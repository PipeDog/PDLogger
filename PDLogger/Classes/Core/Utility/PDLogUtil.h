//
//  PDLogUtil.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>
#import "PDLoggerConstants.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT BOOL PDLogLevelValid(PDLogLevel level);

FOUNDATION_EXPORT NSString *PDLogGetFlag(PDLogLevel level);

NS_ASSUME_NONNULL_END
