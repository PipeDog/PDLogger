//
//  PDLogMessage.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>
#import "PDLoggerConstants.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PDLogMessage <NSObject>

@property (nonatomic, strong, readonly, nullable) NSString *message;
@property (nonatomic, assign, readonly) PDLogLevel level;
@property (nonatomic, strong, readonly) NSString *file;
@property (nonatomic, strong, readonly) NSString *filename;
@property (nonatomic, strong, readonly) NSString *functionName;
@property (nonatomic, assign, readonly) NSUInteger line;
@property (nonatomic, strong, readonly, nullable) NSDictionary *userInfo;
@property (nonatomic, strong, readonly) NSDate *date;
@property (nonatomic, strong, readonly) NSString *threadID;
@property (nonatomic, strong, readonly) NSString *threadName;
@property (nonatomic, strong, readonly) NSString *queueLabel;

- (instancetype)initWithMessage:(NSString * _Nullable)message
                          level:(PDLogLevel)level
                           file:(NSString *)file
                   functionName:(NSString *)functionName
                           line:(NSUInteger)line
                       userInfo:(NSDictionary * _Nullable)userInfo
                           date:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
