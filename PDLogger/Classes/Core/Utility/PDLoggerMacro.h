//
//  PDLoggerMacro.h
//  Pods
//
//  Created by liang on 2021/5/7.
//

#ifndef PDLoggerMacro_h
#define PDLoggerMacro_h

#ifndef weakify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
        #endif
    #endif
#endif

#ifndef strongify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
        #else
        #define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
        #else
        #define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
        #endif
    #endif
#endif


#ifndef PD_SUBCLASSING_FINAL
    #if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
        #define PD_SUBCLASSING_FINAL __attribute__((objc_subclassing_restricted))
    #else
        #define PD_SUBCLASSING_FINAL // Do nothing...
    #endif
#endif


#endif /* PDLoggerMacro_h */
