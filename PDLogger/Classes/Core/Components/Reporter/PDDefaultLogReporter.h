//
//  PDDefaultLogReporter.h
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import <Foundation/Foundation.h>
#import "PDLogReporter.h"

NS_ASSUME_NONNULL_BEGIN

@interface PDLogReporterConfiguration : NSObject

@property (class, strong, readonly) PDLogReporterConfiguration *defaultConfiguration;

@property (nonatomic, strong) NSString *baseUrl;
@property (nonatomic, strong) NSString *urlPath;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *requestHeaders;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

@end

@interface PDDefaultLogReporter : NSObject <PDLogReporter>

- (instancetype)initWithConfiguration:(PDLogReporterConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
