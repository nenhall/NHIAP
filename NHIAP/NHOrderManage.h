//
//  NHOrderManage.h
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/9.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NHMacro.h"

@interface NHOrderInfo : NSObject
@property (nonatomic, copy, readonly) NSString *transactionIdentifier; //订单号
@property (nonatomic, copy, readonly) NSString *consumerIdentifier; //支付者id
@property (nonatomic, copy, readonly) NSString *payTimeStamp; //支付时间(这里以时间戳格式保存)
@property (nonatomic, copy, readonly) NSString *productIdentifier; //产品ID

@end


@interface NHOrderManage : NSObject

/**
 *  添加订单信息
 *
 *  @param transactionIdentifier apple返回的订单号
 *  @param productIdentifier     商品id
 *  @param consumerIdentifier    充值用户DI(根据自己的项目需要来定)，这里只为保存订单信息时用到
 *
 */

+ (BOOL)addTransactionPayTimeStamp:(NSString *)transactionIdentifier
                 productIdentifier:(NSString *)productIdentifier
                consumerIdentifier:(NSString *)consumerIdentifier;

/**
 通过订单号删除相应的订单信息
 @param transactionIdentifier apple返回的订单号
 */
+ (BOOL)deleteTransactionIdentifier:(NSString *)transactionIdentifier;


/**
 检查未完成的订单

 */
+ (NSArray<NHOrderInfo *> *)checkHistyUnfinishedOrder;


/**
 通过订单号获取订单信息
 @param transactionIdentifier apple返回的订单号
 */
+ (NHOrderInfo *)getOrderInfoPayTimeStamp:(NSString *)transactionIdentifier;

/**
 时间戳
 */
+ (long long)getDateTimeTOMilliSeconds:(NSDate *)datetime;
@end



