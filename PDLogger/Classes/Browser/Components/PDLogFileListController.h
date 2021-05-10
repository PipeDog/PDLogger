//
//  PDLogFileListController.h
//  PDLogger
//
//  Created by liang on 2021/5/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDLogFileListController : UIViewController

@property (nonatomic, strong, readonly) NSString *rootPath;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (instancetype)initWithRootPath:(NSString *)rootPath NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
