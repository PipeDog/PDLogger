//
//  PDMMapFileLogger.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDMMapFileLogger.h"
#import "PDFileManager.h"
#import "PDLoggerMacro.h"
#import "PDLoggerConstants.h"
#import "PDLogFileUtil.h"
#import "PDExceptionHandler.h"
#import "PDFileCleaner.h"
#import "PDLogReporter.h"
#import "PDMMapFileReaderWriter.h"

#define SYNC(target, sel) @autoreleasepool {                    \
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);   \
    [target sel ^{                                              \
        dispatch_semaphore_signal(lock);                        \
    }];                                                         \
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);       \
}

@interface PDMMapFileLogger () <PDExceptionListener, PDFileCleanerDelegate>

@end

@implementation PDMMapFileLogger {
    dispatch_queue_t _queue;
    PDFileManager *_fileManager;
    PDMMapFileReaderWriter *_readerWriter;
    PDFileCleaner *_fileCleaner;
    struct {
        unsigned dumpLogsFromFileInfos : 1;
    } _delegateHas;
}

@synthesize delegate = _delegate;
@synthesize logDirPath = _logDirPath;

- (void)dealloc {
    [self _terminateReaderWriter];
    [self _resignListen];
    [PDExceptionHandler removeListener:self];
}

- (instancetype)init {
    return [self initWithDirPath:nil];
}

- (instancetype)initWithDirPath:(NSString *)dirPath {
    self = [super init];
    if (self) {
        if (!dirPath) {
            NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
            NSString *dirName = @"com.pipedog.log";
            dirPath = [cacheFolder stringByAppendingPathComponent:dirName];
        }
        
        _logDirPath = dirPath;
        [self _setupInitializeConfiguration];
    }
    return self;
}

- (void)_setupInitializeConfiguration {
    _maxFileSize = 1000 * 1000 * 2;
    _maxCacheSpace = 1000 * 1000 * 60;
    _logFileValidTimeLength = 60 * 60 * 24 * 7;
    _autoTrimInterval = 30.f;
    _enableTrimUnuploadFiles = YES;

    _queue = dispatch_queue_create("com.pipedog-mmaplogger.queue", DISPATCH_QUEUE_SERIAL);
    _fileManager = [[PDFileManager alloc] initWithRootPath:_logDirPath];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.sss";

    [_fileManager setFilenameFormatWithBlock:^NSString * _Nonnull(PDFileManager * _Nonnull fileManager) {
        NSString *name = [NSString stringWithFormat:@"%@.log", [dateFormatter stringFromDate:[NSDate date]]];
        return name;
    }];
    
    [PDExceptionHandler addListener:self];

    _fileCleaner = [[PDFileCleaner alloc] initWithPath:_logDirPath queue:_queue];
    _fileCleaner.costLimit = self.maxCacheSpace;
    _fileCleaner.ageLimit = self.logFileValidTimeLength;
    _fileCleaner.autoTrimInterval = self.autoTrimInterval;
    _fileCleaner.delegate = self;
    [_fileCleaner trimRecursively];
    
    [self _resetFilesStateExceptRecentFile];
    [self _setupInitializeRecentFile];
    [self _didUpdateReaderWriter];
    [self _registerListen];
}

- (void)_setupInitializeRecentFile {
    if (!_fileManager.recentFileInfo) { // Unexists recent file
        [_fileManager switchFile];
        return;
    }
    
    PDFileInfo *recentFileInfo = _fileManager.recentFileInfo;
    PDLogFileUploadState state = PDLogFileGetUploadState(recentFileInfo.filePath);
    if (state != PDLogFileUploadStateUnupload) { // Uploading || Uploaded
        [_fileManager switchFile];
        return;
    }
        
    if (recentFileInfo.fileSize >= self.maxFileSize) { // Out of file size
        [_fileManager switchFile];
        return;
    }
}

#pragma mark - Notification Methods
- (void)_registerListen {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
}

- (void)_resignListen {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self _syncCloseFileHandle];
}

#pragma mark - Public Methods
- (void)log:(NSString *)logMessage {
    @weakify(self)
    dispatch_async(_queue, ^{ @autoreleasepool {
        @strongify(self)
        if (!self) { return; }

        [self->_readerWriter appendString:logMessage];

        if (![self _outOfLogFileSizeLimit]) {
            return;
        }
        
        [self _switchFile];
        
        if (self->_delegateHas.dumpLogsFromFileInfos) {
            NSArray<PDFileInfo *> *fileInfos = self->_fileManager.fileInfosExceptRecentFile;
            fileInfos = [self _filterNeedUploadLogFileInfos:fileInfos];
            [self.delegate fileLogger:self dumpLogsFromFileInfos:fileInfos];
        }
    }});
}

- (NSArray<PDFileInfo *> *)fileInfosShouldDump {
    NSArray<PDFileInfo *> *fileInfos = [self _filterNeedUploadLogFileInfos:_fileManager.fileInfosExceptRecentFile];
    return fileInfos;
}

- (BOOL)removeFile:(PDFileInfo *)fileInfo {
    if (![fileInfo.filePath isEqualToString:self->_fileManager.recentFileInfo.filePath]) {
        return [self _removeFile:fileInfo];
    }
    
    [self _syncSwitchFile];
    return [_fileManager removeFile:fileInfo];
}

