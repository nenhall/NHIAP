//
//  NHIAP.h
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/6.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "NHPayApi.h"
#import "NHOrderManage.h"
#import "NHOrderManage.h"
#import "NHMacro.h"
#import "NHLog.h"

/** 失败的信息 */
typedef void (^_Nullable NHStoreFailure)(NSError * _Nullable error);

/** 请求到的有效商品 */
typedef void (^_Nullable NHSKProductsRequestSuccess)(NSArray <SKProduct *> *_Nullable products);

/** 请求到的无效商品 */
typedef void (^_Nullable NHSKProductsInvalidProducts)(NSArray <NSString *> *_Nullable invalidProductsIdentifier);

/** note */
typedef void (^_Nullable NHSKPaymentTransactionDidReceiveResponse)(SKProductsResponse *_Nullable response);

/** 交易成功的回调 
 * transaction：成功的订单类
 * 开发者在处理时需要判定用户的一致性
 */
typedef void (^_Nullable NHSKPaymentTransactionSuccess)(SKPaymentTransaction *_Nullable payTransaction, BOOL environmentSandbox);

/** 交易失败的回调 transaction：成功的订单类*/
typedef void (^_Nullable NHSKPaymentTransactionFailure)(SKPaymentTransaction *_Nullable payTransaction, NSError *_Nullable error);

/** 恢复充值的订单 
 *  已在苹果端验证成功的订单才会记为恢复的订单，开发者在处理时需要判定用户的一致性
 */
typedef void (^NHRestoreTransactions)(NSArray <SKProduct *> *_Nullable products);

typedef void (^_Nullable NHPaymentTransactionStatePurchasing)(SKPaymentTransaction *_Nullable payTransaction);

typedef void (^_Nullable NHaymentTransactionStatePurchased)(SKPaymentTransaction *_Nonnull payTransaction);


@protocol NHIAPDelegate <NSObject>


@end


@interface NHIAP : NSObject

@property (nonatomic, assign)id<NHIAPDelegate > _Nullable delegate;

//是否正在请求商品信息
@property (nonatomic, assign) BOOL isRequestProudct;
@property (nonatomic, assign) BOOL onPurchasedAutoVerify;

/**
 *  当前请求/正在购买的产品
 */
@property (nonatomic, strong, readonly) SKProduct *_Nullable currentProduct;
@property (nonatomic, strong, readonly) NHOrderInfo *_Nullable orderinfo;
@property (nonatomic, copy) NHPaymentTransactionStatePurchasing statePurchasing;
@property (nonatomic, copy) NHaymentTransactionStatePurchased statePurchased;


NS_ASSUME_NONNULL_BEGIN

NSSingletonH(NHIAP)
/**
 *  从苹果服务器请求可出售的产品
 *
 *  @param proudctIDS  商品的identifier
 */
+ (_Nonnull instancetype)requestProducts:(NSArray *_Nonnull)proudctIDS
                                 success:(NHSKProductsRequestSuccess)successBlock
                        invalidProductId:(NHSKProductsInvalidProducts)invalidProductId
                                 failure:(NHStoreFailure)failureBlock;


/**
 添加需要购买的产品

 @param productIdentifier 商品identifier
 @param consumerIdentifier 用户identifier，会在paymentTransaction.payment.applicationUsername返回，可用于判定是否用户的一致性
 @param successBlock 交易成功
 @param failureBlock 交易失败
 */

+ (instancetype)addPayment:(NSString *_Nonnull)productIdentifier
                consumerId:(NSString *_Nonnull)consumerIdentifier
                   success:(NHSKPaymentTransactionSuccess)successBlock
                   failure:(NHSKPaymentTransactionFailure)failureBlock;


/**
 检查未完成的订单，如果有多单，会调用多次

 @param transactions 所有待恢复(处理)的订单
 @param successBlock 验证成功的
 @param failureBlock 验证失败的
 */
+ (void)restoreTransaction:(NHRestoreTransactions)transactions
                   success:(NHSKPaymentTransactionSuccess)successBlock
                   failure:(NHSKPaymentTransactionFailure)failureBlock;

/**
 关闭完成的订单
 */
- (void)finishTransaction:(SKPaymentTransaction *)paymentTransaction;


/**
 *  移除监听 */
- (void)removeTransactionObserver;


/**
 Log 输出开关(默认允许所有打印)
 */
+ (void)setLogEnable:(BOOL)flag;

/**
 Log 输出开关，只允许Warn、Error、Fatal级别的日志打印 (默认开启)
 优先级高于：`setLogEnable:` setLogEnable_W_E_F为yes，Warn、Error、Fatal级别的日志不受`setLogEnable:`影响
 */
+ (void)setLogEnable_W_E_F:(BOOL)flag;



@end
NS_ASSUME_NONNULL_END

