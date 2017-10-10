//
//  NHIAP.m
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/6.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import "NHIAP.h"
#import "CommonCrypto/CommonDigest.h"
#import "NHLog.h"
#import "NHMacro.h"
#import "NHOrderVerify.h"


@interface NHIAP ()<SKProductsRequestDelegate,SKPaymentTransactionObserver,SKRequestDelegate>
@property (nonatomic, copy  ) NHSKProductsRequestSuccess productSuccessBlock;
@property (nonatomic, copy  ) NHStoreFailure failureBlock;
@property (nonatomic, copy  ) NHSKPaymentTransactionSuccess transactionSuccessBlock;
@property (nonatomic, copy  ) NHSKPaymentTransactionFailure transactionFailureBlock;
@property (nonatomic, copy  ) NHSKPaymentTransactionDidReceiveResponse receiveResponse;

//恢复相关
@property (nonatomic, copy  ) NHSKProductsInvalidProducts invalidProductId;
@property (nonatomic, copy  ) NHSKPaymentTransactionSuccess restoreTransactionSuccessBlock;
@property (nonatomic, copy  ) NHSKPaymentTransactionFailure restoreTransactionFailureBlock;
@property (nonatomic, copy  ) NHRestoreTransactions restoreTransactionsBlock;
@property (nonatomic, copy  ) NSArray<SKPaymentTransaction *> *restoreTransactions;

@property (nonatomic, copy  ) NSArray <SKProduct *> *effectiveProductsIdentifier; //store查询到的所有有效商品
@property (nonatomic, copy  ) NSArray <NSString *> *invalidProductsIdentifier; //store查询到的无效产品ID
@property (nonatomic, copy  ) NSString *currentProductIdentifier; //当前的产品ID
@property (nonatomic, copy  ) NSArray *productIdentifiers; //产品id
@property (nonatomic, copy  ) NSString *consumerIdentifier; //支付者id
@property (nonatomic, strong) NSMutableDictionary *effectiveProducts; //键：store查询的有效具体产品, key：产品ID
@property (nonatomic, assign) BOOL isRestore;
//@property (nonatomic, copy  ) NSMutableArray *currentRestoreTransactions;
@end

@implementation NHIAP
NSSingletonM(NHIAP)

//- (NSMutableArray *)currentRestoreTransactions {
//
//    if (!_currentRestoreTransactions) {
//        _currentRestoreTransactions = [NSMutableArray alloc];
//    }
//    return _currentRestoreTransactions;
//}

- (NSArray<NHOrderInfo *> *)checkAllUnfinishedOrderIsFromBackground:(BOOL)background{

    _isRestore = YES;

    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];

    self.restoreTransactions = [SKPaymentQueue defaultQueue].transactions;
    
    NSArray *array = [SKPaymentQueue defaultQueue].transactions.mutableCopy;
    NHLog(@"checkAllUnfinishedOrderIsFromBackground:\n%@",array);
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

    return [NHOrderManage checkHistyUnfinishedOrder];
}


//从apple查询可供销售购买产品的信息
+ (instancetype)requestProducts:(NSArray *)proudctIDs
                        success:(NHSKProductsRequestSuccess)successBlock
               invalidProductId:(NHSKProductsInvalidProducts)invalidProductId
                        failure:(NHStoreFailure)failureBlock {
    
    return [[NHIAP sharedNHIAP] requestProducts:proudctIDs
                                        success:successBlock
                               invalidProductId:invalidProductId
                                        failure:failureBlock];
}


- (instancetype)requestProducts:(NSArray *)proudctIDS
                        success:(NHSKProductsRequestSuccess)successBlock
               invalidProductId:(NHSKProductsInvalidProducts)invalidProductId
                        failure:(NHStoreFailure)failureBlock {
    
    
    if (_effectiveProducts.count <= 0) {
        _isRequestProudct = YES;
    } else {
        nh_safe_block(successBlock, _effectiveProducts.copy);
        return self;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    self.productSuccessBlock = successBlock;
    self.failureBlock = failureBlock;
    self.productIdentifiers = proudctIDS;
    self.invalidProductId = invalidProductId;
    
    NSSet *productSet = [NSSet setWithArray:proudctIDS];
    SKProductsRequest *productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productSet];
    productRequest.delegate = self;
    [productRequest start];
    
    return self;
}


+ (instancetype)addPayment:(NSString *)productIdentifier
                consumerId:(NSString *)consumerIdentifier
                   success:(NHSKPaymentTransactionSuccess)successBlock
                   failure:(NHSKPaymentTransactionFailure)failureBlock {
    
    return [[NHIAP sharedNHIAP] addPayment:productIdentifier
                                consumerId:consumerIdentifier
                                   success:successBlock
                                   failure:failureBlock];
}

