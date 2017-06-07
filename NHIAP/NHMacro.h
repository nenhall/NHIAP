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

//自定提醒窗口
NS_INLINE void tipWithMessage(NSString *message){
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [alerView show];
        [alerView performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:@[@0, @1] afterDelay:1.5];
    });
}

//自定提醒窗口
NS_INLINE void tipWithMessages(NSString *message, id delegate, NSString *cancelTitle, NSString *otherTitle){
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

//错误
#define ERROR_MSG(Description,FailureReason,RecoverySuggestion)  [NSDictionary dictionaryWithObjectsAndKeys:(Description),NSLocalizedDescriptionKey,\
(FailureReason),NSLocalizedFailureReasonErrorKey,\
(RecoverySuggestion),NSLocalizedRecoverySuggestionErrorKey, nil]
#define ERROR_STATUS(statusCode,info)  [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:(statusCode) userInfo:(info)]

#import "NHSingleton.h"

///*****************************自定义的 NSLog******************************/
#ifdef DEBUG
#define NHNSLog(fmt, ...) NSLog((@"%s -- " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__);
#else
#define NHNSLog(...)
#endif

#endif /* NHMacro_h */
