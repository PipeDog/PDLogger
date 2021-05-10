//
//  PDFileAttrUtil.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDFileAttrUtil.h"
#import <sys/xattr.h>

BOOL PDFileSetExtendedAttributes(NSString *filePath, NSString *key, NSString *value) {
    if (!filePath.length) { return NO; }
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) { return NO; }
    
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    ssize_t writeLen = setxattr([filePath fileSystemRepresentation],
                                [key UTF8String],
                                [data bytes],
                                [data length],
                                0,
                                0);
    return writeLen == 0 ? YES : NO;
}

NSString *PDFileGetExtendedAttributes(NSString *filePath, NSString *key) {
    if (!filePath.length) { return nil; }
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) { return nil; }

    ssize_t readLen = 1024;
    do {
        char buffer[readLen];
        bzero(buffer, sizeof(buffer));
        size_t leng = sizeof(buffer);
        readLen = getxattr([filePath fileSystemRepresentation],
                           [key UTF8String],
                           buffer,
                           leng,
                           0,
                           0);
        if (readLen < 0) {
            return nil;
        } else if (readLen > sizeof(buffer)) {
            continue;
        } else {
            NSData *data = [NSData dataWithBytes:buffer length:readLen];
            NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            return result;
        }
    } while (YES);
    return nil;
}
