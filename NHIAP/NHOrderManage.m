//
//  NHOrderManage.m
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/9.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import "NHOrderManage.h"
#import <CommonCrypto/CommonDigest.h>
#import <StoreKit/StoreKit.h>
#import "NHPayApi.h"
#import "NHLog.h"

//获取沙盒 Library
#define NHPathLibrary   [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject]
#define TranscationInfo @"noitcasnartinfo.db"

NSString * const NHCacheFolderName = @"om";

static NSString * libraryFolder() {
    NSFileManager *filemgr = [NSFileManager defaultManager];
    static NSString *cacheFolder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!cacheFolder) {
            NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES).firstObject;
            cacheFolder = [cacheDir stringByAppendingPathComponent:NHCacheFolderName];
        }
        NSError *error = nil;
        if(![filemgr createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            //            NHNSLog(@"Failed to create cache directory at %@", cacheFolder);
            printf("Failed to create cache directory at %p", cacheFolder);
            cacheFolder = nil;
        }
    });
    return cacheFolder;
}


static NSString * LocalOrderCachePath(NSString *fileName, BOOL suffix){
    NSString *name = fileName;
    if (suffix) {
        name = [NSString stringWithFormat:@"%@.db",fileName];
    }
    return [libraryFolder() stringByAppendingPathComponent:name];
}

static NSString * getMD5String(NSString *str) {
    
    if (str == nil) return nil;
    
    const char *cstring = str.UTF8String;
    unsigned char bytes[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstring, (CC_LONG)strlen(cstring), bytes);
    
    NSMutableString *md5String = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", bytes[i]];
    }
    return md5String;
}

@interface NHOrderInfo ()<NSCoding>
@property (nonatomic, copy) NSString *transactionIdentifier; //订单号
@property (nonatomic, copy) NSString *consumerIdentifier; //支付者id
@property (nonatomic, copy) NSString *productIdentifier; //产品ID
@property (nonatomic, copy) NSString *PayTimeStamp;
@end


@implementation NHOrderInfo

#define TransactionIdentifier @"transactionIdentifier"
#define PayObjectID           @"consumerIdentifier"
#define ProudctID             @"proudctID"
#define PayTimeStamp          @"PayTimeStamp"

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_transactionIdentifier forKey:getMD5String(TransactionIdentifier)];
    [aCoder encodeObject:_productIdentifier forKey:getMD5String(ProudctID)];
    [aCoder encodeObject:_consumerIdentifier forKey:getMD5String(PayObjectID)];
    [aCoder encodeObject:_payTimeStamp forKey:getMD5String([NSString stringWithFormat:@"%@",PayTimeStamp])];
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.consumerIdentifier    = [coder decodeObjectForKey:getMD5String(PayObjectID)];
        self.productIdentifier     = [coder decodeObjectForKey:getMD5String(ProudctID)];
        self.transactionIdentifier = [coder decodeObjectForKey:getMD5String(TransactionIdentifier)];
        self.payTimeStamp = [coder decodeObjectForKey:getMD5String([NSString stringWithFormat:@"%@",PayTimeStamp])];
    }
    return self;
}

@end



@interface NHOrderManage ()
@end

@implementation NHOrderManage

/**
+ (void)addPayingProductID:(NSString *)productID
               payObjectID:(NSString *)payObjectID
              proudctPrice:(NSString *)proudctPrice {
    NHOrderInfo *orderinfo = [[NHOrderInfo alloc] init];
    orderinfo.transactionIdentifier = productID;
    orderinfo.receiptDataStr = @"";
    orderinfo.proudctPrice = proudctPrice;
    orderinfo.payObjectID = payObjectID;
    orderinfo.payTimeStamp = [self getCurrentDateBaseStyleWithData:nil];
    
    [self saveOrderInfo:orderinfo fileName:payObjectID];
}


+ (void)deletePayingProductID:(NSString *)productID {
    [self deleteTransactionIdentifier:productID];
}
*/

+ (BOOL)saveOrderInfo:(NHOrderInfo *)orderinfo fileName:(NSString *)fileName{
    return [NSKeyedArchiver archiveRootObject:orderinfo toFile:LocalOrderCachePath(fileName,YES)];
}

