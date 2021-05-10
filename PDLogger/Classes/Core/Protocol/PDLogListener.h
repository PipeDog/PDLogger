//
//  PDLogListener.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>
#import "PDLogMessage.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PDLogListener <NSObject>

- (void)log:(id<PDLogMessage>)logMessage formattedLog:(NSString *)log;

@end

NS_ASSUME_NONNULL_END
