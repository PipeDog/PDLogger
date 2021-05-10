//
//  PDLogger.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>
#import "PDLoggerConstants.h"
#import "PDFileLogger.h"
#import "PDLogReporter.h"
#import "PDLogFormatter.h"
#import "PDLogListener.h"
#import "PDLogMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface PDLogger : NSObject

@property (class, strong, readonly) PDLogger *defaultLogger;

@property (nonatomic, strong) id<PDFileLogger> fileLogger;
@property (nonatomic, strong) id<PDLogReporter> logReporter;
@property (nonatomic, strong) id<PDLogFormatter> logFormatter;
@property (nonatomic, unsafe_unretained) Class logMessageClass;

- (void)addListener:(id<PDLogListener>)listener; // Add log listener
- (void)removeListener:(id<PDLogListener>)listener; // Remove log lisnter

- (void)resume; // Resume log collection
- (void)suspend; // Suspend log collection

- (void)forceReportLogs; // Upload all log files
- (void)forceReportLogsFrom:(NSDate *)date1 to:(NSDate *)date2; // Upload log files from date1 to date2

- (void)logWithLevel:(PDLogLevel)level
                file:(const char *)file
                func:(const char *)func
                line:(NSUInteger)line
            userInfo:(nullable NSDictionary *)userInfo
              format:(NSString *)format, ...;

@end

FOUNDATION_EXPORT void PDLog(PDLogLevel level,
                             const char *file,
                             const char *func,
                             NSUInteger line,
                             NSDictionary * _Nullable userInfo,
                             NSString *format, ...);

#define LOG_MACRO(level, userInfo, ...) \
    PDLog(level, __FILE__, __PRETTY_FUNCTION__, __LINE__, userInfo, [NSString stringWithFormat:__VA_ARGS__])

#define PDLogDebug(userInfo, ...)   LOG_MACRO(PDLogLevelDebug, userInfo, __VA_ARGS__)
#define PDLogInfo(userInfo, ...)    LOG_MACRO(PDLogLevelInfo, userInfo, __VA_ARGS__)
#define PDLogWarn(userInfo, ...)    LOG_MACRO(PDLogLevelWarn, userInfo, __VA_ARGS__)
#define PDLogError(userInfo, ...)   LOG_MACRO(PDLogLevelError, userInfo, __VA_ARGS__)
#define PDLogFatal(userInfo, ...)   LOG_MACRO(PDLogLevelFatal, userInfo, __VA_ARGS__)

NS_ASSUME_NONNULL_END
