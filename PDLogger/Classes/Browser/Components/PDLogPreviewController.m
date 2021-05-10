//
//  PDLogPreviewController.m
//  PDLogger
//
//  Created by liang on 2021/5/10.
//

#import "PDLogPreviewController.h"

@interface PDLogPreviewController ()

@property (nonatomic, strong) NSString *logPath;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UIButton *goDownButton;

@end

@implementation PDLogPreviewController

- (instancetype)initWithLogPath:(NSString *)logPath {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _logPath = [logPath copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupInitializeConfiguration];
    [self createViewHierarchy];
    [self loadFileAtPath:self.logPath];
}

- (void)setupInitializeConfiguration {
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"分享" style:UIBarButtonItemStylePlain target:self action:@selector(didClickShareBarButtonItem:)];
}

- (void)createViewHierarchy {
    [self.view addSubview:self.textView];
    [self.view addSubview:self.activityIndicatorView];
    [self.view addSubview:self.goDownButton];
}

#pragma mark - NEFilePreviewControllerDelegate
- (void)loadFileAtPath:(NSString *)filePath {
    if (!filePath.length) { return; }
    
    self.title = [filePath lastPathComponent];
    [self.activityIndicatorView startAnimating];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.textView.text = text;
            [self.activityIndicatorView stopAnimating];
        });
    });
}

#pragma mark - Event Methods
- (void)didClickShareBarButtonItem:(UIBarButtonItem *)sender {
    if (!self.logPath.length) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *fileData = [NSData dataWithContentsOfFile:self.logPath];
        NSURL *fileURL = [NSURL fileURLWithPath:self.logPath];

        dispatch_async(dispatch_get_main_queue(), ^{
            UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[fileData, fileURL] applicationActivities:nil];
            __weak UIActivityViewController *weakController = controller;
            controller.completionWithItemsHandler = ^(UIActivityType activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                [weakController dismissViewControllerAnimated:YES completion:nil];
            };
            [self presentViewController:controller animated:YES completion:nil];
        });
    });
}

- (void)didClickGoDownButton:(UIButton *)sender {
    NSRange range = NSMakeRange(self.textView.text.length - 1, 1);
    [self.textView scrollRangeToVisible:range];
}

#pragma mark - Getter Methods
- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:self.view.bounds];
        _textView.backgroundColor = [UIColor whiteColor];
        _textView.font = [UIFont systemFontOfSize:12];
        _textView.textColor = [UIColor darkTextColor];
        _textView.editable = NO;
        _textView.selectable = YES;
    }
    return _textView;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        
        CGSize size = CGSizeMake(100.f, 100.f);
        CGRect rect = CGRectMake((CGRectGetWidth(self.view.bounds) - size.width) / 2.f,
                                 (CGRectGetHeight(self.view.bounds) - size.height) / 2.f,
                                 size.width,
                                 size.height);
        _activityIndicatorView.frame = rect;
    }
    return _activityIndicatorView;
}

- (UIButton *)goDownButton {
    if (!_goDownButton) {
        _goDownButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat width = 44.f;
        _goDownButton.frame = CGRectMake(CGRectGetMaxX(self.view.bounds) - width - 16.f,
                                         CGRectGetMaxY(self.view.bounds) / 2 + 16.f,
                                         width,
                                         width);

        _goDownButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f];
        [_goDownButton setTitle:@"V" forState:UIControlStateNormal];
        [_goDownButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _goDownButton.titleLabel.font = [UIFont systemFontOfSize:24];
        [_goDownButton addTarget:self action:@selector(didClickGoDownButton:) forControlEvents:UIControlEventTouchUpInside];
        _goDownButton.layer.cornerRadius = width / 2.f;
        _goDownButton.layer.masksToBounds = YES;
    }
    return _goDownButton;
}

@end
