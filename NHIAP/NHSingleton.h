//
//  NHSingleton.h
//  NHShareHelperDemo
//
//  Created by NegHao.W on 17/2/1.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//
#include <UIKit/UIKit.h>

// .h文件
#define NSSingletonH(name) + (instancetype)shared##name;

// .m文件
#define NSSingletonM(name) \
static id _instance; \
\
+ (instancetype)allocWithZone:(struct _NSZone *)zone \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [super allocWithZone:zone]; \
}); \
return _instance; \
} \
\
+ (instancetype)shared##name \
{ \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [[self alloc] init]; \
}); \
return _instance; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return _instance; \
}

