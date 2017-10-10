//
//  NHMacro.h
//  NHIAPDemo
//
//  Created by neghao on 2017/6/7.
//  Copyright © 2017年 neghao. All rights reserved.
//

#ifndef NHMacro_h
#define NHMacro_h

#ifdef __OBJC__
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#endif

#import "NHSingleton.h"


//自定提醒窗口
NS_INLINE void NHIAPTipWithMessage(NSString *message){
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [alerView show];
        [alerView performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:@[@0, @1] afterDelay:1.5];
    });
}

//自定提醒窗口
NS_INLINE void NHIAPDEBUGTipWithMessage(NSString *message){
#ifdef DEBUG
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [alerView show];
        [alerView performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:@[@0, @1] afterDelay:1.5];
    });
#else
    NSLog(@"%s->>%@",message);
#endif
}

//自定提醒窗口
NS_INLINE void NHIAPTipWithMessages(NSString *message, id delegate, NSString *cancelTitle, NSString *otherTitle){
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:delegate cancelButtonTitle:cancelTitle otherButtonTitles:otherTitle, nil];
        [alerView show];
        //        [alerView performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:@[@0, @1] afterDelay:0.9];
    });
}

#define kNotificationCenter   [NSNotificationCenter defaultCenter]
#define kBundleDictionary     [[NSBundle mainBundle] infoDictionary]

// app版本
#define kApp_version         [kBundleDictionary objectForKey:@"CFBundleShortVersionString"]
// app build版本
#define kApp_build_version    [kBundleDictionary objectForKey:@"CFBundleVersion"]

//获取BundleID
#define NHGetBundleID        [kBundleDictionary objectForKey:@"CFBundleIdentifier"]


//错误
#define NHEorrorinfo(statusCode, description, failureReason, recoverySuggestionError) [NSError errorWithDomain:NSCocoaErrorDomain \
code:(statusCode) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:\
(description),NSLocalizedDescriptionKey,\
(failureReason),NSLocalizedFailureReasonErrorKey,\
(recoverySuggestionError),NSLocalizedRecoverySuggestionErrorKey, nil]]


#define nh_safe_block(block,...)\
if (block) {\
block(__VA_ARGS__);\
}


#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif



#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif



#endif /* NHMacro_h */
