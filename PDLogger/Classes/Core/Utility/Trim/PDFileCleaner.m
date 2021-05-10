//
//  PDFileCleaner.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDFileCleaner.h"
#import "PDEncryptUtil.h"
#import "PDLoggerMacro.h"

NSUInteger const PDFileCleanDefaultCostLimit = 1 << 30; ///< 1 GB
NSTimeInterval const PDFileCleanDefaultAgeLimit = 7 * 24 * 60 * 60; ///< 7 Days
NSTimeInterval const PDFileCleanDefaultAutoTrimInterval = 1 * 60; ///< 1 Mins

@interface PDFileCleanerPool : NSObject

@end

@implementation PDFileCleanerPool {
    dispatch_semaphore_t _lock;
    NSMutableDictionary *_dict;
}

+ (PDFileCleanerPool *)globalPool {
    static PDFileCleanerPool *__globalPool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __globalPool = [[self alloc] init];
    });
    return __globalPool;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dict = [NSMutableDictionary dictionary];
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER);
    _dict[key] = value;
    dispatch_semaphore_signal(self->_lock);
}

- (id)valueForKey:(NSString *)key {
    dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER);
    id value = _dict[key];
    dispatch_semaphore_signal(self->_lock);
    return value;
}

@end

@interface PDFileCleaner ()

@property (assign) BOOL trimContinue;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation PDFileCleaner {
    struct {
        unsigned shouldRemoveFileAtPath : 1;
        unsigned didRemoveFileAtPath : 1;
        unsigned didFailRemoveFileAtPath : 1;
    } _delegateHas;
}

@synthesize costLimit = _costLimit;
@synthesize ageLimit = _ageLimit;
@synthesize autoTrimInterval = _autoTrimInterval;

- (instancetype)initWithPath:(NSString *)path {
    return [self initWithPath:path queue:nil];
}

- (instancetype)initWithPath:(NSString *)path queue:(dispatch_queue_t)queue {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSAssert(NO, @"The argument `path` must be valid!");
        return nil;
    }
    
    PDFileCleanerPool *pool = [PDFileCleanerPool globalPool];
    PDFileCleaner *cleaner = [pool valueForKey:path];
    if (cleaner) { return cleaner; }
    
    self = [super init];
    if (self) {
        _path = [path copy];
        _queue = queue;
        _costLimit = PDFileCleanDefaultCostLimit;
        _ageLimit = PDFileCleanDefaultAgeLimit;
        _autoTrimInterval = PDFileCleanDefaultAutoTrimInterval;
    }
    
    [pool setValue:self forKey:path];
    return self;
}

- (void)trimRecursively {
    if (self.trimContinue) { return; }
    
    self.trimContinue = YES;
    [self _trimRecursively];
}

- (void)trim {
    [self _trimInBackground];
}

- (void)trimWithBlock:(void (^)(void))block {
    [self _trimInBackgroundWithBlock:block];
}

- (void)stopTrim {
    if (!self.trimContinue) { return; }
    self.trimContinue = NO;
    
    PDFileCleanerPool *pool = [PDFileCleanerPool globalPool];
    [pool setValue:nil forKey:_path];
}

#pragma mark - Private Methods
- (void)_trimRecursively {
    if (!self.trimContinue) {
        return;
    }
    
    @weakify(self)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        @strongify(self)
        if (!self) { return; }
        [self _trimInBackground];
        [self _trimRecursively];
    });
}

- (void)_trimInBackground {
    [self _trimInBackgroundWithBlock:nil];
}

- (void)_trimInBackgroundWithBlock:(void (^)(void))block {
    @weakify(self)
    dispatch_async(_queue, ^{
        @strongify(self)
        if (!self) { return; }
        [self _trim];
        
        !block ?: block();
    });
}

