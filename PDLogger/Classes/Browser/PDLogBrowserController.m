//
//  PDLogBrowserController.m
//  PDLogger
//
//  Created by liang on 2021/5/10.
//

#import "PDLogBrowserController.h"
#import "PDLogFileListController.h"
#import "PDLogger.h"

@interface PDLogBrowserController ()

@property (nonatomic, strong) UIWindow *bindWindow;

@end

@implementation PDLogBrowserController

- (instancetype)init {
    NSString *path = [PDLogger defaultLogger].fileLogger.logDirPath;
    PDLogFileListController *listController = [[PDLogFileListController alloc] initWithRootPath:path];
    
    self = [super initWithRootViewController:listController];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationBar.tintColor = [UIColor blackColor];
}

#pragma mark - Public Methods
- (void)showWithAnimated:(BOOL)animated completion:(void (^)(void))completion {
    [self.bindWindow makeKeyAndVisible];
    [self.bindWindow.rootViewController presentViewController:self animated:animated completion:completion];
}

- (void)hideWithAnimated:(BOOL)animated completion:(void (^)(void))completion {
    [self dismissViewControllerAnimated:YES completion:^{
        self->_bindWindow = nil;
        !completion ?: completion();
    }];
}

#pragma mark - Getter Methods
- (UIWindow *)bindWindow {
    if (!_bindWindow) {
        _bindWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _bindWindow.rootViewController = [UIViewController new];
        _bindWindow.windowLevel = UIWindowLevelAlert + 1;
    }
    return _bindWindow;
}

@end
