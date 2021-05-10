//
//  PDLogFileUtil.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>
#import "PDLoggerInternalConstants.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT BOOL PDLogFileSetUploadState(NSString *filePath, PDLogFileUploadState state);
FOUNDATION_EXPORT PDLogFileUploadState PDLogFileGetUploadState(NSString *filePath);

NS_ASSUME_NONNULL_END
