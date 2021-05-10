//
//  PDUncaughtExceptionHandler.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>
#import "PDExceptionListener.h"
#import "PDLoggerMacro.h"

NS_ASSUME_NONNULL_BEGIN

PD_SUBCLASSING_FINAL
@interface PDUncaughtExceptionHandler : NSObject

+ (void)registerHandler;

+ (void)addListener:(id<PDExceptionListener>)listener;
+ (void)removeListener:(id<PDExceptionListener>)listener;

@end

NS_ASSUME_NONNULL_END
