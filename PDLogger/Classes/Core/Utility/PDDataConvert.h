//
//  PDDataConvert.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT id _Nullable PDValueToJSONObject(id _Nullable value);
FOUNDATION_EXPORT NSData * _Nullable PDValueToData(id _Nullable value);
FOUNDATION_EXPORT NSString * _Nullable PDValueToJSONText(id _Nullable value);

NS_ASSUME_NONNULL_END
