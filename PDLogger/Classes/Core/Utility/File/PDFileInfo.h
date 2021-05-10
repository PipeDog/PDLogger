//
//  PDFileInfo.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDFileInfo : NSObject

@property (nonatomic, strong, readonly) NSString *filePath;
@property (nonatomic, strong, readonly, nullable) NSString *filename;
@property (nonatomic, assign, readonly) BOOL isDirectory;
@property (nonatomic, strong, readonly, nullable) NSDictionary<NSFileAttributeKey, id> *fileAttributes;
@property (nonatomic, strong, readonly, nullable) NSDate *fileCreationDate;
@property (nonatomic, strong, readonly, nullable) NSDate *fileModificationDate;
@property (nonatomic, assign, readonly) unsigned long long fileSize;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithFilePath:(NSString *)filePath NS_DESIGNATED_INITIALIZER;

- (void)setNeedsUpdate; // File changes, update related properties

@end

NS_ASSUME_NONNULL_END
