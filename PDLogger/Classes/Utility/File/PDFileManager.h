//
//  PDFileManager.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>
#import "PDFileInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface PDFileManager : NSObject

@property (nonatomic, strong, readonly) NSString *rootPath;
// Information about the recently created file. Returns nil if it doesn't exist.
@property (nonatomic, strong, readonly, nullable) PDFileInfo *recentFileInfo;
// All file information in the current directory.
@property (nonatomic, readonly, nullable) NSArray<PDFileInfo *> *fileInfos;
// All file information in the current directory (in ascending order).
@property (nonatomic, readonly, nullable) NSArray<PDFileInfo *> *fileInfosByCreationDateAscendingOrder;
// The current directory in addition to the newly created file all other file information.
@property (nonatomic, readonly, nullable) NSArray<PDFileInfo *> *fileInfosExceptRecentFile;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithRootPath:(NSString *)rootPath NS_DESIGNATED_INITIALIZER;

- (nullable PDFileInfo *)switchFile; // Creates a new file and returns the file information.

- (BOOL)removeFile:(PDFileInfo *)fileInfo; // Deletes the specified file in the current path
- (BOOL)removeAllFiles; // Delete all files in the current path

// Set the filename generation rules
- (void)setFilenameFormatWithBlock:(NSString *(^)(PDFileManager *fm))block;

@end

NS_ASSUME_NONNULL_END
