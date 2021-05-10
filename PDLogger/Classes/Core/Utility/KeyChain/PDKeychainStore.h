//
//  PDKeychainStore.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDKeychainStore : NSObject

+ (BOOL)setValue:(id _Nullable)value forKey:(NSString *)key;
+ (BOOL)setValue:(id _Nullable)value forKey:(NSString *)key forAccessGroup:(NSString * _Nullable)group;

+ (id _Nullable)valueForKey:(NSString *)key;
+ (id _Nullable)valueForKey:(NSString *)key forAccessGroup:(NSString * _Nullable)group;

+ (BOOL)removeValueForKey:(NSString *)key;
+ (BOOL)removeValueForKey:(NSString *)key forAccessGroup:(NSString * _Nullable)group;

@end

NS_ASSUME_NONNULL_END
