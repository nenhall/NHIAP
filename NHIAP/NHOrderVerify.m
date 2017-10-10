//
//  NHOrderVerify.m
//  NHIAPDemo
//
//  Created by neghao on 2017/9/26.
//  Copyright © 2017年 neghao. All rights reserved.
//

#import "NHOrderVerify.h"
#import "NHMacro.h"
#import "NHPayApi.h"
#import "NHPayApi.h"
#import "NHLog.h"

@interface NHOrderVerify ()
@property (nonatomic, copy  ) NSString *productPrice; //产品价格
@property (nonatomic, copy  ) NSString *productID; //产品ID
@property (nonatomic, copy  ) NSString *coustomTransactionID;
@property (nonatomic, copy  ) NSString *receiptData;
@property (nonatomic, copy  ) NSString *payObjectID;//支付者ID
@property (nonatomic, strong) SKPaymentTransaction *payTransaction;
@property (nonatomic, copy  ) NHVerifyPaymentFailure verifyPaymentFailure;
@property (nonatomic, copy  ) NHVerifyPaymentSuccess verifyPaymentSuccess;

@property (nonatomic, copy  ) NSString *customTransactionID;//蜜家：预支付订单号
@property (nonatomic, assign) BOOL isRestore;//是否为恢复购买
@end


@implementation NHOrderVerify


+ (void)orderVerifyPaymentTransaction:(SKPaymentTransaction *)payTransaction
                              success:(NHVerifyPaymentSuccess)success
                              failure:(NHVerifyPaymentFailure)failure {
    
    NHOrderVerify *orderVerify = [[NHOrderVerify alloc] init];
    orderVerify.verifyPaymentFailure = failure;
    orderVerify.verifyPaymentSuccess = success;
    orderVerify.payTransaction = payTransaction;
    
    //从沙盒中获取交易凭证并且拼接成请求体数据
    // Sent to the server by the device
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
    orderVerify.receiptData = [receiptData base64EncodedStringWithOptions:0];
    
    [orderVerify verifyPaymentResultAppleServeSandbox:[NHOrderVerify environmentEqualToSandbox:payTransaction]];
}



- (void)verifyPaymentResultAppleServeSandbox:(BOOL)sandbox {
    __weak __typeof(self)weakself = self;
    if (_receiptData.length == 0) {
        // ... Handle error ...
        NHIAPTipWithMessage(@"支付请求失败，交易结束。");
        nh_safe_block(_verifyPaymentFailure, _payTransaction,NHEorrorinfo(NHVerifyStatusReceiptError, @"支付请求失败，交易结束。", nil, nil));
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    [NHPayApi IAPVerifyIsSandboxEnvironment:sandbox
                                 receiptStr:_receiptData
                                   complete:^(id resultObject, NSError *error)
     {
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

         if (error) {/* ... Handle error ... */
             NHIAPTipWithMessage(error.localizedDescription);
             nh_safe_block(weakself.verifyPaymentFailure, _payTransaction,error);
             
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
                 NHIAPTipWithMessage(@"充值验证失败，交易结束。");
                 nh_safe_block(weakself.verifyPaymentFailure, _payTransaction,error);

             } else {/* ... Send a response back to the device ... */
                 //验证信息是否匹配
                 BOOL transactionCompare = [self verifyAppReceipt:resultObject paymentTransaction:_payTransaction];
                 NHLog(@"\nverifyPurchaseInApple:\n%@",resultObject);
                 NHLog(@"\n苹果服务器验证结果状态:%@\n\n",[resultObject objectForKey:@"status"]);

                 if (statusCode == sandboxCode){
                     //验证环境反了，重新验证一次
                     [weakself verifyPaymentResultAppleServeSandbox:YES];
                     return;
                 }
                 
                 if (statusCode == successCode) {
                     if (transactionCompare) {
                         nh_safe_block(weakself.verifyPaymentSuccess, _payTransaction, resultObject, isTestEnvironment);
                     } else {
                         NSString *errorinfo = @"receipt验证的结果与payTransaction的不一致";
                         nh_safe_block(weakself.verifyPaymentFailure, _payTransaction,NHEorrorinfo(NHVerifyStatusReceiptTransactionMismatching, errorinfo, nil, nil));
                     }
                     
                 } else {
                     NHIAPTipWithMessage(@"充值结果验证无效");
                     nh_safe_block(weakself.verifyPaymentFailure, _payTransaction,error);
                 }
             }
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

+ (BOOL)environmentEqualToSandbox:(SKPaymentTransaction *)payTransaction {
    
    NSString * transactionReceipt = [[NSString alloc] initWithData:payTransaction.transactionReceipt encoding:NSUTF8StringEncoding];
    NSString *environmentStr = [NHOrderVerify environmentForReceipt:transactionReceipt];
    BOOL environment = [environmentStr isEqualToString:@"environment=Sandbox"];
    
    return environment;
}

+ (NSString * )environmentForReceipt:(NSString * )str
{
    str= [str stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    str = [str stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    
    str=[str stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    str=[str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    
    NSArray * arr=[str componentsSeparatedByString:@";"];
    
    //存储收据环境的变量
    if (arr.count < 2) {
        return @"inproduct";
    }
    NSString * environment=arr[2];
    return environment;
}

// JSON编码
- (NSString *)encode:(const uint8_t *)input length:(NSInteger)length
{
    NSLog(@"JSON64编码");
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData *data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *output = (uint8_t *)data.mutableBytes;
    
    for (NSInteger i = 0; i < length; i += 3) {
        
        NSInteger value = 0;
        
        for (NSInteger j = i; j < (i + 3); j++) {
            
            value <<= 8;
            
            if (j < length) {
                
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    table[(value >> 18) & 0x3F];
        output[index + 1] =                    table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
        
    }
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    // return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

@end