+ (BOOL)addTransactionPayTimeStamp:(NSString *)payTimeStamp
               productIdentifier:(NSString *)productIdentifier
              consumerIdentifier:(NSString *)consumerIdentifier {
    
    if (payTimeStamp && consumerIdentifier) {
        NHOrderInfo *orderinfo = [[NHOrderInfo alloc] init];
        orderinfo.consumerIdentifier = consumerIdentifier;
        orderinfo.payTimeStamp = payTimeStamp;
        orderinfo.productIdentifier = productIdentifier;
        NSLog(@"保存订单:\n%@,\n%@,\n%@",orderinfo.transactionIdentifier,orderinfo.productIdentifier,orderinfo.consumerIdentifier);
        
        return [self saveOrderInfo:orderinfo fileName:payTimeStamp];
    }
    return NO;
}

+ (BOOL)deleteTransactionIdentifier:(NSString *)transactionIdentifier {
    NHOrderInfo *orderinfo = [NSKeyedUnarchiver unarchiveObjectWithFile:LocalOrderCachePath(transactionIdentifier,YES)];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDircetory;
    BOOL isExists = [fileManager fileExistsAtPath:LocalOrderCachePath(transactionIdentifier,YES) isDirectory:&isDircetory];
    if (isExists) {
        NSError *error;
        [fileManager removeItemAtPath:LocalOrderCachePath(transactionIdentifier,YES) error:&error];
        NHLog(@"删除订单：\n%@,\n%@,\n%@",orderinfo.transactionIdentifier,orderinfo.payTimeStamp,orderinfo.productIdentifier);
        if (error) {
            NSLog(@"\n订单删除失败:%@",error.localizedDescription);
        }
    }
    return isExists;
}

+ (NHOrderInfo *)checkUnderwayingUnfinishedOrder:(NSString *)productID {
    NHOrderInfo *orderinfo;
    for (NSString *name in [self getFiles]) {
        NHLog(@"checkUnderwayingOrder: %@",name);
        if ([name hasPrefix:productID]) {
            orderinfo = [NSKeyedUnarchiver unarchiveObjectWithFile:LocalOrderCachePath(name,NO)];
        }
    }
    return orderinfo;
}



+ (NSArray<NHOrderInfo *> *)checkHistyUnfinishedOrder{
    NSError *error;
    NSString *filePath = libraryFolder();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager subpathsOfDirectoryAtPath:filePath error:&error];
    NSMutableArray *orders = [[NSMutableArray alloc] init];
    for (NSString *name in files) {
        @autoreleasepool {
            __block NHOrderInfo *orderinfo = [NSKeyedUnarchiver unarchiveObjectWithFile:LocalOrderCachePath(name,NO)];
            //说明是还未完成支付的订单
//            if (orderinfo.receiptDataStr.length < 2) continue;
            
            [orders addObject:orderinfo];
//            NHLog(@"检查订单:\n%@,\n%lu,\n%@,\n%@,\n%@",orderinfo.transactionIdentifier,orderinfo.receiptDataStr.length,
//                  orderinfo.proudctPrice,orderinfo.payObjectID,orderinfo.payTimeStamp);
            
            //通知服务器验证
//            [NHPaymentVerify verifyPaymentResultWithNHOrderInfo:orderinfo];
            

        }
    }
    return orders;
}


+ (NSArray *)getFiles {
    NSError *error;
    NSString *filePath = libraryFolder();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager subpathsOfDirectoryAtPath:filePath error:&error];
    return files;
}

+ (NHOrderInfo *)getOrderInfoPayTimeStamp:(NSString *)payTimeStamp {
    NHOrderInfo *orderinfo = [NSKeyedUnarchiver unarchiveObjectWithFile:LocalOrderCachePath(payTimeStamp,YES)];
    return orderinfo;
}

+ (long long)getDateTimeTOMilliSeconds:(NSDate *)datetime
{
    NSTimeInterval interval;
    if (!datetime) {
        interval = [[NSDate date] timeIntervalSince1970];
    }else {
        interval = [datetime timeIntervalSince1970];
    }
    
    long long totalMilliseconds = interval*1000;
    
    return totalMilliseconds;
}

@end
