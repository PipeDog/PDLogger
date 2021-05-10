//
//  PDFileLogger.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>
#import "PDLoggerConstants.h"
#import "PDLoggerInternalConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class PDFileInfo;
@protocol PDFileLogger;

@protocol PDFileLoggerDelegate <NSObject>

- (void)fileLogger:(id<PDFileLogger>)fileLogger dumpLogsFromFileInfos:(NSArray<PDFileInfo *> *)fileInfos;

@end

@protocol PDFileLogger <NSObject>

@property (nonatomic, weak, nullable) id<PDFileLoggerDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *logDirPath;

- (void)log:(NSString *)logMessage;
- (NSArray<PDFileInfo *> *)fileInfosShouldDump;
- (BOOL)removeFile:(PDFileInfo *)fileInfo;
- (BOOL)setUploadState:(PDLogFileUploadState)state forFilePath:(NSString *)filePath;
- (void)switchFile;

@end

NS_ASSUME_NONNULL_END
