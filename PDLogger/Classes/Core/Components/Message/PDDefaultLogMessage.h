//
//  PDDefaultLogMessage.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>
#import "PDLogMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface PDDefaultLogMessage : NSObject <PDLogMessage>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
