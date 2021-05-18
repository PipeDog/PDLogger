//
//  PDLogger.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDLogger.h"
#import "PDLoggerMacro.h"
#import "PDLogMessage.h"
#import "PDLogFileUtil.h"
#import "PDFileInfo.h"
#import "PDDefaultFileLogger.h"
#import "PDDefaultLogFormatter.h"
#import "PDDefaultLogReporter.h"
#import "PDDefaultLogMessage.h"

@interface PDLogger () <PDFileLoggerDelegate>

@property (atomic, assign) BOOL enableLog;

@end

@implementation PDLogger {
    dispatch_queue_t _queue;
    NSMutableArray<id<PDLogListener>> *_listeners;
}

+ (PDLogger *)defaultLogger {
    static PDLogger *__defaultLogger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __defaultLogger = [[self alloc] init];
    });
    return __defaultLogger;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _enableLog = YES;
        _logFormatter = [[PDDefaultLogFormatter alloc] init];
        _logReporter = [[PDDefaultLogReporter alloc] init];
        _fileLogger = [[PDDefaultFileLogger alloc] init];
        _fileLogger.delegate = self;
        _logMessageClass = [PDDefaultLogMessage class];
        
        _queue = dispatch_queue_create("com.pipedog-logger.queue", DISPATCH_QUEUE_SERIAL);
        _listeners = [NSMutableArray array];
        
        [self reportLogsIfNeeded];
    }
    return self;
}

#pragma mark - Public Methods
- (void)logWithLevel:(PDLogLevel)level
                file:(const char *)file
                func:(const char *)func
                line:(NSUInteger)line
            userInfo:(NSDictionary *)userInfo
              format:(NSString *)format, ... {
    if (!self.enableLog) { return; }
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    id<PDLogMessage> logMessage = [[self.logMessageClass alloc] initWithMessage:message
                                                                          level:level
                                                                           file:[NSString stringWithUTF8String:file]
                                                                   functionName:[NSString stringWithUTF8String:func]
                                                                           line:line
                                                                       userInfo:userInfo
                                                                           date:[NSDate date]];

    @weakify(self)
    dispatch_async(_queue, ^{ @autoreleasepool {
        @strongify(self)
        if (!self) { return; }
        
        NSString *log = [self->_logFormatter formatLogMessage:logMessage];
        [self->_fileLogger log:log];
        
        for (id<PDLogListener> listener in self->_listeners) {
            [listener log:logMessage formattedLog:log];
        }
    }});
}

- (void)addListener:(id<PDLogListener>)listener {
    if ([listener respondsToSelector:@selector(log:formattedLog:)]) {
        [self->_listeners addObject:listener];
    }
}

- (void)removeListener:(id<PDLogListener>)listener {
    if ([self->_listeners containsObject:listener]) {
        [self->_listeners removeObject:listener];
    }
}

- (void)resume {
    self.enableLog = YES;
}

- (void)suspend {
    self.enableLog = NO;
}

- (void)forceReportLogs {
    [self.fileLogger switchFile];
    [self reportLogsIfNeeded];
}

- (void)forceReportLogsFrom:(NSDate *)date1 to:(NSDate *)date2 {
    NSArray<PDFileInfo *> *fileInfos = self.fileLogger.fileInfosShouldDump;
    
    NSDate *minDate = [date1 earlierDate:date2];
    NSDate *maxDate = [date1 laterDate:date2];
    
    // Two pointer to filter log files to be uploaded
    NSUInteger leftIndex = 0, rightIndex = fileInfos.count - 1;
    
    while (leftIndex < rightIndex) {
        //
        //                  minDate                                    maxDate
        //                     |                                          |
        //                     |                                          |
        //                     V                                          V
        //            file A                     file B                         file C
        //      |-----------------| |-------------------------------| |---------------------------|
        //    <Create -> Last Modify> <Create --------> Last Modify>   <Create -----> Last Modify>
        //                        |                                   |
        //                        |                                   |
        //                        V                                   V
        //                  file A Modify =====================> file C Create
        //
        NSDate *left = fileInfos[leftIndex].fileModificationDate;
        NSDate *right = fileInfos[rightIndex].fileCreationDate;

        NSComparisonResult leftResult = [left compare:minDate];
        NSComparisonResult rightResult = [right compare:maxDate];
        
        // left >= minDate && right <= maxDate
        if (leftResult != NSOrderedAscending &&
            rightResult != NSOrderedAscending) {
            break;
        }
        // left < minDate
        if (leftResult == NSOrderedAscending) {
            leftIndex++;
        }
        // right > maxDate
        if (rightResult == NSOrderedDescending) {
            rightIndex--;
        }
    }
    
    // Get file infos
    NSMutableArray<PDFileInfo *> *needUploadFileInfos = [NSMutableArray array];

    for (NSUInteger i = leftIndex; i < rightIndex; i++) {
        PDFileInfo *fileInfo = fileInfos[i];
        [needUploadFileInfos addObject:fileInfo];
    }
    
    // Report to server-side
    [self reportLogsWithFileInfos:needUploadFileInfos];
}

