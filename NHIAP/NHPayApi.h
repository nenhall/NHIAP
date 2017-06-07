//
//  NHApi.h
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/6.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ResultBlock)(id resultObject, NSError *error);

@interface NHPayApi : NSObject


/**
 苹果服务器验证支付结果

 @param isProductEnvironment 支付环境
 @param receiptStr  receiptData
 */
+ (void)IAPVerifyIsSandboxEnvironment:(BOOL)isProductEnvironment
                           receiptStr:(NSString *)receiptStr
                             complete:(ResultBlock)complete;


+ (void)payVerifyWithReceiptData:(NSString *)receiptData
                   transactionID:(NSString *)transactionID
                        totalFee:(NSString *)totalFee
                          userID:(NSString *)userID
                         is_test:(int)is_test
                        complete:(ResultBlock)complete;


+ (NSString *)getCurrentDateBaseStyle:(NSData *)data;

@end
