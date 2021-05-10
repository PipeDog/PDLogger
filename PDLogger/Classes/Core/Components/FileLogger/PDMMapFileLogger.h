//
//  PDMMapFileLogger.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>
#import "PDFileLogger.h"

NS_ASSUME_NONNULL_BEGIN

@interface PDMMapFileLogger : NSObject <PDFileLogger>

@property (nonatomic, assign) NSUInteger maxFileSize;
@property (nonatomic, assign) NSUInteger maxCacheSpace;
@property (nonatomic, assign) NSTimeInterval logFileValidTimeLength;
@property (nonatomic, assign) NSTimeInterval autoTrimInterval;
@property (nonatomic, assign) BOOL enableTrimUnuploadFiles;

- (instancetype)initWithDirPath:(NSString * _Nullable)dirPath NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
