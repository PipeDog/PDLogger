//
//  PDExceptionListener.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PDExceptionListener <NSObject>

/* @brief Catch exception callbacks
 * @param formattedInformation Formatted exception message */
- (void)didCatchExceptionWithFormattedInformation:(NSString *)formattedInformation;

@end

#define PD_EXCEPTION_NOTIFY_LISTENER_INSTALL()                                                  \
+ (void)addListener:(id<PDExceptionListener>)listener {                                         \
    if (!listener) { return; }                                                                  \
                                                                                                \
    NSHashTable *listeners = objc_getAssociatedObject(self, _cmd);                              \
    if (!listeners) {                                                                           \
        listeners = [NSHashTable weakObjectsHashTable];                                         \
        objc_setAssociatedObject(self, _cmd, listeners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);     \
    }                                                                                           \
                                                                                                \
    if ([listener respondsToSelector:@selector(didCatchExceptionWithFormattedInformation:)]) {  \
        [listeners addObject:listener];                                                         \
    }                                                                                           \
}                                                                                               \
                                                                                                \
+ (void)removeListener:(id<PDExceptionListener>)listener {                                      \
    NSHashTable *listeners = objc_getAssociatedObject(self, @selector(addListener:));           \
    if (!listeners) { return; }                                                                 \
                                                                                                \
    if ([listeners containsObject:listener]) {                                                  \
        [listeners removeObject:listener];                                                      \
    }                                                                                           \
}                                                                                               \
                                                                                                \
+ (void)notifyListeners:(NSString *)formattedInformation {                                      \
    NSHashTable *listeners = objc_getAssociatedObject(self, @selector(addListener:));           \
    if (!listeners) { return; }                                                                 \
                                                                                                \
    NSArray<id<PDExceptionListener>> *allListeners = listeners.allObjects;                      \
                                                                                                \
    for (id<PDExceptionListener> listener in allListeners) {                                    \
        [listener didCatchExceptionWithFormattedInformation:formattedInformation];              \
    }                                                                                           \
}

NS_ASSUME_NONNULL_END
