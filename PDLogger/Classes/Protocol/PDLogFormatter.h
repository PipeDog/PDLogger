//
//  PDLogFormatter.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PDLogMessage;

@protocol PDLogFormatter <NSObject>

- (NSString *)formatLogMessage:(id<PDLogMessage>)logMessage;

@optional
- (void)setDateFormatter:(NSDateFormatter *)dateFormatter;

@end

NS_ASSUME_NONNULL_END
