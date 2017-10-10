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
        [NHIAP restoreTransaction:^(NSArray<SKProduct *> * _Nullable products) {
            
        } success:^(SKPaymentTransaction * _Nullable payTransaction, BOOL environmentSandbox) {
            
        } failure:^(SKPaymentTransaction * _Nullable transaction, NSError * _Nullable error) {
            
        }];
    
    });
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {

    [[NHIAP sharedNHIAP] removeTransactionObserver];
}




@end
