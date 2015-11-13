//
//  PayOrderByAlipay.m
//  shopping
//
//  Created by yunlai on 13-3-5.
//
//

#import "PayOrderByAlipay.h"
//#import "AlixPayOrder.h"
//#import "AlixPayResult.h"
//#import "AlixPay.h"
//#import "DataSigner.h"

#import "Order.h"
#import <AlipaySDK/AlipaySDK.h>
#import "DataSigner.h"

#import "Product.h"
#import "Common.h"

@implementation PayOrderByAlipay


+ (BOOL) payOrder:(float)orderPrice withOrderID:(NSString*)orderID withOrderName:(NSString*)name withDesc:(NSString*)desc{
    NSLog(@"payorder");
    /*
	 *点击获取prodcut实例并初始化订单信息
	 */
	Product *product = [[Product alloc] init];
    product.price = orderPrice;//[[orderArray objectAtIndex:2] floatValue];
    product.orderId = orderID;//[self generateTradeNO];//[orderArray objectAtIndex:1];
    product.subject = name;
    product.body = desc;
    
    /*
     *商户的唯一的parnter和seller。
     *外部商户可以考虑存于服务端或本地其他地方。
     *签约后，支付宝会为每个商户分配一个唯一的 parnter 和 seller。
     */
    NSString *partner = ALIPAY_PARTNER;
    NSString *seller = ALIPAY_SELLER;
    //partner和seller获取失败,提示
	if ([partner length] == 0 || [seller length] == 0)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
														message:@"缺少partner或者seller。"
													   delegate:self
											  cancelButtonTitle:@"确定"
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		return NO;
	}
    /*
	 *生成订单信息及签名
	 *可以存放在服务端或本地其他地方,确保安全性
	 */
	//将商品信息赋予AlixPayOrder的成员变量
    
    
    Order *order = [[Order alloc] init];
    order.partner = partner;
    order.seller = seller;
    order.tradeNO = orderID; //订单ID（由商家自行制定）
    order.productName = product.subject; //商品标题
    order.productDescription = product.body; //商品描述
    order.amount = @"0.01"; //商品价格
    order.notifyURL = @"http://www.yunlai.cn"; //回调URL
    
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    //NSLog(@"orderSpec = %@",orderSpec);
    
    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner([[NSBundle mainBundle] objectForInfoDictionaryKey:@"RSA private key"]);
    NSString *signedString = [signer signString:orderSpec];
    
    
    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types,用于安全支付成功后重新唤起商户应用
    NSString *appScheme = @"ShopingTempleate";
    
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                       orderSpec, signedString, @"RSA"];
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"reslut = %@",resultDic);
            int resurtInt = [[resultDic objectForKey:@"resultStatus"] intValue];
            if (resurtInt == 9000) {
                NSLog(@"支付成功");
            } else {
                NSLog(@"支付失败");
            }
        }];
    }
    
//    AlixPayOrder *order = [[AlixPayOrder alloc] init];
//	order.partner = partner;
//	order.seller = seller;
//	order.tradeNO = orderID;//订单ID（由商家自行制定）
//	order.productName = product.subject; //商品标题
//	order.productDescription = product.body; //商品描述
//    order.amount = @"0.01";//[NSString stringWithFormat:@"%.2f",product.price]; //商品价格
//	order.notifyURL =  @"http://www.yunlai.cn"; //回调URL
//    
//    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types,用于安全支付成功后重新唤起商户应用
//	NSString *appScheme = @"ShopingTempleate";
//    
//    //将商品信息拼接成字符串
//	NSString *orderSpec = [order description];
//	NSLog(@"orderSpec = %@",orderSpec);
//	
//	//获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
//	id<DataSigner> signer = CreateRSADataSigner([[NSBundle mainBundle] objectForInfoDictionaryKey:@"RSA private key"]);
//	NSString *signedString = [signer signString:orderSpec];
//    
//    //将签名成功字符串格式化为订单字符串,请严格按照该格式
//	NSString *orderString = nil;
//	if (signedString != nil) {
//		orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
//                       orderSpec, signedString, @"RSA"];
//        NSLog(@"orderString = %@",orderString);
//        
//        //获取安全支付单例并调用安全支付接口
//        AlixPay * alixpay = [AlixPay shared];
//        int ret = [alixpay pay:orderString applicationScheme:appScheme];
//        
//        if (ret == kSPErrorAlipayClientNotInstalled) {
//            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"提示"
//                                                                 message:@"您还没有安装支付宝快捷支付，请先安装。"
//                                                                delegate:self
//                                                       cancelButtonTitle:@"确定"
//                                                       otherButtonTitles:nil];
//            [alertView setTag:123];
//            [alertView show];
//            [alertView release];
//        }
//        else if (ret == kSPErrorSignError) {
//            NSLog(@"签名错误！");
//        }
//        
//	}
    return YES;
}

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//	if (alertView.tag == 123) {
//		NSString * URLString = [NSString stringWithString:@"http://itunes.apple.com/cn/app/id535715926?mt=8"];
//		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
//	}
//}


@end
