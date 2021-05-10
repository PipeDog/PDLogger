//
//  PDExceptionHandler.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDExceptionHandler.h"
#import "PDSignalExceptionHandler.h"
#import "PDUncaughtExceptionHandler.h"

@implementation PDExceptionHandler

+ (void)registerHandler {
    [PDSignalExceptionHandler registerHandler];
    [PDUncaughtExceptionHandler registerHandler];
}

+ (void)addListener:(id<PDExceptionListener>)listener {
    [PDSignalExceptionHandler addListener:listener];
    [PDUncaughtExceptionHandler addListener:listener];
}

+ (void)removeListener:(id<PDExceptionListener>)listener {
    [PDSignalExceptionHandler removeListener:listener];
    [PDUncaughtExceptionHandler removeListener:listener];
}

@end
