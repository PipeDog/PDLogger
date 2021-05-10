//
//  PDMMapFileReaderWriter.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDMMapFileReaderWriter : NSObject

@property (nonatomic, strong, readonly) NSString *filePath;
@property (nonatomic, assign, readonly) size_t maxFileSize;
@property (nonatomic, assign, readonly) size_t currentFileSize;

@property (nonatomic, assign) NSUInteger syncToDiskCount;
@property (nonatomic, assign) NSUInteger syncToDiskSize;
@property (nonatomic, assign) NSTimeInterval syncToDiskTimeInterval;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithFilePath:(NSString *)filePath NS_DESIGNATED_INITIALIZER;

- (BOOL)appendFormat:(NSString *)format, ...;
- (BOOL)appendString:(NSString *)string;

- (void)terminate;

@end

NS_ASSUME_NONNULL_END