- (instancetype)addPayment:(NSString *)productIdentifier
                consumerId:(NSString *)consumerIdentifier
                   success:(NHSKPaymentTransactionSuccess)successBlock
                   failure:(NHSKPaymentTransactionFailure)failureBlock {
    
    self.transactionSuccessBlock = successBlock;
    self.transactionFailureBlock = failureBlock;
    
    if (_effectiveProducts.count <= 0 && !_isRequestProudct) {
//        NHIAPTipWithMessage(@"暂无可售卖商品");
        nh_safe_block(failureBlock, nil, NHEorrorinfo(404, @"暂无可售卖商品", nil, nil));
        return self;
    }
    
    if (_effectiveProducts.count <= 0 && _isRequestProudct) {
//        NHIAPTipWithMessage(@"正在更新商品信息...");
        nh_safe_block(failureBlock, nil, NHEorrorinfo(404, @"正在更新商品信息...", nil, nil));
        return self;
    }
    
    if (![SKPaymentQueue canMakePayments]) {
//        NHIAPTipWithMessage(@"您的手机没有打开程序内付费功能");
        nh_safe_block(failureBlock, nil, NHEorrorinfo(404, @"您的手机没有打开程序内付费功能", nil, nil));
        return self;
    }
    
    //发送购买请求
    _currentProductIdentifier = productIdentifier;
    _currentProduct = [_effectiveProducts objectForKey:productIdentifier];
    _consumerIdentifier = consumerIdentifier;
    
    
    if (_currentProduct == nil) {
        NHWEFLog(@"产品id不能为空");
        return self;
    }
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    SKMutablePayment *payment= [SKMutablePayment paymentWithProduct:_currentProduct];
    //设置用户别名，防止充错用户，可以用userID+版本号做标记
    payment.applicationUsername = [NSString stringWithFormat:@"%@:%lld",consumerIdentifier,[NHOrderManage getDateTimeTOMilliSeconds:nil]];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
//    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    return self;
}


/**
 恢复订单的相关信息
 */
+ (void)restoreTransaction:(NHRestoreTransactions)transactions
                   success:(NHSKPaymentTransactionSuccess)successBlock
                   failure:(NHSKPaymentTransactionFailure)failureBlock {
    return [[NHIAP sharedNHIAP] restoreTransaction:transactions success:successBlock failure:failureBlock];
}

- (void)restoreTransaction:(NHRestoreTransactions)transactions
                   success:(NHSKPaymentTransactionSuccess)successBlock
                   failure:(NHSKPaymentTransactionFailure)failureBlock {
    
    self.restoreTransactionFailureBlock = failureBlock;
    self.restoreTransactionSuccessBlock = successBlock;
    self.restoreTransactionsBlock = transactions;
    [self checkAllUnfinishedOrderIsFromBackground:YES];
}

#pragma mark - SKRequestDelegate
#pragma mark -
- (void)requestDidFinish:(SKRequest *)request {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    nh_safe_block(_productSuccessBlock, [_effectiveProducts allValues])
}


- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    _isRequestProudct = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NHWEFLog(@"请求产品信息失败:%@",error.localizedDescription);
    
    NHIAPDEBUGTipWithMessage(error.localizedDescription);

    nh_safe_block(_failureBlock, error);
}


#pragma mark - SKProductsRequestDelegate
#pragma mark -
//查询成功后的回调（收到产品返回信息）
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    _isRequestProudct = NO;

    NSArray *effectiveProducts = response.products;
    
    _invalidProductsIdentifier = response.invalidProductIdentifiers;
    
    nh_safe_block(_invalidProductId, _invalidProductsIdentifier)
    
    if (_invalidProductsIdentifier.count > 0) {
        NSString *sting = [NSString stringWithFormat:@"无效的商品:%@",response.invalidProductIdentifiers];
        NHIAPDEBUGTipWithMessage(sting);
    }
    
    if (effectiveProducts.count == 0) {//无法获取产品信
        NHIAPDEBUGTipWithMessage(@"暂无可售卖商品");
        return;
    }
    
    for(SKProduct *product in effectiveProducts){
        [self printfProductinfos:product];
        //保存有效商品，在下一次购买的时候不需要重新请求
        [self.effectiveProducts setObject:product forKey:product.productIdentifier];
    }
}


