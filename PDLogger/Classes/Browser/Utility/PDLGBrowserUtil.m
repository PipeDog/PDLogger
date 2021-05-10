//
//  PDLGBrowserUtil.m
//  PDLogger
//
//  Created by liang on 2021/5/10.
//

#import "PDLGBrowserUtil.h"

NSString *PDLGFormatByte(unsigned long long byte) {
    double convertedValue = byte;
    int multiplyFactor = 0;
    NSArray *tokens = @[@"B", @"KB", @"MB", @"GB", @"TB"];
    
    // https://www.zhihu.com/question/24601215
    while (convertedValue > 1000) {
        convertedValue /= 1000;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.2f %@", convertedValue, tokens[multiplyFactor]]; ;
}
