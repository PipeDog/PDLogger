//
//  PDLogFileListController.m
//  PDLogger
//
//  Created by liang on 2021/5/10.
//

#import "PDLogFileListController.h"
#import "PDLogBrowserController.h"
#import "PDLogPreviewController.h"
#import "PDFileInfo.h"
#import "PDLGBrowserUtil.h"

@interface PDLogFileListController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSArray<PDFileInfo *> *logFileInfos;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation PDLogFileListController

- (instancetype)initWithRootPath:(NSString *)rootPath {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _rootPath = rootPath;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupInitializeConfiguration];
    [self createViewHierarchy];
    [self loadLogsWithPath:self.rootPath];
}

- (void)setupInitializeConfiguration {
    self.title = @"日志";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(didClickDismissBarButtonItem:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                           target:self
                                                                                           action:@selector(didClickTrashBarButtonItem:)];
}

- (void)createViewHierarchy {
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.activityIndicatorView];
}

#pragma mark - Event Methods
- (void)didClickDismissBarButtonItem:(UIBarButtonItem *)sender {
    if (!self.navigationController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    if ([self.navigationController isKindOfClass:[PDLogBrowserController class]]) {
        PDLogBrowserController *navigationController = (PDLogBrowserController *)self.navigationController;
        [navigationController hideWithAnimated:YES completion:nil];
        return;
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didClickTrashBarButtonItem:(UIBarButtonItem *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"清理日志" message:@"是否清空本地所有日志文件？" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        for (PDFileInfo *fileInfo in self.logFileInfos) {
            [[NSFileManager defaultManager] removeItemAtPath:fileInfo.filePath error:nil];
        }
        
        [self loadLogsWithPath:self.rootPath];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Load Methods
- (void)loadLogsWithPath:(NSString *)path {
    [self.activityIndicatorView startAnimating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.logFileInfos = [self logFileInfosAtPath:self.rootPath];
        self.logFileInfos = [self sortFileInfosByCreationDateDescendingOrder:self.logFileInfos];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.activityIndicatorView stopAnimating];
            self.title = [NSString stringWithFormat:@"日志（%zd 个文件）", self.logFileInfos.count];
        });
    });
}

- (NSArray<PDFileInfo *> *)logFileInfosAtPath:(NSString *)path {
    if (!path.length) {
        return @[];
    }

    NSMutableArray<PDFileInfo *> *logFileInfos = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray<NSString *> *paths = [fileManager contentsOfDirectoryAtPath:path error:&error];
    
    for (NSString *tmpPath in paths) {
        // Filter hidden files.
        if ([[tmpPath lastPathComponent] hasPrefix:@"."]) {
            continue;
        }
        
        BOOL isDirectory = NO;
        NSString *fullPath = [path stringByAppendingPathComponent:tmpPath];
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
                
        if (fullPath.length > 0 && !isDirectory) {
            PDFileInfo *fileInfo = [[PDFileInfo alloc] initWithFilePath:fullPath];
            [logFileInfos addObject:fileInfo];
        }
    }
    
    return logFileInfos;
}

#pragma mark - Sort Methods
- (NSArray<PDFileInfo *> *)sortFileInfosByCreationDateDescendingOrder:(NSArray<PDFileInfo *> *)fileInfos {
    return [fileInfos sortedArrayUsingComparator:^NSComparisonResult(PDFileInfo * _Nonnull obj1, PDFileInfo * _Nonnull obj2) {
        return [obj2.fileCreationDate compare:obj1.fileCreationDate];
    }];
}

#pragma mark - UITableView Delegate && DataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.logFileInfos.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([UITableViewCell class])];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    PDFileInfo *logFileInfo = self.logFileInfos[indexPath.row];
    cell.textLabel.text = logFileInfo.filename;
    cell.detailTextLabel.text = PDLGFormatByte(logFileInfo.fileSize);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    PDFileInfo *logFileInfo = self.logFileInfos[indexPath.row];
    PDLogPreviewController *controller = [[PDLogPreviewController alloc] initWithLogPath:logFileInfo.filePath];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Getter Methods
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.tableFooterView = [[UIView alloc] init];
    }
    return _tableView;
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

@end
