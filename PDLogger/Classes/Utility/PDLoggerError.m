//
//  PDLoggerError.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDLoggerError.h"

static NSString *const kPDLGErrorDomain = @"kPDLGErrorDomain";

NSError *PDLGErrorWithDomain(NSErrorDomain domain, NSInteger code, NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *message = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    
    NSError *error = [NSError errorWithDomain:domain code:code userInfo:@{NSLocalizedDescriptionKey: message ?: @""}];
    return error;
}

NSError *PDLGError(NSInteger code, NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *message = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    
    NSError *error = [NSError errorWithDomain:kPDLGErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: message ?: @""}];
    return error;
}

NSErrorDomain PDLGErrorGetDomain(NSError *error) {
    if (!error) {
        return nil;
    }
    return error.domain;
}

NSInteger PDLGErrorGetCode(NSError *error) {
    if (!error) {
        return 0;
    }
    return error.code;
}

NSString *PDLGErrorGetMessage(NSError *error) {
    if (!error) {
        return nil;
    }
    
    NSDictionary *userInfo = error.userInfo;
    NSString *message = userInfo[NSLocalizedDescriptionKey];
    return message;
}
