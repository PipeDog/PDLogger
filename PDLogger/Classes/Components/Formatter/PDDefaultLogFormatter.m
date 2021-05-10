//
//  PDDefaultLogFormatter.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <pthread/pthread.h>
#import "PDDefaultLogFormatter.h"
#import "PDLogMessage.h"
#import "PDLogUtil.h"
#import "PDDataConvert.h"

@implementation PDDefaultLogFormatter {
    NSDateFormatter *_dateFormatter;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.timeZone = [NSTimeZone systemTimeZone];
        _dateFormatter.dateFormat = @"yyyy/MM/dd HH:mm:ss.SSSZ";
    }
    return self;
}

#pragma mark - PDLogFormatter
- (NSString *)formatLogMessage:(id<PDLogMessage>)logMessage {
    if (!logMessage) { return nil; }

    // @eg:
    //  2020/10/19 09:32:18.091Z [D][PDLogExample.m|- [PDLogExample test:]|122] [Custom Thread ID|com.pipedog.queue]
    //  message => xxx
    //  userInfo => xxx
    NSMutableString *string = [NSMutableString stringWithFormat:@"%@ [%@][%@|%@|%lu] [%@|%@]",
                               [_dateFormatter stringFromDate:logMessage.date],
                               PDLogGetFlag(logMessage.level),
                               logMessage.filename,
                               logMessage.functionName,
                               logMessage.line,
                               logMessage.threadName.length > 0 ? logMessage.threadName : @"Unknown thread",
                               logMessage.queueLabel];
    
    [string appendString:@"\n"];
    [string appendFormat:@"message => %@", logMessage.message];
    [string appendString:@"\n"];

    if (!logMessage.userInfo) { return string; }
    
    NSString *formattedString = [self _formatLogUserInfo:logMessage.userInfo];
    [string appendFormat:@"userInfo => %@", formattedString];
    [string appendString:@"\n"];
    return string;
}

- (void)setDateFormatter:(NSDateFormatter *)dateFormatter {
    _dateFormatter = dateFormatter;
}

#pragma mark - Private Methods
- (NSString *)_formatLogUserInfo:(NSDictionary *)userInfo {
    @try {
        NSString *formattedString = PDValueToJSONText(userInfo);
        return formattedString;
    } @catch (NSException *exception) {
        NSAssert(NO, @"Data type conversion failed!");
        
        NSMutableString *formattedString = [NSMutableString string];
        
        [userInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *pair = [NSString stringWithFormat:@"&%@=%@",
                              [key isKindOfClass:[NSString class]] ? key : [key description],
                              [obj isKindOfClass:[NSString class]] ? obj : [obj description]];
            [formattedString appendString:pair];
        }];
        
        if ([formattedString hasPrefix:@"&"]) {
            return [formattedString substringFromIndex:1];
        }
        return formattedString;
    }
}

@end
