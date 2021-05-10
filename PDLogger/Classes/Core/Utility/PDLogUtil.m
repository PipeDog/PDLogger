//
//  PDLogUtil.m
//  PDLogger
//
//  Created by liang on 2021/5/7.
//

#import "PDLogUtil.h"

BOOL PDLogLevelValid(PDLogLevel level) {
    switch (level) {
        case PDLogLevelDebug:
        case PDLogLevelInfo:
        case PDLogLevelWarn:
        case PDLogLevelError:
        case PDLogLevelFatal: {
            return YES;
        }
        default: {
            return NO;
        }
    }
}

NSString *PDLogGetFlag(PDLogLevel level) {
    switch (level) {
        case PDLogLevelDebug: return @"Debug";
        case PDLogLevelInfo: return @"Info";
        case PDLogLevelWarn: return @"Warn";
        case PDLogLevelError: return @"Error";
        case PDLogLevelFatal: return @"Fatal";
        default: return @"Undefined";
    }
}
