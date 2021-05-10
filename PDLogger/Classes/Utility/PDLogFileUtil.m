//
//  PDLogFileUtil.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDLogFileUtil.h"
#import "PDFileAttrUtil.h"

static NSString *const PDLogFileUploadStateKey = @"PDLogFileUploadState";

BOOL PDLogFileSetUploadState(NSString *filePath, PDLogFileUploadState state) {
    NSString *string = [NSString stringWithFormat:@"%lu", (unsigned long)state];
    BOOL result = PDFileSetExtendedAttributes(filePath, PDLogFileUploadStateKey, string);
    return result;
}

PDLogFileUploadState PDLogFileGetUploadState(NSString *filePath) {
    NSString *string = PDFileGetExtendedAttributes(filePath, PDLogFileUploadStateKey);
    PDLogFileUploadState state = [string integerValue];
    return state;
}
