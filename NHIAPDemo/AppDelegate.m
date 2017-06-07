//
//  AppDelegate.m
//  NHIAPDemo
//
//  Created by neghao on 2017/6/7.
//  Copyright © 2017年 neghao. All rights reserved.
//

#import "AppDelegate.h"
#import "NHIAP.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    dispatch_async(dispatch_queue_create(NULL, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        //检查有无未完成充值的订单
        [[NHIAP sharedNHIAP] checkAllUnfinishedOrderIsFromBackground:NO];
    });
    return YES;
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    dispatch_async(dispatch_queue_create(NULL, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        //检查有无未完成充值的订单
        [[NHIAP sharedNHIAP] checkAllUnfinishedOrderIsFromBackground:NO];
    });
}




@end
