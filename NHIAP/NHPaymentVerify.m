//
//  NHPaymentVerify.m
//  BaiKeMiJiaLive
//
//  Created by neghao on 2017/5/26.
//  Copyright © 2017年 facebac.com. All rights reserved.
//

#import "NHPaymentVerify.h"
#import "NHPayApi.h"
#import "NHOrderManage.h"

@interface NHPaymentVerify ()
@property (nonatomic, copy  ) NSString *productPrice; //产品价格
@property (nonatomic, copy  ) NSString *productID; //产品ID
@property (nonatomic, copy  ) NSString *coustomTransactionID;
@property (nonatomic, copy  ) NSString *receiptData;
@property (nonatomic, copy  ) NSString *payObjectID;//支付者ID
@property (nonatomic, strong) SKPaymentTransaction *payTransaction;
@property (nonatomic, copy  ) NHVerifyPaymentResult verifyPaymentResult;
@property (nonatomic, copy  ) NSString *customTransactionID;//蜜家：预支付订单号
@property (nonatomic, assign) BOOL isRestore;//是否为恢复购买

@end

@implementation NHPaymentVerify

+ (instancetype)createVerify {
    return [[self alloc] init];
}

- (void)verifyPaymentResultSandbox:(BOOL)sandbox
                paymentTransaction:(SKPaymentTransaction *)payTransaction
                     productsPrice:(NSString *)productsPrice
                       payObjectID:(NSString *)payObjectID
               customTransactionID:(NSString *)customTransactionID
                         isRestore:(BOOL)isRestore
                     paymentResult:(NHVerifyPaymentResult)paymentResult
{
    //从沙盒中获取交易凭证并且拼接成请求体数据
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl]; // Sent to the server by the device
    _receiptData = [receiptData base64EncodedStringWithOptions:0];
    
    _customTransactionID = customTransactionID;
    _productPrice = productsPrice;
    _payObjectID = payObjectID;
    _payTransaction = payTransaction;
    _verifyPaymentResult = paymentResult;
    _isRestore = isRestore;
    
    [self verifyPaymentResultAppleServeSandbox:sandbox];
    
//    [self saveOrderinfo];
}


- (void)verifyPaymentResultAppleServeSandbox:(BOOL)sandbox {
    __weak __typeof(self)weakself = self;
    if (_receiptData.length == 0) {
        // ... Handle error ...
        tipWithMessage(@"支付请求失败，交易结束。");
        if (weakself.verifyPaymentResult) {
            weakself.verifyPaymentResult(nil, _payTransaction, 404, _isRestore,ERROR_STATUS(404, ERROR_MSG(@"支付请求失败，交易结束。", @"", @"")));
        }
        return;
    }

    
    [NHPayApi IAPVerifyIsSandboxEnvironment:sandbox
                                 receiptStr:_receiptData
                                   complete:^(id resultObject, NSError *error)
    {
        
        if (error) {/* ... Handle error ... */
            tipWithMessage(error.localizedDescription);
            
        } else {
            static NSString  *statusKey = @"status";
            static NSInteger successCode = 0;
            static NSInteger sandboxCode = 21007;
            static NSString  *sandbox = @"Sandbox";
            static int isTestEnvironment = 1;
            
            NSString  *environment = [NSString stringWithFormat:@"%@",[resultObject objectForKey:@"environment"]];
            
            if ([environment isEqualToString:sandbox]) {
                isTestEnvironment = 1;
            }else{
                isTestEnvironment = 0;
            }
            NSInteger statusCode = [resultObject[statusKey] integerValue];
            
            if (!resultObject || error) {/* ... Handle error ...*/
                tipWithMessage(@"充值验证失败，交易结束。");
                if (weakself.verifyPaymentResult) {
                    weakself.verifyPaymentResult(resultObject, _payTransaction, -1, _isRestore, error);
                }
                
            } else {/* ... Send a response back to the device ... */
                //验证信息是否匹配
                if (statusCode == successCode && [self verifyAppReceipt:resultObject paymentTransaction:_payTransaction]) {
                    //通过自己的服务器验证
                    [weakself verifyInServeTransactionId:_payTransaction.transactionIdentifier
                                       productIdentifier:_payTransaction.payment.productIdentifier
                                                 sandbox:isTestEnvironment];
                    NHNSLog(@"\n苹果服务器验证结果状态:%@\n\n",[resultObject objectForKey:@"status"]);
                    
                } else if (statusCode == sandboxCode){
                    //验证环境反了，重新验证一次
                    [weakself verifyPaymentResultAppleServeSandbox:YES];
                    NHNSLog(@"\nverifyPurchaseInApple:\n%@",resultObject);
                    
                } else {
                    tipWithMessage(@"充值结果验证无效");
                    if (weakself.verifyPaymentResult) {
                        weakself.verifyPaymentResult(resultObject, _payTransaction, -2, _isRestore, error);
                    }
                }
            }
        }
    }];
}

