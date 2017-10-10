//
//  NHOrderVerify.h
//  NHIAPDemo
//
//  Created by neghao on 2017/9/26.
//  Copyright © 2017年 neghao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>


typedef NS_ENUM(NSInteger, NHVerifyStatus) {
    NHVerifyStatusReceiptError = -99993,//receipt错误：可能是数据为空
    NHVerifyStatusReceiptTransactionMismatching = -99994,//receipt数据验证的结果与payTransaction的信息不一致
    NHVerifyStatusReceiptVerifyError = -99995,//receipt数据在apple验证失败：receipt数据可能是无效的(eg：假的)
    NHVerifyStatusOtherError = -100000,//其它错误，具体请看当时返回的`NSError *error`
};

typedef  void(^NHVerifyPaymentFailure)(SKPaymentTransaction *payTransaction, NSError *error);
typedef  void(^NHVerifyPaymentSuccess)(SKPaymentTransaction *payTransaction, id result, BOOL sandbox);


@interface NHOrderVerify : NSObject


/**
 验证充值的有效性

 @param payTransaction 交易订单
 */
+ (void)orderVerifyPaymentTransaction:(SKPaymentTransaction *)payTransaction
                              success:(NHVerifyPaymentSuccess)success
                              failure:(NHVerifyPaymentFailure)failure;


/**
 支付环境
 */
+ (NSString * )environmentForReceipt:(NSString *)str;
+ (BOOL)environmentEqualToSandbox:(SKPaymentTransaction *)payTransaction;

@end
