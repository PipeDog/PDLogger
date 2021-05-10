//
//  PDDefaultLogReporter.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDDefaultLogReporter.h"
#import "PDLoggerMacro.h"
#import "PDLoggerConstants.h"
#import "PDLoggerError.h"
#import "PDDataConvert.h"

static NSInteger const kPDLogReportSuccessStatusCode = 100000;

@interface PDLogReportOperation : NSOperation

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionUploadTask *task;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, copy) void (^completionHandler)(NSData *, NSURLResponse *, NSError *);


- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request
                        fileURL:(NSURL *)fileURL
              completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

@end

@implementation PDLogReportOperation

- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request
                        fileURL:(NSURL *)fileURL
              completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    self = [super init];
    if (self) {
        _session = session;
        _request = request;
        _fileURL = fileURL;
        _completionHandler = [completionHandler copy];
    }
    return self;
}

- (void)main {
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);
    
    @weakify(self)
    _task = [_session uploadTaskWithRequest:_request fromFile:_fileURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        @strongify(self)
        if (!self) { return; }
        
        !self.completionHandler ?: self.completionHandler(data, response, error);
        dispatch_semaphore_signal(lock);
    }];
    [_task resume];
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    
    [self cancel];
}

- (void)cancel {
    [super cancel];

    _task = nil;
    _session = nil;
    _request = nil;
    _fileURL = nil;
    _completionHandler = nil;
}

@end

@implementation PDDefaultLogReporter {
    NSURLSession *_session;
    NSOperationQueue *_queue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration];
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
        
        // TODO: 更换 baseUrl 和 urlPath
        _baseUrl = @"https://xxx.xxx";
        _urlPath = @"/xxx";
        _requestHeaders = nil;
        _timeoutInterval = 30.f;
    }
    return self;
}

#pragma mark - PDLogReporter
- (void)reportLogFile:(NSString *)filePath completion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSAssert(NO, @"Invalid file path!");
        NSError *error = PDLGError(1001, @"Invalid file path!");
        !completion ?: completion(NO, error);
        return;
    }
    
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSString *URLString = [NSString stringWithFormat:@"%@%@", self.baseUrl, self.urlPath];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = self.timeoutInterval;
    request.HTTPShouldHandleCookies = NO;
    request.allHTTPHeaderFields = self.requestHeaders;
    request.HTTPShouldUsePipelining = YES;
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    PDLogReportOperation *operation = [[PDLogReportOperation alloc] initWithSession:_session
                                                                            request:request
                                                                            fileURL:fileURL
                                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *HTTPResp = (NSHTTPURLResponse *)response;
            if (HTTPResp.statusCode != 200) {
                !completion ?: completion(NO, error);
                return;
            }
        }
        
        NSDictionary *dict = PDValueToJSONObject(data);
        NSInteger status = [(NSNumber *)dict[@"status"] integerValue];
        if (status != kPDLogReportSuccessStatusCode) {
            NSError *error = PDLGError(1002, @"Report log failed!");
            !completion ?: completion(NO, error);
            return;
        }
        
        !completion ?: completion(YES, nil);
    }];
    
    if (!operation) { return; }
    
    [_queue addOperation:operation];
}

- (void)reportLogFiles:(NSArray<NSString *> *)filePaths
            completion:(void (^)(NSError * _Nullable, NSArray<NSString *> * _Nullable, NSArray<NSString *> * _Nullable))completion {
    __block NSError *outError;
    NSMutableArray<NSString *> *finishedList = [NSMutableArray array];
    NSMutableArray<NSString *> *failedList = [NSMutableArray array];
    
    dispatch_group_t group = dispatch_group_create();
    for (NSString *filePath in filePaths) {
        dispatch_group_enter(group);
        [self reportLogFile:filePath completion:^(BOOL success, NSError * _Nullable error) {
            if (!outError && error) {
                outError = error;
            }

            if (success) {
                [finishedList addObject:filePath];
            } else {
                [failedList addObject:filePath];
            }
            
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        !completion ?: completion(outError, failedList, finishedList);
    });
}

@end
