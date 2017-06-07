//
//  ViewController.m
//  NHIAPDemo
//
//  Created by neghao on 2017/6/7.
//  Copyright © 2017年 neghao. All rights reserved.
//

#import "ViewController.h"
#import "NHIAP.h"

@interface ViewController ()
@property (nonatomic, copy  ) NSArray  *proudctIDS;
@property (nonatomic, copy  ) NSArray  *productPrices;
@end

@implementation ViewController

- (void)setproudctIDS {
    //价格
    _productPrices = @[@6,@30,@88,@588,@1598,@1998];
    //产品id
    _proudctIDS = @[
                    @"com.neghao.iap01",
                    @"com.neghao.iap02",
                    @"com.neghao.iap03",
                    @"com.neghao.iap04",
                    @"com.neghao.iap05",
                    @"com.neghao.iap06",
                    ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //请求产品信息，看是否正确，能否进行支付
    [self updateStoreProducts];
}

- (void)viewDidLoad {
    [super viewDidLoad];


}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {

    [self buyEvent];
}

#pragma mark - 苹果支付相关
- (void)updateStoreProducts {
    [NHIAP requestProducts:nil success:^(NSArray<SKProduct *> *products, NSArray<NSString *> *invalidIdentifiers) {
        NSLog(@"查询成功:%@--%@",products,invalidIdentifiers);
        
    } failure:^(NSError *error) {
        tipWithMessage(error.localizedDescription);
        NSLog(@"查询失败:%@",error);
    }];
}


- (void)buyEvent{
    NHIAP *iap = [NHIAP sharedNHIAP];
    if (iap.isRequestProudct) {
        tipWithMessage(@"正在更新商品信息...");
        return;
    }
    
    __weak typeof(self) weakself = self;
//    __block MBProgressHUD *hud = [MBProgressHUD showMessage:@"正在购买，请不要离开..." ToView:kWindow];
    
    [iap addPayment:self.proudctIDS[1]
        payObjectID:@"123"/**支付者ID*/
    paymentComplete:^(SKPaymentTransaction *transaction) {
//        hud.label.text = @"正在充值，请不要离开...";
        
        
    } success:^(SKPaymentTransaction *transaction, NSDictionary *resultObject, BOOL isRestore_sub) {
//        [hud hideAnimated:YES];
        
        //do something eg:更新用户全额
        if (!isRestore_sub) tipWithMessage(@"充值成功！");
        
        
    } failure:^(SKPaymentTransaction *transaction, BOOL isRestore_sub, NSError *error) {
//        [hud hideAnimated:YES];
        
        if (error && !isRestore_sub) {
            //@"交易失败,%@",error.localizedDescription;
            
        } else {
           //[NSString stringWithFormat:@"交易失败,交易未完成！"]
        }
        NHNSLog(@"\n %@：订单号：%@",error.localizedDescription ,transaction.transactionIdentifier);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