#pragma mark - PDFileLoggerDelegate
- (void)fileLogger:(id<PDFileLogger>)fileLogger dumpLogsFromFileInfos:(NSArray<PDFileInfo *> *)fileInfos {
    [self reportLogsWithFileInfos:fileInfos];
}

#pragma mark - Private Methods
- (void)reportLogsIfNeeded {
    NSArray<PDFileInfo *> *fileInfos = self.fileLogger.fileInfosShouldDump;
    [self reportLogsWithFileInfos:fileInfos];
}

- (void)reportLogsWithFileInfos:(NSArray<PDFileInfo *> *)fileInfos {
    if (!fileInfos.count) { return; }
    
    if ([self.logReporter respondsToSelector:@selector(reportLogFile:completion:)]) {
        [self singleReportLogsWithFileInfos:fileInfos];
    } else if ([self.logReporter respondsToSelector:@selector(reportLogFiles:completion:)]) {
        [self batchReportLogsWithFileInfos:fileInfos];
    } else {
        NSAssert(NO, @"One of methods `- reportLogFile:completion:` and "
                      "`- reportLogFiles:completion:`  must be implemented!");
    }
}

- (void)singleReportLogsWithFileInfos:(NSArray<PDFileInfo *> *)fileInfos {
    id<PDLogReporter> reporter = self.logReporter;
    id<PDFileLogger> fileLogger = self.fileLogger;

    [fileInfos enumerateObjectsUsingBlock:^(PDFileInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // Set uploading state
        [fileLogger setUploadState:PDLogFileUploadStateUploading forFilePath:obj.filePath];

        [reporter reportLogFile:obj.filePath completion:^(BOOL success, NSError * _Nullable error) {
            if (!success || error) {
                // NSAssert(NO, @"Upload failed!");
                // Set upload failed state
                [fileLogger setUploadState:PDLogFileUploadStateFailed forFilePath:obj.filePath];
                return;
            }

            // Set upload success state
            [fileLogger setUploadState:PDLogFileUploadStateUploaded forFilePath:obj.filePath];
            // remove local event file if upload finished
            [fileLogger removeFile:obj];
        }];
    }];
}

- (void)batchReportLogsWithFileInfos:(NSArray<PDFileInfo *> *)fileInfos {
    id<PDLogReporter> reporter = self.logReporter;
    id<PDFileLogger> fileLogger = self.fileLogger;

    NSMutableArray<NSString *> *filePaths = [NSMutableArray array];
    for (PDFileInfo *fileInfo in fileInfos) {
        [fileLogger setUploadState:PDLogFileUploadStateUploading forFilePath:fileInfo.filePath];
        [filePaths addObject:fileInfo.filePath];
    }
    
    [reporter reportLogFiles:filePaths completion:^(NSError * _Nullable error,
                                                    NSArray<NSString *> * _Nullable failedList,
                                                    NSArray<NSString *> * _Nullable finishedList) {
        for (PDFileInfo *fileInfo in failedList) {
            [fileLogger setUploadState:PDLogFileUploadStateFailed forFilePath:fileInfo.filePath];
        }
        for (PDFileInfo *fileInfo in finishedList) {
            // Set upload success state
            [fileLogger setUploadState:PDLogFileUploadStateUploaded forFilePath:fileInfo.filePath];
            // remove local event file if upload finished
            [fileLogger removeFile:fileInfo];
        }
    }];
}

@end

void PDLog(PDLogLevel level,
           const char *file,
           const char *func,
           NSUInteger line,
           NSDictionary *userInfo,
           NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *log = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [[PDLogger defaultLogger] logWithLevel:level file:file func:func line:line userInfo:userInfo format:log];
}
