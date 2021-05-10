//
//  PDViewController.m
//  PDLogger
//
//  Created by liang on 05/10/2021.
//  Copyright (c) 2021 liang. All rights reserved.
//

#import "PDViewController.h"
#import <PDLogBrowserController.h>
#import <PDLogger.h>

@interface PDViewController ()

@end

@implementation PDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)didClickLogBrowserButton:(id)sender {
    PDLogBrowserController *controller = [[PDLogBrowserController alloc] init];
    [controller showWithAnimated:YES completion:nil];
}

- (IBAction)didClickWriteLogButton:(id)sender {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 3;
    
    dispatch_group_t group = dispatch_group_create();
    
    PDLogDebug(nil, @"====================== log start ======================");

    for (NSInteger i = 0; i < 10000; i++) {
        dispatch_group_enter(group);
        [queue addOperationWithBlock:^{
            PDLogDebug(nil, @"log index = %zd", i);
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        PDLogDebug(nil, @"====================== log end ======================");
    });
}

@end
