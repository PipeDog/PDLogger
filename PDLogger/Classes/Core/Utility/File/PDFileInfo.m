//
//  PDFileInfo.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDFileInfo.h"

@implementation PDFileInfo

@synthesize filePath = _filePath;
@synthesize filename = _filename;
@synthesize isDirectory = _isDirectory;
@synthesize fileAttributes = _fileAttributes;
@synthesize fileCreationDate = _fileCreationDate;
@synthesize fileModificationDate = _fileModificationDate;
@synthesize fileSize = _fileSize;

- (instancetype)initWithFilePath:(NSString *)filePath {
    if (!filePath.length) {
        return nil;
    }
    
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory]) {
        return nil;
    }

    self = [super init];
    if (self) {
        _filePath = [filePath copy];
        _filename = [filePath lastPathComponent];
        _isDirectory = isDirectory;
    }
    return self;
}

- (void)setNeedsUpdate {
    _fileAttributes = nil;
    _fileCreationDate = nil;
    _fileModificationDate = nil;
    _fileSize = 0;
}

#pragma mark - Getter Methods
- (NSDictionary<NSFileAttributeKey,id> *)fileAttributes {
    if (!_fileAttributes) {
        _fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_filePath error:nil];
    }
    return _fileAttributes;
}

- (NSDate *)fileCreationDate {
    if (!_fileCreationDate) {
        _fileCreationDate = [self.fileAttributes fileCreationDate];
    }
    return _fileCreationDate;
}

- (NSDate *)fileModificationDate {
    if (!_fileModificationDate) {
        _fileModificationDate = [self.fileAttributes fileModificationDate];
    }
    return _fileModificationDate;
}

- (unsigned long long)fileSize {
    if (!_fileSize) {
        _fileSize = [self.fileAttributes fileSize];
    }
    return _fileSize;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString string];
    [description appendString:@"fileInfo => {\n"];
    [description appendFormat:@"\tname: %@,\n", self.filename];
    [description appendFormat:@"\tpath: %@,\n", self.filePath];
    [description appendString:@"}\n"];
    return description;
}

@end