//恢复充值的验证
+ (void)verifyPaymentResultWithNHOrderInfo:(NHOrderInfo *)orderInfo {
    NHPaymentVerify *pv = [[self alloc] init];
    pv.receiptData = orderInfo.receiptDataStr;
    pv.productPrice = orderInfo.proudctPrice;
    pv.payObjectID = orderInfo.payObjectID;
    pv.isRestore = YES;
    [pv verifyInServeTransactionId:orderInfo.transactionIdentifier
                 productIdentifier:orderInfo.proudctPrice
                           sandbox:1];
}

//通知app服务验证
- (void)verifyInServeTransactionId:(NSString *)transactionID
                 productIdentifier:(NSString *)productIdentifier
                           sandbox:(int)sandbox
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    __weak __typeof(self)weakself = self;
    [NHPayApi payVerifyWithReceiptData:_receiptData
                         transactionID:transactionID
                              totalFee:_productPrice
                                userID:_payObjectID
                               is_test:sandbox
                              complete:^(id responseObject, NSError *error)
     {
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
         
         NSString *errorString = [responseObject objectForKey:@"msg"];
         int errorCode = [[responseObject objectForKey:@"err"] intValue];//0为成功
         int code = [[responseObject objectForKey:@"code"] intValue];

         //通知充值结果，结束交易
         if (weakself.verifyPaymentResult) {
             weakself.verifyPaymentResult(responseObject, _payTransaction, errorCode, _isRestore,error);
         }
         //这里的验证结果你自己的服务器返回的，请根据返回字段给相应提示，这里只做提示，具体结果回调是通过上面的block
         NSLog(@"\napp服务器:%@",responseObject);
         if (!error && (errorCode == 0)) {
             //删除订单
             if (_isRestore) {
                #if DEBUG
                 dispatch_async(dispatch_get_main_queue(), ^{
                     tipWithMessage(@"恢复充值成功");
                 });
                #endif
             }
             
         } else if (errorCode == 500 && [errorString isEqualToString:@"失败"]) {
             if (_isRestore) {
                #if DEBUG
                 dispatch_async(dispatch_get_main_queue(), ^{
                     tipWithMessage([NSString stringWithFormat:@"恢复充值失败，此订单已被充值"]);
                 });
                #endif
             }
             
         } else {
             if (_isRestore) {
                #if DEBUG
                 dispatch_async(dispatch_get_main_queue(), ^{
                     tipWithMessage([NSString stringWithFormat:@"恢复充值失败 - ,%@",error.localizedDescription]);
                 });
                #endif
             }
//             [BKCustomBarHUD showMessageAndImageFailed:[NSString stringWithFormat:@"充值失败,%@",error.localizedDescription]];
         }
     }];
}



- (BOOL)verifyAppReceipt:(NSDictionary*)jsonResponse paymentTransaction:(SKPaymentTransaction *)payTransaction {
    
    NSDictionary *receipt = [jsonResponse objectForKey:@"receipt"];
    if (!receipt) return NO;

    NSString *bundle_id = [receipt objectForKey:@"bundle_id"];
    if (![bundle_id isEqualToString:NHGetBundleID]) return NO;

    
    NSArray *in_app = [receipt objectForKey:@"in_app"];
    if (in_app.count < 1) return NO;
    
    NSString *product_id = nil;
    NSString *transaction_id = nil;
    @autoreleasepool {
        for (NSDictionary *pidDict in in_app) {
            NSString *pid = [pidDict objectForKey:@"product_id"];
            NSString *tid = [pidDict objectForKey:@"original_transaction_id"];
            
            if ([pid isEqualToString:payTransaction.payment.productIdentifier]) {
                product_id = pid;
            }
            if ([tid isEqualToString:payTransaction.transactionIdentifier]) {
                transaction_id = tid;
            }
        }
    }
    
    if (![product_id isEqualToString:payTransaction.payment.productIdentifier]) return NO;
    
    if (![transaction_id isEqualToString:payTransaction.transactionIdentifier]) return NO;
    
    return YES;
}


- (void)saveOrderinfo {
    //添加正在交易的订单
    BOOL saveResult =  [NHOrderManage addTransactionIdentifier:_payTransaction.transactionIdentifier
                                                receiptDataStr:_receiptData
                                                  proudctPrice:_productPrice
                                                     proudctID:_payTransaction.payment.productIdentifier
                                                   payObjectID:_payObjectID
                                                       sandbox:0];
#if DEBUG
    if (!saveResult) {
//        [BKCustomBarHUD showMessageAndImageFailed:@"订单保存失败！"];
    }
#endif
}

@end
