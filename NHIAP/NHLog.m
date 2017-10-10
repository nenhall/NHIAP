//
//  NHLog.m
//  NHIAPDemo
//
//  Created by neghao on 2017/9/25.
//  Copyright © 2017年 neghao. All rights reserved.
//

#import "NHLog.h"



@implementation NHLog

// Log 开关状态，默认不输出log信息
static BOOL kNH_Log_Switch = YES;
static BOOL kNH_HLog_Switch = YES;

+ (BOOL)logEnable {
    return kNH_Log_Switch;
}
+ (BOOL)heightLogEnable {
    return kNH_HLog_Switch;
}

+ (void)setLogEnable:(BOOL)flag {
    kNH_Log_Switch = flag;
}
+ (void)setLogEnable_W_E_F:(BOOL)flag {
    kNH_HLog_Switch = flag;
}

void NHCustomLog(const char *func, NSString *format, ...)
{
    if ([NHLog logEnable]) {  // 开启了Log
        va_list args;
        va_start(args, format);
        NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
        NSString *strFormat = [NSString stringWithFormat:@"%s, %@",func,string];
        NSLogv(strFormat, args);
        va_end(args);
    }
}

void NHCustomHLog(const char *func, NSString *format, ...)
{
    if ([NHLog heightLogEnable]) {  // 开启了Log
        va_list args;
        va_start(args, format);
        NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
        NSString *strFormat = [NSString stringWithFormat:@"%s, %@",func,string];
        NSLogv(strFormat, args);
        va_end(args);
    }
}


@end
