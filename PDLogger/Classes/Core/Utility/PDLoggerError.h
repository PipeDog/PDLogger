//
//  PDLoggerError.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSError *PDLGErrorWithDomain(NSErrorDomain domain, NSInteger code, NSString *fmt, ...);
FOUNDATION_EXPORT NSError *PDLGError(NSInteger code, NSString *fmt, ...);
FOUNDATION_EXPORT NSErrorDomain PDLGErrorGetDomain(NSError *error);
FOUNDATION_EXPORT NSInteger PDLGErrorGetCode(NSError *error);
FOUNDATION_EXPORT NSString *PDLGErrorGetMessage(NSError *error);

NS_ASSUME_NONNULL_END
