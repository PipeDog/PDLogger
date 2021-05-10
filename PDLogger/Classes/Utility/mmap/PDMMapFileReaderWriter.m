//
//  PDMMapFileReaderWriter.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDMMapFileReaderWriter.h"
#import <sys/stat.h>
#import <sys/mman.h>

@interface PDMMapFileReaderWriter ()

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, assign) size_t currentFileSize;
@property (nonatomic, assign) int fileDescriptor;
@property (nonatomic, assign) BOOL enableReadWrite;
@property (nonatomic, assign) NSUInteger appendCount;
@property (nonatomic, assign) NSUInteger appendSize;
@property (nonatomic, assign) NSTimeInterval timestamp;

@end

@implementation PDMMapFileReaderWriter

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = [filePath copy];
        _enableReadWrite = YES;
        _appendCount = 0;
        _appendSize = 0;
        _syncToDiskCount = 10;
        _syncToDiskSize = PAGE_SIZE * 2;
        _syncToDiskTimeInterval = 20.f;

        if (![self prepareReadWriteContext]) {
            return nil;
        }
    }
    return self;
}

- (BOOL)prepareReadWriteContext {
    _fileDescriptor = open(_filePath.UTF8String, O_RDWR | O_CREAT, 0);
    if (_fileDescriptor < 0) {
        NSAssert(NO, @"Open file failed!");
        return NO;
    }
    
    struct stat fs;
    if (fstat(_fileDescriptor, &fs) != 0) {
        NSAssert(NO, @"Get file stat failed when prepare read write context!");
        return NO;
    }
    
    _currentFileSize = (size_t)fs.st_size;
    return YES;
}

#pragma mark - Public Methods
- (BOOL)appendFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    return [self appendString:string];
}

- (BOOL)appendString:(NSString *)string {
    if (!self.enableReadWrite) {
        NSAssert(NO, @"Can not append string after terminate operation!");
        return NO;
    }
    
    struct stat fs;
    if (fstat(self.fileDescriptor, &fs) != 0) {
        NSAssert(NO, @"Get file stat failed when append string!");
        return NO;
    }

    size_t originLen = (size_t)fs.st_size;
    size_t stringLen = strlen(string.UTF8String);
    size_t totalFileLen = originLen + stringLen;
    
    // update file size
    if (ftruncate(self.fileDescriptor, totalFileLen) != 0) {
        NSAssert(NO, @"Update file size failed when append string!");
        return NO;
    }
    self.currentFileSize = totalFileLen;
    
    // build map file before append string
    // offset must be multiple of PAGE_SIZE, otherwise the mapping will fail
    off_t offset = floor((double)originLen / PAGE_SIZE) * PAGE_SIZE;
    size_t mapLen = totalFileLen - (size_t)offset;
    void *mappedBegin = mmap(NULL, mapLen, PROT_READ | PROT_WRITE,
                            MAP_FILE | MAP_SHARED, self.fileDescriptor, offset);
    if (mappedBegin == MAP_FAILED) {
        NSAssert(NO, @"Build mmap failed when append string!");
        return NO;
    }
    
    // copy string data to file map memory
    size_t off = originLen % PAGE_SIZE;
    memcpy(mappedBegin + off, string.UTF8String, stringLen);
    
    // sync to disk if needed
    BOOL sync = NO; self.appendCount++; self.appendSize += stringLen;
    if (self.appendCount >= self.syncToDiskCount) { sync = YES; self.appendCount = 0; }
    if (self.appendSize >= self.syncToDiskSize) { sync = YES; self.appendSize = 0; }
    
    NSTimeInterval curTimestamp = [NSDate date].timeIntervalSince1970;
    NSTimeInterval timeLen = curTimestamp - self.timestamp;
    if (timeLen > self.syncToDiskTimeInterval) { sync = YES; self.timestamp = curTimestamp; }
    
    if (sync) { if (msync(mappedBegin, mapLen, MS_ASYNC) != 0) { NSAssert(NO, @"msync data to disk failed!"); } }
    
    // unmap file
    if (munmap(mappedBegin, mapLen) != 0) {
        NSAssert(NO, @"Remove mmap failed when append string!");
        return NO;
    }
    
    return YES;
}

- (void)terminate {
    if (!self.enableReadWrite) { return; }

    close(self.fileDescriptor);
}

@end
