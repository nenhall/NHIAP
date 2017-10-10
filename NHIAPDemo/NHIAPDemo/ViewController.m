//
//  ViewController.m
//  NHIAPDemo
//
//  Created by neghao on 2017/6/7.
//  Copyright © 2017年 neghao. All rights reserved.
//

#import "ViewController.h"
#import "NHIAP.h"
#import <NHHUDExtend/MBProgressHUD+NHAdd.h>

@interface ViewController ()
@property (nonatomic, copy  ) NSArray  *proudctIDS;
@property (nonatomic, copy  ) NSArray  *productPrices;
@end

@implementation ViewController

- (void)setproudctIDS {
    //产品id
    _proudctIDS = @[
                    @"com.facebac.MontnetsLiveCloud.number01",
                    @"com.facebac.MontnetsLiveCloud.number02",
                    @"com.facebac.MontnetsLiveCloud.number03",
                    @"com.facebac.MontnetsLiveCloud.number04",
                    @"com.facebac.MontnetsLiveCloud.number05",
                    @"com.facebac.MontnetsLiveCloud.number06",
                    ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //请求产品信息，看是否正确，能否进行支付
    [self updateStoreProducts];
    
    [self restore];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setproudctIDS];
    
}

- (void)restore {
    [NHIAP restoreTransaction:^(NSArray<SKProduct *> * _Nullable products) {
        NHLog(@"restoreTransaction:%@",products);

    } success:^(SKPaymentTransaction * _Nullable payTransaction, BOOL environmentSandbox) {
        MBProgressHUD *hud = [MBProgressHUD HUDForView:self.navigationController.view];

        NHLog(@"restoreTransaction／success:%@",payTransaction.payment.productIdentifier);
        if (hud) {
            hud.title(@"正在恢复已购商品");
            [hud hideAnimated:YES afterDelay:1.2];
        } else {
            [MBProgressHUD showOnlyTextToView:nil title:@"正在恢复已购商品"];
        }
        
        /** do something  eg:通知后台去难证
         验证完成后调用：[[NHIAP sharedNHIAP] finishTransaction:payTransaction];
         */
        [[NHIAP sharedNHIAP] finishTransaction:payTransaction];
        
    } failure:^(SKPaymentTransaction * _Nullable transaction, NSError * _Nullable error) {
        NHLog(@"restoreTransaction／failure:%@",error.localizedDescription);
        MBProgressHUD *hud = [MBProgressHUD HUDForView:self.navigationController.view];

        if (hud) {
            hud.title(error.localizedDescription);
            [hud hideAnimated:YES afterDelay:1.2];
        } else {
            [MBProgressHUD showOnlyTextToView:nil title:error.localizedDescription];
        }
        
    }];
}

- (IBAction)buy:(UIButton *)sender {
    
    NHIAP *iap = [NHIAP sharedNHIAP];
    if (iap.isRequestProudct) {
        NHIAPTipWithMessage(@"正在更新商品信息...");
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showLoadToView:self.navigationController.view contentColor:[UIColor whiteColor] title:@"正在购买，请不要离开..."];
    
    [NHIAP addPayment:_proudctIDS[sender.tag] consumerId:@"nh2017" success:^(SKPaymentTransaction * _Nullable payTransaction, BOOL environmentSandbox) {
        
        hud.title(payTransaction.payment.productIdentifier);
        [hud hideAnimated:YES afterDelay:1.2];
        NHLog(@"%@",payTransaction.payment.productIdentifier);
        
        /** do something  eg:通知后台去难证
         验证完成后调用：[[NHIAP sharedNHIAP] finishTransaction:payTransaction];
         */
        [[NHIAP sharedNHIAP] finishTransaction:payTransaction];
        
    } failure:^(SKPaymentTransaction * _Nullable payTransaction, NSError * _Nullable error) {
        NHLog(@"\n %@：订单号：%@",error.localizedDescription ,payTransaction.transactionIdentifier);
        hud.mode = MBProgressHUDModeText;
        hud.title(error.localizedDescription);
        [hud hideAnimated:YES afterDelay:1.2];
        
        [[NHIAP sharedNHIAP] finishTransaction:payTransaction];
    }];
}


#pragma mark - 苹果支付相关
- (void)updateStoreProducts {
    [NHIAP requestProducts:_proudctIDS success:^(NSArray<SKProduct *> * _Nullable products) {
        NHLog(@"产品请求：%@",products);
    } invalidProductId:^(NSArray<NSString *> * _Nullable invalidProductsIdentifier) {
        
    } failure:^(NSError * _Nullable error) {
        
    }];
}



@end
