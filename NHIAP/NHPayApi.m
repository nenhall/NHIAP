//
//  NHApi.m
//  NHMobilePayDemo
//
//  Created by neghao on 2017/3/6.
//  Copyright © 2017年 NegHao.Studio. All rights reserved.
//

#import "NHPayApi.h"
#import <CommonCrypto/CommonDigest.h>

#define kAppID    @"appID"
#define kAppIDNum @(5)

#define PayURL_payed              @"https://api.cnlive.com/open/api2/unifypay/payed"
#define PayURL_prepay             @"https://api.cnlive.com/open/api2/unifypay/prepay"
#define Sandbox_IAPURL            @"https://sandbox.itunes.apple.com/verifyReceipt" //applePay 沙盒环境
#define Production_IAPURL         @"https://buy.itunes.apple.com/verifyReceipt" //applePay 正式环境

@implementation NHPayApi
//去苹果服务器验证
+ (void)IAPVerifyIsSandboxEnvironment:(BOOL)isSandboxEnvironment
                           receiptStr:(NSString *)receiptStr
                             complete:(ResultBlock)complete {

    // Create the JSON object that describes the request
    NSError *error = nil;
    NSDictionary *requestContents = @{
                                      @"receipt-data":receiptStr
                                      };
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents
                                                          options:0
                                                            error:&error];
    
    NSString *iapUrl = Sandbox_IAPURL;
    if (!isSandboxEnvironment) {
        iapUrl = Production_IAPURL;
    }
    
    // Create a POST request with the receipt data.
    NSURL *storeURL = [NSURL URLWithString:iapUrl];
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    
    
    // Make a connection to the iTunes Store on a background queue.
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:storeRequest
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             NSError *error2;
             NSDictionary *jsonResponse;
             if (data) {
                 jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error2];
             }
             if (complete) {
                 complete(jsonResponse,error);
             }
         });
     }];
}


/** 去app服务的验证*/
+ (void)payVerifyWithReceiptData:(NSString *)receiptData
                   transactionID:(NSString *)transactionID
                        totalFee:(NSString *)totalFee
                          userID:(NSString *)userID
                         is_test:(int)is_test
                        complete:(ResultBlock)complete {
    
}





static NSString* NSStringFromQueryParameters(NSDictionary* queryParameters)
{
    NSMutableArray* parts = [NSMutableArray array];
    [queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *part = [NSString stringWithFormat: @"%@=%@",
                          [key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
                          [value stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
                          ];
        [parts addObject:part];

//        NSString *part = [NSString stringWithFormat: @"%@=%@",key,value];
//        [parts addObject:part];
    }];
    return [parts componentsJoinedByString: @"&"];
}

/**
 Creates a new URL by adding the given query parameters.
 @param URL The input URL.
 @param queryParameters The query parameter dictionary to add.
 @return A new NSURL.
 */
static NSURL* NSURLByAppendingQueryParameters(NSURL* URL, NSDictionary* queryParameters)
{
    NSString* URLString = [NSString stringWithFormat:@"%@?%@",
                           [URL absoluteString],
                           NSStringFromQueryParameters(queryParameters)
                           ];
    return [NSURL URLWithString:URLString];
}


+ (NSString *)getCurrentDateBaseStyle:(NSData *)data{
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
    NSString *dataString = [NSString stringWithFormat:@"%ld%ld%ld%ld%ld%ld%ld",year,month,week,day,hour,min,sec];
    return dataString;
}


#pragma mark 签名
//加密
+ (NSString*)sha1:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (int)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    while ([[output substringToIndex:1] isEqualToString:@"0"]) {
        output = [[NSMutableString alloc] initWithString:[output substringFromIndex:1]];
    }
    
    return output;
}


//签名
+ (NSString *)signvalue:(NSDictionary*)parameter
{
    //对所有传入参数按照字段名的 ASCII 码从小到大排序
    NSArray *keyArr=[parameter allKeys];
    NSArray *arr = [keyArr sortedArrayUsingSelector:@selector(compare:)];
    
    NSMutableString *string1 = [[NSMutableString alloc]init];
    for (int i=0; i<arr.count; i++) {
        
        NSString *parameterString = parameter[[arr objectAtIndex:i]];
        if (parameterString.length > 0) {
            [string1 appendString:[NSString stringWithFormat:@"%@=%@&",[arr objectAtIndex:i],parameter[[arr objectAtIndex:i]]]];
        }
    }
    
    if (string1.length > 0) {
        [string1 deleteCharactersInRange:NSMakeRange(string1.length-1, 1)];
    }
    
    return string1;
}

@end
