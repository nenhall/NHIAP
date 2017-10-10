//
//  NHLog.h
//  NHIAPDemo
//
//  Created by neghao on 2017/9/25.
//  Copyright © 2017年 neghao. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  自定义Log，可配置开关（用于替换NSLog）
 */
#define NHLog(format,...) NHCustomLog(__FUNCTION__,format,##__VA_ARGS__)

//重要打印
#define NHWEFLog(format,...) NHCustomHLog(__FUNCTION__,format,##__VA_ARGS__)

#ifdef DEBUG
#define NHCLog(FORMAT, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NHCLog(...)
#endif

/**
 *  自定义Log
 *  @warning 外部可直接调用 NHNSLog
 *
 *  @param func         方法名
 *  @param format       Log内容
 *  @param ...          个数可变的Log参数
 */
void NHCustomLog(const char *func, NSString *format, ...);
void NHCustomHLog(const char *func, NSString *format, ...);

/**
 *  自定义Log类，外部控制Log开关
 */
@interface NHLog : NSObject

/**
 Log 输出开关(默认允许所有打印)
 */
+ (void)setLogEnable:(BOOL)flag;


/**
 Log 输出开关，只允许Warn、Error、Fatal级别的日志打印 (默认开启)
 优先级高于：`setLogEnable:` setLogEnable_W_E_F为yes，Warn、Error、Fatal级别的日志不受`setLogEnable:`影响
 */
+ (void)setLogEnable_W_E_F:(BOOL)flag;


/**
 *  是否开启了 Log 输出
 *
 *  @return Log 开关状态
 */
+ (BOOL)logEnable;
+ (BOOL)heightLogEnable;



@end