#pragma mark - SKPaymentTransactionObserver
//购买操作后的回调
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *paymentTransaction in transactions) {
            NHLog(@"payTransaction = %@",paymentTransaction.transactionIdentifier);
        
        switch (paymentTransaction.transactionState) {
            case SKPaymentTransactionStatePurchased: //支付完成
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                nh_safe_block(_statePurchased, paymentTransaction);
                [self compaleteTransaction:paymentTransaction];
                break;
                
            case SKPaymentTransactionStateFailed:  //支付失败
                [self failedTransaction:paymentTransaction];
                break;
                
            case SKPaymentTransactionStateRestored:  //已经购买过该商品
                //恢复购买
                [self resroreTransaction:paymentTransaction];
                break;
                
            case SKPaymentTransactionStatePurchasing: //商品添加进列表
            {
                //添加正在请求付费信息
                _isRestore = NO;
                for (SKPaymentTransaction *pt in _restoreTransactions) {
                    if ([pt.payment.productIdentifier isEqualToString:paymentTransaction.payment.productIdentifier]) {
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        if (pt.transactionState == 1 || pt.transactionState == 3) {
                            _isRestore = YES;
                            [self verifyPurchaseWithPaymentTransaction:pt isRestore:YES];
                            nh_safe_block(_statePurchasing, pt);
                        }
                    }
                }
                
                NHLog(@"\n请求付费信息:\n订单号:%@",paymentTransaction.transactionIdentifier);
            }
                break;
                case SKPaymentTransactionStateDeferred:
                    NHLog(@"\n订单挂起:\n订单号:%@",paymentTransaction.transactionIdentifier);
                    break;

            default:
                break;
        }
    }
}

//恢复已购买商品
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    
    self.restoreTransactions = [SKPaymentQueue defaultQueue].transactions;

    for (SKPaymentTransaction *paymentTransaction in queue.transactions) {
        NHLog(@"%ld  --  %@",queue.transactions.count,paymentTransaction.transactionIdentifier);
        if (paymentTransaction.transactionIdentifier) {
            [self resroreTransaction:paymentTransaction];
        } else {
            [self finishTransaction:paymentTransaction];
        }
    }
}

//删除完成的交易
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    NHLog(@"removedTransactions:%ld",transactions.count);
}

//恢复操作后的回调
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSString *errorString = queue.transactions.firstObject.transactionIdentifier;
    NHWEFLog(@"恢复购买错误：%@",errorString,error.localizedDescription);
    NHIAPDEBUGTipWithMessage(errorString);
    nh_safe_block(_restoreTransactionFailureBlock,queue.transactions.firstObject, error);
}

//当下载状态更改时发送。
- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray<SKDownload *> *)downloads{
    NHLog(@"%@",queue.transactions.firstObject.transactionIdentifier);
}


#pragma mark - private method
#pragma mark -
/**
 交易完成调用
 */
- (void)compaleteTransaction:(SKPaymentTransaction *)paymentTransaction {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NHLog(@"支付完成订单号: %@",paymentTransaction.transactionIdentifier);
    NSString * productIdentifier = paymentTransaction.transactionIdentifier;

    if (productIdentifier) {
        [self verifyPurchaseWithPaymentTransaction:paymentTransaction isRestore:_isRestore];
    }
}


/**
 恢复已购买商品
 */
- (void)resroreTransaction:(SKPaymentTransaction *)paymentTransaction {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    NHIAPDEBUGTipWithMessage(@"恢复已购买商品");

    NHLog(@"恢复已购买商品:%@",paymentTransaction.transactionIdentifier);
    [self verifyPurchaseWithPaymentTransaction:paymentTransaction isRestore:YES];
}


/**
 关闭完成的订单
 */
- (void)finishTransaction:(SKPaymentTransaction *)paymentTransaction {
    if (paymentTransaction.transactionIdentifier) {
        [[SKPaymentQueue defaultQueue] finishTransaction:paymentTransaction];
    }
    
    [self performSelector:@selector(removeArrary) withObject:nil afterDelay:1];
//
//    @synchronized (self) {
//        NSMutableArray *tempArr = [[NSMutableArray alloc] initWithArray:_restoreTransactions];
//        for (SKPaymentTransaction *pt in tempArr) {
//            if ([pt.payment.productIdentifier isEqualToString:paymentTransaction.payment.productIdentifier]) {
//                [tempArr removeObject:pt];
//            }
//            _restoreTransactions = tempArr.copy;
//        }
//    }
}

- (void)removeArrary {
    _restoreTransactions = [SKPaymentQueue defaultQueue].transactions.copy;
}


/**
 移除监听
 */
- (void)removeTransactionObserver {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    _currentProduct = nil;
}


/**
 交易失败后调用
 */
