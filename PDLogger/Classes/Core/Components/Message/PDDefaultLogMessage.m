//
//  PDDefaultLogMessage.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <pthread.h>
#import "PDDefaultLogMessage.h"
#import "PDLogUtil.h"

@implementation PDDefaultLogMessage

@synthesize message = _message;
@synthesize level = _level;
@synthesize file = _file;
@synthesize filename = _filename;
@synthesize functionName = _functionName;
@synthesize line = _line;
@synthesize userInfo = _userInfo;
@synthesize date = _date;
@synthesize threadID = _threadID;
@synthesize threadName = _threadName;
@synthesize queueLabel = _queueLabel;

- (instancetype)initWithMessage:(NSString *)message
                          level:(PDLogLevel)level
                           file:(NSString *)file
                   functionName:(NSString *)functionName
                           line:(NSUInteger)line
                       userInfo:(NSDictionary *)userInfo
                           date:(NSDate *)date {
    self = [super init];
    if (self) {
        _message = [message copy];
        _level = level;
        _file = [file copy];
        _filename = [file lastPathComponent];
        _functionName = [functionName copy];
        _line = line;
        _userInfo = [userInfo copy];
        _date = date;

        _threadID = ({
            NSString *threadID;
            __uint64_t tid;
            if (pthread_threadid_np(NULL, &tid) == 0) {
                threadID = [[NSString alloc] initWithFormat:@"%llu", tid];
            } else {
                threadID = @"Miss threadID";
            }
            threadID;
        });
        
        _threadName = [NSThread currentThread].name;
        _queueLabel = [NSString stringWithUTF8String:dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)];
    }
    return self;
}

- (NSString *)description {
    NSMutableString *format = [NSMutableString string];
    [format appendString:@"\n{\n"];
    [format appendFormat:@"\tdate = %@,\n", self.date];
    [format appendFormat:@"\tlevel = %@,\n", PDLogGetFlag(self.level)];
    [format appendFormat:@"\tfilename = %@,\n", self.filename];
    [format appendFormat:@"\tfunctionName = %@,\n", self.functionName];
    [format appendFormat:@"\tline = %lu,\n", self.line];
    [format appendFormat:@"\tuserInfo = %@,\n", self.userInfo];
    [format appendFormat:@"\tlog = %@\n", self.message];
    [format appendString:@"}\n"];
    return format;
}

@end
