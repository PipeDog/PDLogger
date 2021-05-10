//
//  PDFileCleaner.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSUInteger const PDFileCleanDefaultCostLimit; ///< 1 GB
FOUNDATION_EXPORT NSTimeInterval const PDFileCleanDefaultAgeLimit; ///< 7 Days
FOUNDATION_EXPORT NSTimeInterval const PDFileCleanDefaultAutoTrimInterval; ///< 1 Mins

@class PDFileCleaner;

@protocol PDFileCleanerDelegate <NSObject>

@optional
- (BOOL)fileCleaner:(PDFileCleaner *)fileCleaner shouldRemoveFileAtPath:(NSString *)filePath;
- (void)fileCleaner:(PDFileCleaner *)fileCleaner didRemoveFileAtPath:(NSString *)filePath;
- (void)fileCleaner:(PDFileCleaner *)fileCleaner didFailRemoveFileAtPath:(NSString *)filePath withError:(NSError *)error;

@end

@interface PDFileCleaner : NSObject

@property (nonatomic, strong, readonly) NSString *path;
@property (nonatomic, weak, nullable) id<PDFileCleanerDelegate> delegate;

@property (atomic, assign) NSUInteger costLimit;
@property (atomic, assign) NSTimeInterval ageLimit;
@property (atomic, assign) NSTimeInterval autoTrimInterval;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithPath:(NSString *)path;
- (nullable instancetype)initWithPath:(NSString *)path queue:(nullable dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;

- (void)trimRecursively; // Regularly cleaned
- (void)trim; // Single clean
- (void)trimWithBlock:(void (^)(void))block; // Single clean with callback

- (void)stopTrim; // Stop file cleaning

@end

NS_ASSUME_NONNULL_END