- (void)failedTransaction:(SKPaymentTransaction *)paymentTransaction {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    //交易结束了，可以删除正在支付的订单
    [self finishTransaction:paymentTransaction];
    
    NHWEFLog(@"交易失败:%@",paymentTransaction.error.localizedDescription);
    
    NSString *errString;
    switch (paymentTransaction.error.code) {
        case SKErrorUnknown:
            errString = paymentTransaction.error.localizedDescription;
            break;
            
        case SKErrorClientInvalid:
            errString = @"当前appleID无法购买商品!";
            break;
            
        case SKErrorPaymentCancelled:
            errString = @"用户主动取消支付";
            break;
            
        case SKErrorPaymentInvalid:
            errString = @"订单无效!";
            break;
            
        case SKErrorPaymentNotAllowed:
            errString = @"无法购买商品，当前设备不允许付款";
            break;
            
        case SKErrorStoreProductNotAvailable:
            errString = @"此产品在当前店面中不可用";
            break;
            
#ifdef NSFoundationVersionNumber_iOS_9_3
        case SKErrorCloudServicePermissionDenied:
            errString = @"当前appleID不允许访问apple云服务通知";
            break;
            
        case SKErrorCloudServiceNetworkConnectionFailed:
            errString = @"当前设备无法连接到网络！";
            break;
#endif
        default:
            errString = nil;
            break;
    }
    
    nh_safe_block(_transactionFailureBlock, paymentTransaction, NHEorrorinfo(paymentTransaction.error.code, errString, nil, nil))
 
    if (errString) {
//        tipWithMessage(errString);
    }
}



/**
 服务器验证

 @param paymentTransaction 当前交易对象
 @param isRestore 是否为恢复购买
 */
-(void)verifyPurchaseWithPaymentTransaction:(SKPaymentTransaction *)paymentTransaction isRestore:(BOOL)isRestore {
    NHLog(@"\n\n订单号：%@----isRestore:%d",paymentTransaction.transactionIdentifier,_isRestore);
    
    //同步订单，防止恢复订单的时候不消失提示框
    self.restoreTransactions = [SKPaymentQueue defaultQueue].transactions;
//    [self.currentRestoreTransactions addObject:paymentTransaction];
    
    if (_onPurchasedAutoVerify) {
        __weak __typeof(self)weakself = self;
        
        [NHOrderVerify orderVerifyPaymentTransaction:paymentTransaction success:^(SKPaymentTransaction *payTransaction, id result, BOOL sandbox) {

            if (weakself.isRestore) {
                nh_safe_block(weakself.restoreTransactionSuccessBlock, paymentTransaction, sandbox);
            } else {
                nh_safe_block(weakself.transactionSuccessBlock, paymentTransaction, sandbox);
            }
            
        } failure:^(SKPaymentTransaction *payTransaction, NSError *error) {

            if (weakself.isRestore) {
                nh_safe_block(weakself.restoreTransactionFailureBlock, paymentTransaction, error);
            } else {
                nh_safe_block(weakself.transactionFailureBlock, paymentTransaction, error);
            }
            
            if (error.code == NHVerifyStatusReceiptError) {
                [weakself finishTransaction:payTransaction];
            }
        }];
        
    } else {

        BOOL sandbox = [NHOrderVerify environmentEqualToSandbox:paymentTransaction];
        if (self.isRestore) {
            nh_safe_block(self.restoreTransactionSuccessBlock, paymentTransaction, sandbox);
        } else {
            nh_safe_block(self.transactionSuccessBlock, paymentTransaction, sandbox);
        }
    }
}

//打印产品信息
- (void)printfProductinfos:(SKProduct *)product {
    if ([NHLog logEnable]) {
        NHCLog(@"<<<<<<<<<<<product info>>>>>>>>>>");
        NHCLog(@"SKProduct 描述信息: %@", [product description]);
        NHCLog(@"产品标题: %@" , product.localizedTitle);
        NHCLog(@"产品描述信息: %@" , product.localizedDescription);
        NHCLog(@"价格: %@" , product.price);
        NHCLog(@"Product id: %@\n\n" , product.productIdentifier);
    }
}


#pragma mark - setting/getting
#pragma mark -
- (NSMutableDictionary *)effectiveProducts{
    if (!_effectiveProducts) {
        _effectiveProducts = [[NSMutableDictionary alloc] init];
    }
    return _effectiveProducts;
}

+ (void)setLogEnable:(BOOL)flag {
    [NHLog setLogEnable:flag];
}

+ (void)setLogEnable_W_E_F:(BOOL)flag {
    [NHLog setLogEnable_W_E_F:flag];
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
