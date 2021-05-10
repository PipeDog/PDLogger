//
//  PDFileManager.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDFileManager.h"
#import "PDLoggerMacro.h"

@interface PDFileManager ()

/* This queue is only used for creating, reading, and deleting files,
 * and all operations are provided synchronously in this class. */
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, copy) NSString *(^filenameFormatBlock)(PDFileManager *);

@end

@implementation PDFileManager

@synthesize recentFileInfo = _recentFileInfo;
@synthesize fileInfos = _fileInfos;
@synthesize fileInfosExceptRecentFile = _fileInfosExceptRecentFile;
@synthesize fileInfosByCreationDateAscendingOrder = _fileInfosByCreationDateAscendingOrder;

- (instancetype)initWithRootPath:(NSString *)rootPath {
    NSAssert(rootPath.length > 0, @"The argument `rootPath` can not be nil!");
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:rootPath isDirectory:&isDir];
    
    if (exists && isDir) { /* Do nothing */ } else {
        NSError *error;
        BOOL result = [fileManager createDirectoryAtPath:rootPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (!result || error) {
            NSAssert(NO, @"Create dir path failed!");
            return nil;
        }
    }
    
    self = [super init];
    if (self) {
        _rootPath = [rootPath copy];
    }
    return self;
}

#pragma mark - Public Methods
- (PDFileInfo *)switchFile {
    _recentFileInfo = nil;
    _fileInfosExceptRecentFile = nil;
    _fileInfosByCreationDateAscendingOrder = nil;
    _fileInfos = nil;
    
    NSString *filename = _filenameFormatBlock(self);
    NSString *filePath = [_rootPath stringByAppendingPathComponent:filename];
    
    __block BOOL result;
    dispatch_sync(_queue, ^{
        result = [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    });

    if (!result) {
        NSAssert(NO, @"Create file failed!");
        return nil;
    }
    
    return (_recentFileInfo = [[PDFileInfo alloc] initWithFilePath:filePath]);
}

- (BOOL)removeFile:(PDFileInfo *)fileInfo {
    __block BOOL result;
    
    @weakify(self)
    dispatch_sync(_queue, ^{
        @strongify(self)
        result = [self _removeFile:fileInfo];
    });
    
    return result;
}

- (BOOL)removeAllFiles {
    __block BOOL result;
    
    @weakify(self)
    dispatch_async(_queue, ^{
        @strongify(self)
        result = [self _removeAllFiles];
    });
    
    return result;
}

- (void)setFilenameFormatWithBlock:(NSString * _Nonnull (^)(PDFileManager * _Nonnull))block {
    _filenameFormatBlock = block;
}

#pragma mark - Private Methods
- (BOOL)_removeFile:(PDFileInfo *)fileInfo {
    if (!fileInfo.filePath) {
        NSAssert(NO, @"The `filePath` from `fileInfo` can not be nil!");
        return YES;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileInfo.filePath]) {
        NSAssert(NO, @"Invalid file path!");
        return YES;
    }
    
    NSError *error;
    BOOL result = [[NSFileManager defaultManager] removeItemAtPath:fileInfo.filePath error:&error];
    if (result && !error) { return YES; }
    
    NSAssert(NO, @"Remove file failed!");
    return NO;
}

- (BOOL)_removeAllFiles {
    BOOL result = YES;
    NSArray<PDFileInfo *> *fileInfos = [self.fileInfos copy];
    
    for (PDFileInfo *fileInfo in fileInfos) {
        if (![self _removeFile:fileInfo]) {
            result = NO;
        }
    }
    return result;
}

#pragma mark - Getter Methods
- (dispatch_queue_t)queue {
    if (!_queue) {
        NSString *name = [NSString stringWithFormat:@"com.fileoperation.queue-%@", _rootPath.lastPathComponent];
        _queue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    return _queue;
}

- (NSString *(^)(PDFileManager *))filenameFormatBlock {
    if (!_filenameFormatBlock) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone systemTimeZone];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.sss";
        
        _filenameFormatBlock = ^(PDFileManager *fm) {
            NSString *name = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:[NSDate date]]];
            return name;
        };
    }
    return _filenameFormatBlock;
}

- (NSArray<PDFileInfo *> *)fileInfos {
    if (!_fileInfos) {
        NSMutableArray<PDFileInfo *> *fileInfos = [NSMutableArray array];
        __block NSArray<NSString *> *filenames;
                
        NSString *rootPath = _rootPath;
        dispatch_sync(_queue, ^{
            filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:rootPath error:NULL];
        });
        
        for (NSString *filename in filenames) {
            NSString *fullPath = [_rootPath stringByAppendingPathComponent:filename];
            PDFileInfo *fileInfo = [[PDFileInfo alloc] initWithFilePath:fullPath];
            if (fileInfo) { [fileInfos addObject:fileInfo]; }
        }
        
        _fileInfos = [fileInfos copy];
    }
    return _fileInfos;
}

- (NSArray<PDFileInfo *> *)fileInfosExceptRecentFile {
    if (!_fileInfosExceptRecentFile) {
        NSMutableArray<PDFileInfo *> *fileInfos = [NSMutableArray array];
        [fileInfos addObjectsFromArray:self.fileInfos ?: @[]];
        
        NSString *recentFilePath = self.recentFileInfo.filePath;
        for (PDFileInfo *fileInfo in fileInfos) {
            if ([recentFilePath isEqualToString:fileInfo.filePath]) {
                [fileInfos removeObject:fileInfo];
                break;
            }
        }
        
        _fileInfosExceptRecentFile = [fileInfos copy];
    }
    return _fileInfosExceptRecentFile;
}

- (PDFileInfo *)recentFileInfo {
    if (!_recentFileInfo) {
        _recentFileInfo = self.fileInfosByCreationDateAscendingOrder.lastObject;
    }
    return _recentFileInfo;
}

- (NSArray<PDFileInfo *> *)fileInfosByCreationDateAscendingOrder {
    if (!_fileInfosByCreationDateAscendingOrder) {
        NSArray<PDFileInfo *> *fileInfos = self.fileInfos;
        
        _fileInfosByCreationDateAscendingOrder = [fileInfos sortedArrayUsingComparator:^NSComparisonResult(PDFileInfo * _Nonnull obj1, PDFileInfo * _Nonnull obj2) {
            return [obj1.fileCreationDate compare:obj2.fileCreationDate];
        }];
    }
    return _fileInfosByCreationDateAscendingOrder;
}

@end
