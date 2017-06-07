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
#import "NHPaymentVerify.h"


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
@property (nonatomic, copy) NSString *receiptDataStr; //apple返回的receiptData数据
@property (nonatomic, copy) NSString *transactionIdentifier; //订单号
@property (nonatomic, copy) NSString *proudctPrice; //产品价格
@property (nonatomic, copy) NSString *payObjectID; //支付者id
@property (nonatomic, copy) NSString *payTimeStamp; //支付时间(这里以时间戳格式保存)
@property (nonatomic, copy) NSString *proudctID; //产品ID
@property (nonatomic, copy) NSNumber *sandbox; //交易环境(1为沙盒 0线上)
@end


@implementation NHOrderInfo

#define ReceiptData           @"receiptDataStr"
#define TransactionIdentifier @"transactionIdentifier"
#define ProudctPrice          @"proudctPrice"
#define PayObjectID           @"payObjectID"
#define PayTimeStamp          @"payTimeStamp"
#define ProudctID             @"proudctID"
#define Sandbox               @"sandbox"

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_receiptDataStr forKey:getMD5String(ReceiptData)];
    [aCoder encodeObject:_transactionIdentifier forKey:getMD5String(TransactionIdentifier)];
    [aCoder encodeObject:_proudctPrice forKey:getMD5String(ProudctPrice)];
    [aCoder encodeObject:_proudctID forKey:getMD5String(ProudctID)];
    [aCoder encodeObject:_sandbox forKey:getMD5String(Sandbox)];
    [aCoder encodeObject:_payObjectID forKey:getMD5String(PayObjectID)];
    [aCoder encodeObject:_payTimeStamp forKey:getMD5String([NSString stringWithFormat:@"%@",PayTimeStamp])];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.receiptDataStr        = [coder decodeObjectForKey:getMD5String(ReceiptData)];
        self.proudctPrice          = [coder decodeObjectForKey:getMD5String(ProudctPrice)];
        self.payObjectID           = [coder decodeObjectForKey:getMD5String(PayObjectID)];
        self.proudctID             = [coder decodeObjectForKey:getMD5String(ProudctID)];
        self.sandbox               = [coder decodeObjectForKey:getMD5String(Sandbox)];
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


+ (BOOL)addTransactionIdentifier:(NSString *)transactionIdentifier
                  receiptDataStr:(NSString *)receiptDataStr
                    proudctPrice:(NSString *)proudctPrice
                       proudctID:(NSString *)proudctID
                     payObjectID:(NSString *)payObjectID
                         sandbox:(BOOL)sandbox {
    
    if (transactionIdentifier && payObjectID && receiptDataStr) {
        NHOrderInfo *orderinfo = [[NHOrderInfo alloc] init];
        orderinfo.payObjectID = payObjectID;
        orderinfo.proudctPrice = proudctPrice;
        orderinfo.receiptDataStr = receiptDataStr;
        orderinfo.payTimeStamp = [self getCurrentDateBaseStyleWithData:nil];
        orderinfo.transactionIdentifier = transactionIdentifier;
        orderinfo.proudctID = proudctID;
        orderinfo.sandbox = [NSNumber numberWithBool:sandbox];
        NSLog(@"保存订单:\n%@,\n%ld,\n%@,\n%@,\n%@",orderinfo.transactionIdentifier,orderinfo.receiptDataStr.length,orderinfo.proudctPrice,orderinfo.payObjectID,orderinfo.payTimeStamp);
        
        return [self saveOrderInfo:orderinfo fileName:transactionIdentifier];
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
        NSLog(@"删除订单：\n%@,\n%ld,\n%@,\n%@,\n%@",orderinfo.transactionIdentifier,orderinfo.receiptDataStr.length,orderinfo.proudctPrice,orderinfo.payObjectID,orderinfo.payTimeStamp);
        if (error) {
            NSLog(@"\n订单删除失败:%@",error.localizedDescription);
        }
    }
    return isExists;
}

+ (NHOrderInfo *)checkUnderwayingUnfinishedOrder:(NSString *)productID {
    NHOrderInfo *orderinfo;
    for (NSString *name in [self getFiles]) {
        NHNSLog(@"checkUnderwayingOrder: %@",name);
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
            if (orderinfo.receiptDataStr.length < 2) continue;
            
            [orders addObject:orderinfo];
            NHNSLog(@"检查订单:\n%@,\n%lu,\n%@,\n%@,\n%@",orderinfo.transactionIdentifier,orderinfo.receiptDataStr.length,
                  orderinfo.proudctPrice,orderinfo.payObjectID,orderinfo.payTimeStamp);
            
            //通知服务器验证
            [NHPaymentVerify verifyPaymentResultWithNHOrderInfo:orderinfo];
            

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

+ (NHOrderInfo *)getOrderInfoTransactionIdentifier:(NSString *)transactionIdentifier {
    NHOrderInfo *orderinfo = [NSKeyedUnarchiver unarchiveObjectWithFile:LocalOrderCachePath(transactionIdentifier,YES)];
    return orderinfo;
}


+ (NSString *)getCurrentDateBaseStyleWithData:(NSData *)data{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSInteger unitFlags = NSYearCalendarUnit |
    NSMonthCalendarUnit |
    NSDayCalendarUnit |
    NSWeekdayCalendarUnit |
    NSHourCalendarUnit |
    NSMinuteCalendarUnit |
    NSSecondCalendarUnit;
    
    NSDate *currentDate = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    comps = [calendar components:unitFlags fromDate:data ? nil : currentDate];
    NSInteger week = [comps weekday];
    NSInteger year=[comps year];
    NSInteger month = [comps month];
    NSInteger day = [comps day];
    //[formatter setDateStyle:NSDateFormatterMediumStyle];
    //This sets the label with the updated time.
    NSInteger hour = [comps hour];
    NSInteger min = [comps minute];
    NSInteger sec = [comps second];
    NSString *dataString = [NSString stringWithFormat:@"%ld%ld%ld%ld%ld",year,month,day,hour,min];
    return dataString;
}
@end
