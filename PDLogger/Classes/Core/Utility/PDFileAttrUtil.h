//
//  PDFileAttrUtil.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT BOOL PDFileSetExtendedAttributes(NSString *filePath, NSString *key, NSString * _Nullable value);
FOUNDATION_EXPORT NSString * _Nullable PDFileGetExtendedAttributes(NSString *filePath, NSString *key);

NS_ASSUME_NONNULL_END
