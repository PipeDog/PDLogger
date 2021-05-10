//
//  PDKeychainStore.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDKeychainStore.h"

@implementation PDKeychainStore

+ (BOOL)setValue:(id)value forKey:(NSString *)key {
    return [self setValue:value forKey:key forAccessGroup:nil];
}

+ (BOOL)setValue:(id)value forKey:(NSString *)key forAccessGroup:(NSString *)group {
    NSMutableDictionary *query = [self getKeychainQuery:key forAccessGroup:group];
    [self removeValueForKey:key forAccessGroup:group];
    NSData *data = nil;
    @try {
        data = [NSKeyedArchiver archivedDataWithRootObject:value];
    } @catch (NSException *exception) {
        NSLog(@"archived failure value %@  %@",value,exception);
        return NO;
    }
    
    [query setObject:data forKey:(__bridge id)kSecValueData];
    OSStatus result = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    return result == errSecSuccess;
}

+ (id)valueForKey:(NSString *)key {
    return [self valueForKey:key forAccessGroup:nil];
}

+ (id)valueForKey:(NSString *)key forAccessGroup:(NSString *)group {
    id value = nil;
    NSMutableDictionary *query = [self getKeychainQuery:key forAccessGroup:group];
    CFDataRef keyData = NULL;
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&keyData) == errSecSuccess) {
        @try {
            value = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        }
        @catch (NSException *e) {
            NSLog(@"Unarchive of %@ failed: %@", key, e);
            value = nil;
        }
        
    }
    
    if (keyData) {
        CFRelease(keyData);
    }
    return value;
}

+ (BOOL)removeValueForKey:(NSString *)key {
    return [self removeValueForKey:key forAccessGroup:nil];
}

+ (BOOL)removeValueForKey:(NSString *)key forAccessGroup:(NSString *)group {
    NSMutableDictionary *query = [self getKeychainQuery:key forAccessGroup:group];
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)query);
    return result == errSecSuccess;
}

+ (NSString *)getBundleSeedIdentifier {
    static NSString *bundleSeedIdentifier = nil;
    
    if (bundleSeedIdentifier == nil) {
        @synchronized(self) {
            if (bundleSeedIdentifier == nil) {
                NSString *_bundleSeedIdentifier = nil;
                NSDictionary *query = @{
                                        (__bridge id)kSecClass: (__bridge NSString *)kSecClassGenericPassword,
                                        (__bridge id)kSecAttrAccount: @"bundleSeedID",
                                        (__bridge id)kSecAttrService: @"",
                                        (__bridge id)kSecReturnAttributes: (__bridge id)kCFBooleanTrue
                                        };
                CFDictionaryRef result = nil;
                OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
                if (status == errSecItemNotFound) {
                    status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
                }
                if (status == errSecSuccess) {
                    NSString *accessGroup = [(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kSecAttrAccessGroup];
                    NSArray *components = [accessGroup componentsSeparatedByString:@"."];
//                    NSLog(@"components %@",components);
                    _bundleSeedIdentifier = [[components objectEnumerator] nextObject];
                    CFRelease(result);
                }
                if (_bundleSeedIdentifier != nil) {
                    bundleSeedIdentifier = [_bundleSeedIdentifier copy];
                }
            }
        }
    }
    
    return bundleSeedIdentifier;
}

#pragma mark - Private Methods
+ (NSMutableDictionary *)getKeychainQuery:(NSString *)key forAccessGroup:(NSString *)group {
    NSMutableDictionary *query = @{(__bridge id)kSecClass                   : (__bridge id)kSecClassGenericPassword,
                                          (__bridge id)kSecAttrService      : key,
                                          (__bridge id)kSecAttrAccount      : key,
                                          (__bridge id)kSecAttrAccessible   : (__bridge id)kSecAttrAccessibleAfterFirstUnlock
                                          }.mutableCopy;
    if (group != nil) {
        [query setObject:[self getFullAccessGroup:group] forKey:(__bridge id)kSecAttrAccessGroup];
    }
    
    return query;
}

+ (NSString *)getFullAccessGroup:(NSString *)group {
    NSString *accessGroup = nil;
    NSString *bundleSeedIdentifier = [self getBundleSeedIdentifier];
    if (bundleSeedIdentifier != nil && [group rangeOfString:bundleSeedIdentifier].location == NSNotFound) {
        accessGroup = [NSString stringWithFormat:@"%@.%@", bundleSeedIdentifier, group];
    }
    return accessGroup;
}

@end
