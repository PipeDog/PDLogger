//
//  PDUncaughtExceptionHandler.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDUncaughtExceptionHandler.h"

static NSUncaughtExceptionHandler *previousUncaughtExceptionHandler = NULL;

@implementation PDUncaughtExceptionHandler

PD_EXCEPTION_NOTIFY_LISTENER_INSTALL()

#pragma mark - Register
+ (void)registerHandler {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
        NSSetUncaughtExceptionHandler(&PDUncaughtExceptionHandlerImpl);
    });
}

#pragma mark - Private
static void PDUncaughtExceptionHandlerImpl(NSException * exception) {
    NSArray *callStackSymbols = [exception callStackSymbols];
    NSString *reason = [exception reason];
    NSString *name = [exception name];
        
    NSMutableString *info = [NSMutableString string];
    [info appendString:@"======== Uncaught exception 异常报告 ========\n"];
    [info appendFormat:@"name: %@\n", name];
    [info appendFormat:@"reason: %@\n", reason];
    [info appendFormat:@"callStackSymbols: \n%@", [callStackSymbols componentsJoinedByString:@"\n"]];
    [info appendFormat:@"\n"];
        
    // notify listeners
    [PDUncaughtExceptionHandler notifyListeners:info];
    // call previous handler
    if (previousUncaughtExceptionHandler) { previousUncaughtExceptionHandler(exception); }
    // kill the program so that SIGABRT that is thrown at the same time is not caught by SignalException
    kill(getpid(), SIGKILL);
}

@end