- (BOOL)setUploadState:(PDLogFileUploadState)state forFilePath:(NSString *)filePath {
    return PDLogFileSetUploadState(filePath, state);
}

- (void)switchFile {
    [self _syncSwitchFile];
}

#pragma mark - PDExceptionListener
- (void)didCatchExceptionWithFormattedInformation:(NSString *)formattedInformation {
    [self _syncCloseFileHandle];
}

#pragma mark - PDFileCleanerDelegate
- (BOOL)fileCleaner:(PDFileCleaner *)fileCleaner shouldRemoveFileAtPath:(NSString *)filePath {
    // current log file
    if ([filePath isEqualToString:_fileManager.recentFileInfo.filePath]) {
        return NO;
    }
    
    if (self.enableTrimUnuploadFiles) {
        return YES;
    }

    PDLogFileUploadState state = PDLogFileGetUploadState(filePath);
    if (state == PDLogFileUploadStateUploaded) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Async Serial Methods (Sync execute)
- (void)_syncSwitchFile {
    SYNC(self, _switchFileWithBlock:);
}

- (void)_syncCloseFileHandle {
    SYNC(self, _terminateReaderWriterWithBlock:);
}

- (void)_syncDidUpdateFileHandle {
    SYNC(self, _didUpdateReaderWriterWithBlock:);
}

#pragma mark - Async Methods
- (void)_switchFileWithBlock:(void (^)(void))block {
    @weakify(self)
    dispatch_async(_queue, ^{
        @strongify(self)
        if (!self) { return; }
        
        [self _switchFile];
        !block ?: block();
    });
}

- (void)_terminateReaderWriterWithBlock:(void (^)(void))block {
    @weakify(self)
    dispatch_async(_queue, ^{
        @strongify(self)
        if (!self) { return; }
        
        [self _terminateReaderWriter];
        !block ?: block();
    });
}

- (void)_didUpdateReaderWriterWithBlock:(void (^)(void))block {
    @weakify(self)
    dispatch_async(_queue, ^{
        @strongify(self)
        if (!self) { return; }
        
        [self _didUpdateReaderWriter];
        !block ?: block();
    });
}

#pragma mark - Tool Methods
- (BOOL)_removeFile:(PDFileInfo *)fileInfo {
    return [_fileManager removeFile:fileInfo];
}

- (void)_switchFile {
    [self _terminateReaderWriter];
    [self->_fileManager switchFile];
    [self _didUpdateReaderWriter];
}

- (void)_resetFilesStateExceptRecentFile {
    NSTimeInterval timeLen = self.logFileValidTimeLength;
    NSTimeInterval earliestTime = [NSDate date].timeIntervalSince1970 - timeLen;
    NSArray<PDFileInfo *> *fileInfos = self->_fileManager.fileInfosExceptRecentFile;
    
    for (PDFileInfo *fileInfo in fileInfos) {
        NSTimeInterval modificationTime = fileInfo.fileModificationDate.timeIntervalSince1970;
        if (modificationTime < earliestTime) { // Remove expired file
            [self->_fileManager removeFile:fileInfo];
            continue;
        }
        
        PDLogFileUploadState state = PDLogFileGetUploadState(fileInfo.filePath);
        switch (state) {
            case PDLogFileUploadStateUnupload: {
                // Do nothing...
            } break;
            case PDLogFileUploadStateUploading: {
                PDLogFileSetUploadState(fileInfo.filePath, PDLogFileUploadStateUnupload);
            } break;
            case PDLogFileUploadStateUploaded: {
                [self->_fileManager removeFile:fileInfo];
            } break;
        }
    }
}

- (void)_terminateReaderWriter {
    if (!_readerWriter) { return; }
    
    [_readerWriter terminate];
    _readerWriter = nil;
}

- (void)_didUpdateReaderWriter {
    PDFileInfo *recentFileInfo = _fileManager.recentFileInfo;
    _readerWriter = [[PDMMapFileReaderWriter alloc] initWithFilePath:recentFileInfo.filePath];
}

- (NSArray<PDFileInfo *> *)_filterNeedUploadLogFileInfos:(NSArray<PDFileInfo *> *)fileInfos {
    NSMutableArray<PDFileInfo *> *needUploadFileInfos = [NSMutableArray array];
    
    for (PDFileInfo *fileInfo in fileInfos) {
        PDLogFileUploadState state = PDLogFileGetUploadState(fileInfo.filePath);
        if (state == PDLogFileUploadStateUnupload) {
            [needUploadFileInfos addObject:fileInfo];
        }
    }
    
    return needUploadFileInfos;
}

- (BOOL)_outOfLogFileSizeLimit {
    return (self->_readerWriter.currentFileSize >= self.maxFileSize);
}

#pragma mark - Setter Methods
- (void)setDelegate:(id<PDFileLoggerDelegate>)delegate {
    _delegate = delegate;
    _delegateHas.dumpLogsFromFileInfos = [_delegate respondsToSelector:@selector(fileLogger:dumpLogsFromFileInfos:)];
}

@end
