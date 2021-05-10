//
//  PDLogReporter.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PDLogReporter <NSObject>

@optional
- (void)reportLogFile:(NSString *)filePath
           completion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completion;

- (void)reportLogFiles:(NSArray<NSString *> *)filePaths
            completion:(void (^ _Nullable)(NSError * _Nullable error, NSArray<NSString *> * _Nullable failedList, NSArray<NSString *> * _Nullable finishedList))completion;

@end

NS_ASSUME_NONNULL_END
