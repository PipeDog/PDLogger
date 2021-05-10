//
//  PDLoggerInternalConstants.h
//  Pods
//
//  Created by liang on 2021/5/7.
//

#ifndef PDLoggerInternalConstants_h
#define PDLoggerInternalConstants_h

typedef NS_ENUM(NSUInteger, PDLogFileUploadState) {
    PDLogFileUploadStateUnupload    = 0,
    PDLogFileUploadStateUploading   = 1,
    PDLogFileUploadStateUploaded    = 2,
    PDLogFileUploadStateFailed      = PDLogFileUploadStateUnupload,
};

#endif /* PDLoggerInternalConstants_h */