- (void)_trim {
    if (![_fileManager fileExistsAtPath:_path]) {
        PDFileCleanerPool *pool = [PDFileCleanerPool globalPool];
        [pool setValue:nil forKey:_path];
        return;
    }
    
    @weakify(self)
    BOOL (^removeFileBlock)(NSString *) = ^(NSString *filePath) {
        @strongify(self)
        if (!self) { return NO; }
        
        // determine whether the file should be deleted
        BOOL shouldRemove = YES;
        if (self->_delegateHas.shouldRemoveFileAtPath) {
            shouldRemove = [self.delegate fileCleaner:self shouldRemoveFileAtPath:filePath]; }
        if (!shouldRemove) { return NO; }
        
        // perform the delete file operation
        NSError *error;
        BOOL success = [self.fileManager removeItemAtPath:filePath error:&error];
        
        // remove file failed
        if (!success || error) {
            if (self->_delegateHas.didFailRemoveFileAtPath) {
                [self.delegate fileCleaner:self didFailRemoveFileAtPath:filePath withError:error];
            }
            NSAssert(NO, @"Remove file failed!");
            return NO;
        }
        
        // remove file finished
        if (self->_delegateHas.didRemoveFileAtPath) {
            [self.delegate fileCleaner:self didRemoveFileAtPath:filePath];
        }
        return YES;
    };
    
    NSUInteger costLimit = self.costLimit;
    NSTimeInterval ageLimit = self.ageLimit;
    NSAssert(ageLimit > 0, @"Invalid condition property `ageLimit`!");
    
    // [[path, fileSize], [path, fileSize], ...]
    NSMutableArray *cacheInfos = [NSMutableArray array];
    unsigned long long totalSize = 0;

    NSError *error;
    NSArray<NSString *> *paths = [_fileManager contentsOfDirectoryAtPath:_path error:&error];

    for (NSString *tmpPath in paths) {
        NSString *fullPath = [_path stringByAppendingPathComponent:tmpPath];
        NSDictionary<NSFileAttributeKey, id> *attr = [_fileManager attributesOfItemAtPath:fullPath error:NULL];
        unsigned long long fileSize = [self _fileSizeAtPath:fullPath];

        NSDate *modifiedDate = attr.fileModificationDate;
        NSDate *expirationDate = [modifiedDate dateByAddingTimeInterval:ageLimit];
        
        if ([[NSDate date] compare:expirationDate] == NSOrderedAscending) {
            totalSize += fileSize;
            [cacheInfos addObject:@[fullPath, [NSNumber numberWithUnsignedLongLong:fileSize]]];
        } else {
            removeFileBlock(fullPath);
        }
    }
    
    // Sort by fileSize, High => Low
    NSArray *sortedInfos = [cacheInfos sortedArrayUsingComparator:^NSComparisonResult(NSArray * _Nonnull obj1, NSArray * _Nonnull obj2) {
        if (![obj1 isKindOfClass:[NSArray class]] || ![obj2 isKindOfClass:[NSArray class]]) { return NSOrderedSame; }
        if (obj1.count < 2 || obj2.count < 2) { return NSOrderedSame; }
        
        unsigned long long size1 = [obj1[1] unsignedLongLongValue];
        unsigned long long size2 = [obj2[1] unsignedLongLongValue];
        
        if (size1 < size2) { return NSOrderedDescending; }
        if (size1 > size2) { return NSOrderedAscending; }
        return NSOrderedSame;
    }];
    
    if (totalSize <= costLimit) { return; }
    
    for (NSArray *info in sortedInfos) {
        NSString *filePath = info[0];
        unsigned long long fileSize = [info[1] unsignedLongLongValue];
        
        if (!removeFileBlock(filePath)) {
            continue;
        }
        
        totalSize -= fileSize;
        if (totalSize < costLimit) {
            break;
        }
    }
}

- (unsigned long long)_fileSizeAtPath:(NSString *)filePath {
    BOOL isDir = NO;
    if (![_fileManager fileExistsAtPath:filePath isDirectory:&isDir]) {
        return 0;
    }
    
    if (!isDir) {
        NSDictionary<NSFileAttributeKey, id> *attr = [_fileManager attributesOfItemAtPath:filePath error:NULL];
        return attr.fileSize;
    }

    unsigned long long fileSize = 0;
    NSMutableArray<NSString *> *paths = [NSMutableArray array];
    [paths addObject:filePath];
    
    while (paths.count > 0) { @autoreleasepool {
        NSString *nodePath = paths.firstObject;
        [paths removeObjectAtIndex:0];
        
        NSDictionary<NSFileAttributeKey, id> *attr = [_fileManager attributesOfItemAtPath:nodePath error:NULL];
        fileSize += attr.fileSize;
        
        BOOL isDir = NO;
        if (![_fileManager fileExistsAtPath:nodePath isDirectory:&isDir]) { continue; }
        if (!isDir) { continue; }
        
        NSArray<NSString *> *filenames = [_fileManager contentsOfDirectoryAtPath:nodePath error:NULL];
        [filenames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *tmpPath = [nodePath stringByAppendingPathComponent:obj];
            [paths addObject:tmpPath];
        }];
    }}
    
    return fileSize;
}

#pragma mark - Setter Methods
- (void)setDelegate:(id<PDFileCleanerDelegate>)delegate {
    _delegate = delegate;
    
    _delegateHas.shouldRemoveFileAtPath = [_delegate respondsToSelector:@selector(fileCleaner:shouldRemoveFileAtPath:)];
    _delegateHas.didRemoveFileAtPath = [_delegate respondsToSelector:@selector(fileCleaner:didRemoveFileAtPath:)];
    _delegateHas.didFailRemoveFileAtPath = [_delegate respondsToSelector:@selector(fileCleaner:didFailRemoveFileAtPath:withError:)];
}

#pragma mark - Getter Methods
- (NSFileManager *)fileManager {
    return [NSFileManager defaultManager];
}

- (dispatch_queue_t)queue {
    if (!_queue) {
        NSString *name = [NSString stringWithFormat:@"com.%@.trash", PDMD5EncryptWithString(_path)];
        _queue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    return _queue;
}

@end
