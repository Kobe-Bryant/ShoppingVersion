//
//  UIColumnViewCell.m
//  shopping
//
//  Created by yunlai on 13-1-22.
//
//

#import "UIColumnViewCell.h"
#import "myImageView.h"
#import "DBOperate.h"
#import "Common.h"
#import "FileManager.h"
#import "UIImageScale.h"
#import "downloadParam.h"
#import "imageDownLoadInWaitingObject.h"
#import "OriginPicViewController.h"
#import "DataManager.h"
#import "carViewController.h"
#import "picDetailViewController.h"
#import "TableFooterView.h"
#import "Product.h"
//#import "AlixPayOrder.h"
//#import "AlixPayResult.h"
//#import "AlixPay.h"
//#import "DataSigner.h"
#import "tabEntranceViewController.h"
#import "CustomTabBar.h"
#import "SubmitOrderViewController.h"
#import "AddOrEditReservationViewController.h"
#import "LoginViewController.h"

#define PIC_WIDTH 220
#define MARGIN 12

@implementation UIColumnViewCell

@synthesize productDetailData;
@synthesize imageDownloadsInProgress;
@synthesize imageDownloadsInWaiting;
@synthesize productPicArray;
@synthesize myNavigationController;
@synthesize commentArray;
@synthesize isLoadingMore;
@synthesize canLoadMore;
@synthesize delegate;
@synthesize pageControl;
@synthesize commentTableView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        //图片下载类初始化
        NSMutableDictionary *idip = [[NSMutableDictionary alloc]init];
        self.imageDownloadsInProgress = idip;
        [idip release];
        NSMutableArray *wait = [[NSMutableArray alloc]init];
        self.imageDownloadsInWaiting = wait;
        [wait release];
        
        productDetailData = [[NSArray alloc] init];
        productPicArray = [[NSArray alloc] init];
        
        isLoadingMore = NO;
        canLoadMore = YES;
    }
    
    return self;
}

- (void)dealloc {
    [headerView release],headerView = nil;
    [docImage release],docImage = nil;
    [commentTableView release],commentTableView = nil;
    [pageControl release], pageControl = nil;
    [productDetailData release],productDetailData = nil;
    [imageDownloadsInProgress release],imageDownloadsInProgress = nil;
    [imageDownloadsInWaiting release],imageDownloadsInWaiting = nil;
    [productPicArray release],productPicArray = nil;
    [myNavigationController release],myNavigationController = nil;
    [commentArray release],commentArray = nil;
    [footerView release],footerView = nil;
    [progressHUD release],progressHUD = nil;
    [super dealloc];
}

- (void) addComponent{
    //读取产品图片
    
    self.productPicArray = [productDetailData objectAtIndex:product_pics];
    
    NSMutableArray *cay = [[NSMutableArray alloc] init];
    self.commentArray = cay;
    [cay release];
    
    [self addCommentTableview];
    
    //请求该产品的评论
    [self accessService];
}

- (void) addCommentTableview
{
    [commentTableView removeFromSuperview];
    UITableView *tb = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, [UIScreen mainScreen].bounds.size.height - 20 - 84 - 44) style:UITableViewStylePlain];
    self.commentTableView = tb;
    [tb release];
    
    [self creatHeadView];
    
    commentTableView.backgroundColor = [UIColor clearColor];
    commentTableView.delegate = self;
    commentTableView.dataSource = self;
    commentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    footerView = [[TableFooterView alloc] initWithFrame:CGRectMake(0,0, self.frame.size.width,44)];
    commentTableView.tableFooterView = footerView;
    [footerView release];
    
    [self addSubview:commentTableView];
    
    [self.commentTableView reloadData];
}

- (void)accessService
{
    int pid = [[productDetailData objectAtIndex:product_id] intValue];
	NSMutableDictionary *jsontestDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        [Common getSecureString],@"keyvalue",
                                        [NSNumber numberWithInt: SITE_ID],@"site_id",
                                        [NSNumber numberWithInt:pid],@"id",
                                        [NSNumber numberWithInt:0],@"type",
                                        [NSNumber numberWithInt:0],@"created",
                                        nil];
	
	[[DataManager sharedManager] accessService:jsontestDic command:PRODUCT_COMMENTLIST_COMMAND_ID accessAdress:@"comment/list.do?param=%@" delegate:self withParam:jsontestDic];
}

#pragma mark -
#pragma mark CommandOperationDelegate
- (void) didFinishCommand:(NSMutableArray *)resultArray cmd:(int)commandid withVersion:(int)ver{
    
    if (commandid == SUBMIT_ORDER_COMMAND_ID) {
        [self performSelectorOnMainThread:@selector(easyBuyResult:) withObject:resultArray waitUntilDone:NO];
    }else if(commandid == PRODUCT_COMMENTLIST_COMMAND_ID){
        //加载更多情况，
        if (isLoadingMore) {
            [self performSelectorOnMainThread:@selector(loadMoreCompleted:) withObject:resultArray waitUntilDone:NO];
        }else{
            //self.commentArray = resultArray;
            [commentArray addObjectsFromArray:resultArray];
            [resultArray release];
            [self performSelectorOnMainThread:@selector(addCommentTableview) withObject:nil waitUntilDone:NO];
        }
    }else if(commandid == EASYLIST_COMMAND_ID){
        [self performSelectorOnMainThread:@selector(toSubbmitOrderView) withObject:nil waitUntilDone:NO];
    }
}

- (void) easyBuyResult:(NSArray*)resultArray{
    if (progressHUD != nil) {
		if (progressHUD) {
			[progressHUD removeFromSuperview];
		}
	}
    //组装订单
    NSMutableArray *buyArray = [[NSMutableArray alloc] init];
    NSMutableArray *buy_product = [[NSMutableArray alloc] init];
    [buy_product addObject:[productDetailData objectAtIndex:product_id]];
    [buy_product addObject:[NSNumber numberWithInt:1]];
    [buy_product addObject:[productDetailData objectAtIndex:product_price]];
    [buy_product addObject:[productDetailData objectAtIndex:product_promotion_price]];
    [buy_product addObject:[productDetailData objectAtIndex:product_title]];
    [buy_product addObject:[productDetailData objectAtIndex:product_pic]];
    [buy_product addObject:[NSNumber numberWithInt:1]];
    [buyArray addObject:buy_product];
    [buy_product release];
    
    //跳转至订单页面
    SubmitOrderViewController *sc = [[SubmitOrderViewController alloc] init];
    sc.shopArray = buyArray;
    sc.totalMoney = [[productDetailData objectAtIndex:product_promotion_price]intValue] - promotionMoney;
    sc.totalPrice = [NSString stringWithFormat:@"￥ %d",[[productDetailData objectAtIndex:product_promotion_price]intValue]];
    int save = [[productDetailData objectAtIndex:product_price]intValue] - [[productDetailData objectAtIndex:product_promotion_price]intValue];
    sc.savePrice = [NSString stringWithFormat:@"￥ %d",save];
    sc.isEasyBuy = YES;
    [self.myNavigationController pushViewController:sc animated:YES];
    [buyArray release];
    [sc release];
}

#pragma mark -
#pragma mark Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        int count = [commentArray count];
        return count;
    }else {
        return 0;
    }
}

- (void)creatHeadView{
    headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor whiteColor];
    
    int picCount = [self.productPicArray count];
    imageScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, PIC_WIDTH)];
    UIImageView *showBackGround = [[UIImageView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, PIC_WIDTH)];
    UIImage *backImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"商品详情图片背景" ofType:@"png"]];
    showBackGround.image = [backImage fillSize:CGSizeMake(self.frame.size.width, PIC_WIDTH)];
    [backImage release];
    [headerView addSubview:showBackGround];
    [showBackGround release];
    
    imageScrollView.pagingEnabled = YES;
    imageScrollView.delegate = self;
    imageScrollView.showsHorizontalScrollIndicator = NO;
    imageScrollView.scrollEnabled = YES;
    imageScrollView.contentSize = CGSizeMake(320 * picCount, PIC_WIDTH);
    [headerView addSubview:imageScrollView];
    for (int i = 0; i < picCount; i++) {
        NSArray *pic_thrum_ay = [productPicArray objectAtIndex:i];
        
        myImageView *iv = [[myImageView alloc]initWithFrame:CGRectMake(50 +320*i, 0, PIC_WIDTH, imageScrollView.frame.size.height) withImageId:[NSString stringWithFormat:@"%d",i]];
        iv.tag = i+150;
        
        NSString *imageUrl = [pic_thrum_ay objectAtIndex:product_pic_pic];
        NSString *picName = [Common encodeBase64:(NSMutableData *)[imageUrl dataUsingEncoding: NSUTF8StringEncoding]];
        UIImage *photo = [FileManager getPhoto:picName];
        if (photo != nil && photo.size.width > 0)
        {
            iv.image = photo;
        }
        else
        {
            UIImage *img = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"商品详情默认图片" ofType:@"png"]];
            iv.image = img;
            [img release];
            
            [self startIconDownload:imageUrl forIndexPath:[NSIndexPath indexPathForRow:150+i inSection:0]];
        }
        iv.mydelegate = self;
        [imageScrollView addSubview:iv];
        [iv release];
    }
    
    UIPageControl *pc = [[UIPageControl alloc] initWithFrame:CGRectMake(-40, 196, 80, 30)];
    self.pageControl = pc;
    [pc release];
    pageControl.currentPage = 0;
    pageControl.backgroundColor = [UIColor clearColor];
    pageControl.numberOfPages = picCount;
    [headerView addSubview:pageControl];
    
    float totalHeigth = 0;
    totalHeigth += PIC_WIDTH;
    
    //添加优惠价
    NSString *promitionPrice = [productDetailData objectAtIndex:product_promotion_price];
    UIImage *image = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"优惠价" ofType:@"png"]];
    if ([promitionPrice length] > 0  && [promitionPrice intValue] > 0) {
        UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(MARGIN, totalHeigth+MARGIN,image.size.width, image.size.height)];
        imageview.image = image;
        [headerView addSubview:imageview];
        [imageview release];
        
        UILabel *promotionPriceLabel = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN, totalHeigth+MARGIN+20,120, image.size.height)];
        promotionPriceLabel.backgroundColor = [UIColor clearColor];
        promotionPriceLabel.font = [UIFont boldSystemFontOfSize:14];
        promotionPriceLabel.textColor = [UIColor redColor];
        promotionPriceLabel.text = [NSString stringWithFormat:@"%.2f",[promitionPrice doubleValue]];
        promotionPriceLabel.textAlignment = UITextAlignmentLeft;
        [headerView addSubview:promotionPriceLabel];
        [promotionPriceLabel release];
    }
    
    
    //添加市场价
    UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(image.size.width + 3*MARGIN, totalHeigth+MARGIN,80, image.size.height)];
    priceLabel.backgroundColor = [UIColor clearColor];
    priceLabel.font = [UIFont systemFontOfSize:14];
    priceLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    if ([promitionPrice length] > 0 && [promitionPrice intValue] > 0) {
        priceLabel.text = @"市场价";
    }else{
        priceLabel.text = @"价格";
        priceLabel.font = [UIFont boldSystemFontOfSize:14];
        priceLabel.textColor = [UIColor redColor];
        priceLabel.frame = CGRectMake(2*MARGIN, totalHeigth+MARGIN ,50, image.size.height );
    }
    [headerView addSubview:priceLabel];
    [priceLabel release];
    
    UILabel *normalPriceLabel = [[UILabel alloc] initWithFrame:CGRectMake(image.size.width + 3*MARGIN, totalHeigth+MARGIN, 120, image.size.height)];
    normalPriceLabel.backgroundColor = [UIColor clearColor];
    normalPriceLabel.font = [UIFont systemFontOfSize:14];
    normalPriceLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    if ([promitionPrice length] > 0 && [promitionPrice intValue] > 0) {
        normalPriceLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
        normalPriceLabel.frame = CGRectMake(MARGIN, totalHeigth+MARGIN, image.size.width, image.size.height);
    }
    normalPriceLabel.text = [NSString stringWithFormat:@"%.2f",[[productDetailData objectAtIndex:product_price] doubleValue]];
    normalPriceLabel.textAlignment = UITextAlignmentLeft;
    [headerView addSubview:normalPriceLabel];
    
    CGSize constraint = CGSizeMake(120, 20000.0f);
    CGSize size = [normalPriceLabel.text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
    if ([promitionPrice length] > 0 && [promitionPrice intValue] > 0) {
        totalMoney = [[productDetailData objectAtIndex:product_promotion_price] doubleValue];
        normalPriceLabel.frame = CGRectMake(image.size.width + 3*MARGIN, totalHeigth+MARGIN+20,120, image.size.height);
    }else{
        totalMoney = [[productDetailData objectAtIndex:product_price] doubleValue];
        normalPriceLabel.textColor = [UIColor redColor];
        normalPriceLabel.frame = CGRectMake(2*MARGIN, totalHeigth+MARGIN+20,120, image.size.height);
    }
    
    [image release];
    
    UIImageView *lineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(-1,8, size.width+2, 1)];
    lineImageView.backgroundColor = [UIColor darkGrayColor];
    if ([promitionPrice length] > 0 && [promitionPrice intValue] > 0) {
        [normalPriceLabel addSubview:lineImageView];
    }
    [lineImageView release];
    
    [normalPriceLabel release];
    
    //购买、收藏、喜欢三个按钮
    UIImage *buyImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"详情_购买" ofType:@"png"]];
    UIImageView *buyImageview = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width-98, totalHeigth+MARGIN,buyImage.size.width, buyImage.size.height)];
    buyImageview.image = buyImage;
    [buyImage release];
    [headerView addSubview:buyImageview];
    [buyImageview release];
    
    UILabel *buyLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width-98, totalHeigth+MARGIN+20,buyImage.size.width, buyImage.size.height)];
    buyLabel.backgroundColor = [UIColor clearColor];
    buyLabel.font = [UIFont systemFontOfSize:14];
    buyLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    buyLabel.text = [NSString stringWithFormat:@"%d",[[productDetailData objectAtIndex:product_salenum] intValue]];
    buyLabel.textAlignment = UITextAlignmentCenter;
    [headerView addSubview:buyLabel];
    [buyLabel release];
    
    UIImage *likeImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"详情_喜欢" ofType:@"png"]];
    UIImageView *likeImageview = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width-64, totalHeigth+MARGIN,buyImage.size.width, buyImage.size.height)];
    likeImageview.image = likeImage;
    [likeImage release];
    [headerView addSubview:likeImageview];
    [likeImageview release];
    
    UILabel *likeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width-64, totalHeigth+MARGIN+20,buyImage.size.width, buyImage.size.height)];
    likeLabel.backgroundColor = [UIColor clearColor];
    likeLabel.font = [UIFont systemFontOfSize:14];
    likeLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    likeLabel.text = [NSString stringWithFormat:@"%d",[[productDetailData objectAtIndex:product_likes] intValue]];;
    likeLabel.textAlignment = UITextAlignmentCenter;
    [headerView addSubview:likeLabel];
    [likeLabel release];
    
    UIImage *shoucangImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"详情_收藏" ofType:@"png"]];
    UIImageView *shoucangImageview = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width-30, totalHeigth+MARGIN,buyImage.size.width, buyImage.size.height)];
    shoucangImageview.image = shoucangImage;
    [shoucangImage release];
    [headerView addSubview:shoucangImageview];
    [shoucangImageview release];
    
    UILabel *shoucangLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width-30, totalHeigth+MARGIN+20,buyImage.size.width, buyImage.size.height)];
    shoucangLabel.backgroundColor = [UIColor clearColor];
    shoucangLabel.font = [UIFont systemFontOfSize:14];
    shoucangLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    shoucangLabel.text = [NSString stringWithFormat:@"%d",[[productDetailData objectAtIndex:product_favorites] intValue]];;
    shoucangLabel.textAlignment = UITextAlignmentCenter;
    [headerView addSubview:shoucangLabel];
    [shoucangLabel release];
    
    //添加虚线
    docImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"商品一级分类分割线" ofType:@"png"]];
    UIImageView *docImageview = [[UIImageView alloc] initWithFrame:CGRectMake(0, totalHeigth+2*MARGIN+30,docImage.size.width, 1)];
    docImageview.image = docImage;
    [headerView addSubview:docImageview];
    [docImageview release];
    
    totalHeigth = totalHeigth+2*MARGIN+30;
    
    UIImageView *docImageview2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, totalHeigth+60,docImage.size.width, 1)];
    docImageview2.image = docImage;
    [headerView addSubview:docImageview2];
    [docImageview2 release];
    
    //添加两个按钮
    UIImage *easyBuyImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"产品详情黄色按钮" ofType:@"png"]];
    easyBuy = [UIButton buttonWithType:UIButtonTypeCustom];
    easyBuy.frame = CGRectMake(7, totalHeigth+(60-easyBuyImage.size.height)/2, easyBuyImage.size.width, easyBuyImage.size.height);
    [easyBuy addTarget:self action:@selector(handleEasyBuy:)
      forControlEvents:UIControlEventTouchUpInside];
    [easyBuy setBackgroundImage:easyBuyImage forState:UIControlStateNormal];
    [easyBuyImage release];
    [easyBuy setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    
    [easyBuy setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    easyBuy.titleLabel.font = [UIFont systemFontOfSize:15];
    [easyBuy setTitle:@"轻松购" forState:UIControlStateNormal];
    easyBuy.titleLabel.textAlignment = UITextAlignmentCenter;
    [headerView addSubview:easyBuy];
    
    UIImage *img = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"产品详情红色按钮" ofType:@"png"]];
    buyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    buyButton.frame = CGRectMake(164, totalHeigth+(60-img.size.height)/2, img.size.width, img.size.height);
    [buyButton addTarget:self action:@selector(handleAddToCar:)
        forControlEvents:UIControlEventTouchUpInside];
    [buyButton setBackgroundImage:img forState:UIControlStateNormal];
    [img release];
    [buyButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    
    [buyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    buyButton.titleLabel.font = [UIFont systemFontOfSize:15];
    int sum_count = [[productDetailData objectAtIndex:product_sum] intValue];
    NSArray *ay = [DBOperate queryData:T_SHOPCAR theColumn:@"product_id" theColumnValue:[productDetailData objectAtIndex:product_id] withAll:NO];
    int shop_count = 0;
    if ([ay count] > 0) {
        NSArray *car_ay = [ay objectAtIndex:0];
        shop_count = [[car_ay objectAtIndex:shopcar_product_count] intValue];
    }
    
    if (sum_count > 0) {
        if (shop_count < sum_count) {
            [buyButton setTitle:@"加入购物车" forState:UIControlStateNormal];
        }else{
            UIImage *image = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"产品线详情灰色按钮" ofType:@"png"]];
            [buyButton setTitle:@"加入购物车" forState:UIControlStateNormal];
            [buyButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [easyBuy setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [buyButton setBackgroundImage:image forState:UIControlStateNormal];
            [easyBuy setBackgroundImage:image forState:UIControlStateNormal];
            buyButton.userInteractionEnabled = NO;
            easyBuy.userInteractionEnabled = NO;
            [image release];
        }
    }else{
        UIImage *image = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"产品线详情灰色按钮" ofType:@"png"]];
        [buyButton setTitle:@"加入购物车" forState:UIControlStateNormal];
        [buyButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [easyBuy setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [buyButton setBackgroundImage:image forState:UIControlStateNormal];
        [easyBuy setBackgroundImage:image forState:UIControlStateNormal];
        buyButton.userInteractionEnabled = NO;
        easyBuy.userInteractionEnabled = NO;
        [image release];
    }
    buyButton.titleLabel.textAlignment = UITextAlignmentCenter;
    [headerView addSubview:buyButton];
    
    totalHeigth += 60;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.tag = 1003;
    titleLabel.textColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0];
    [titleLabel setLineBreakMode:UILineBreakModeWordWrap];
    [titleLabel setMinimumFontSize:16];
    [titleLabel setNumberOfLines:0];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
    titleLabel.backgroundColor = [UIColor clearColor];
    
    NSString *titleText = [productDetailData objectAtIndex:product_title];
    CGSize constraint3 = CGSizeMake(300, 20000.0f);
    CGSize size3 = [titleText sizeWithFont:[UIFont boldSystemFontOfSize:16] constrainedToSize:constraint3 lineBreakMode:UILineBreakModeWordWrap];
    float fixHeight2 = size3.height;
    fixHeight2 = fixHeight2 == 0 ? 10.f : fixHeight2;
    [titleLabel setText:titleText];
    [titleLabel setFrame:CGRectMake(MARGIN,  totalHeigth+8, 300, fixHeight2)];
    [headerView addSubview:titleLabel];
    [titleLabel release];
    
    totalHeigth += fixHeight2+4;
    
    UILabel *descLabel = nil;
    descLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    descLabel.tag = 1004;
    descLabel.textColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0];
    [descLabel setLineBreakMode:UILineBreakModeWordWrap];
    [descLabel setMinimumFontSize:14];
    [descLabel setNumberOfLines:0];
    [descLabel setFont:[UIFont systemFontOfSize:14]];
    descLabel.backgroundColor = [UIColor clearColor];
    
    NSString *text = [productDetailData objectAtIndex:product_content];
    CGSize constraint2 = CGSizeMake(300, 20000.0f);
    CGSize size2 = [text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:constraint2 lineBreakMode:UILineBreakModeWordWrap];
    float fixHeight = size2.height;
    fixHeight = fixHeight == 0 ? 10.f : fixHeight;
    [descLabel setText:text];
    [descLabel setFrame:CGRectMake(MARGIN,  totalHeigth+8, 300, fixHeight)];
    [headerView addSubview:descLabel];
    [descLabel release];
    
    totalHeigth += fixHeight+8*2;
    
    UIImageView *docImageview3 = [[UIImageView alloc] initWithFrame:CGRectMake(0, totalHeigth,docImage.size.width, 1)];
    docImageview3.image = docImage;
    [headerView addSubview:docImageview3];
    [docImageview3 release];
    
    UILabel *commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN, totalHeigth + 1,120,30)];
    commentLabel.backgroundColor = [UIColor clearColor];
    commentLabel.font = [UIFont boldSystemFontOfSize:14];
    commentLabel.textColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
    commentLabel.text = [NSString stringWithFormat:@"%@(%d)",@"用户评价",[[productDetailData objectAtIndex:product_comment_num] intValue]];
    commentLabel.textAlignment = UITextAlignmentLeft;
    [headerView addSubview:commentLabel];
    [commentLabel release];
    
    headerView.frame = CGRectMake(0, 0, 320, totalHeigth + 31);
    
    commentTableView.tableHeaderView = headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *cay = [commentArray objectAtIndex:[indexPath row]];
    NSString *text = [cay objectAtIndex:1];
    CGSize constraint = CGSizeMake(230, 20000.0f);
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
    float height = size.height < 20 ? 58.f : size.height + 30;
    //NSLog(@"height:%f",height);
    return height;

}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	
	//NSInteger row = [indexPath row];
	
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
        //cell.backgroundColor = [UIColor clearColor];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIImage *backImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"头像背景" ofType:@"png"]];
        UIImageView *headBackImageView = [[UIImageView alloc] initWithFrame: CGRectMake(3,3,52,52)];
        headBackImageView.tag = 303;
        headBackImageView.image = backImage;
        [backImage release];
        [cell.contentView addSubview:headBackImageView];
                
        UIImageView *headImageView = [[UIImageView alloc] initWithFrame: CGRectMake(6,6,40,40)];
        headImageView.tag = 203;
        [headBackImageView addSubview:headImageView];
        [headImageView release];
        [headBackImageView release];
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(8*2+52, 5, 120, 24)];
        nameLabel.text = @"";//[c_ay objectAtIndex:2];
        nameLabel.tag = 200;
        nameLabel.font = [UIFont systemFontOfSize:12];
        nameLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
        nameLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:nameLabel];
        [nameLabel release];
        
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(cell.frame.size.width-140, 5, 120, 24)];
        timeLabel.tag = 201;
        timeLabel.font = [UIFont systemFontOfSize:12];
        timeLabel.textAlignment = UITextAlignmentRight;
        timeLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
        timeLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:timeLabel];
        [timeLabel release];
    
        //UILabel *contentLabel = nil;
        UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        contentLabel.tag = 202;
        contentLabel.text = @"";
        contentLabel.textColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
        [contentLabel setLineBreakMode:UILineBreakModeWordWrap];
        [contentLabel setMinimumFontSize:14];
        [contentLabel setNumberOfLines:0];
        [contentLabel setFont:[UIFont systemFontOfSize:14]];
        contentLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:contentLabel];
        [contentLabel release];
    }
    
    if ([commentArray count] > 0) {
        NSArray *c_ay = [commentArray objectAtIndex:indexPath.row];
        UILabel *nameLabel = (UILabel*)[cell.contentView viewWithTag:200];
        UILabel *timeLabel = (UILabel*)[cell.contentView viewWithTag:201];
        UILabel *contentLabel = (UILabel*)[cell.contentView viewWithTag:202];
        UIImageView *headBackImageView = (UIImageView*)[cell viewWithTag:303];
        UIImageView *headImageView = (UIImageView*)[headBackImageView viewWithTag:203];
        
        NSString *headImageUrl = [c_ay objectAtIndex:3];
       
        NSString *picName = [Common encodeBase64:(NSMutableData *)[headImageUrl dataUsingEncoding: NSUTF8StringEncoding]];
        UIImage *headImage;
        if ([FileManager getPhoto:picName] != nil) {
            headImage = [FileManager getPhoto:picName];
        }else{
            headImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"默认头像" ofType:@"png"]];
            [self startIconDownload:headImageUrl forIndexPath:indexPath];
            
        }
        //图片圆形效果处理
        UIImage *image = [self circleImage:headImage withParam:0];
        headImageView.image = image;
        
        nameLabel.text = [c_ay objectAtIndex:2];
        //时间戳转化成时间
        int createTime = [[c_ay objectAtIndex:0] intValue];
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:createTime];
        NSDateFormatter *outputFormat = [[NSDateFormatter alloc] init];
        [outputFormat setDateFormat:@"YYYY-MM-dd"];
        NSString *dateString = [outputFormat stringFromDate:date];
        timeLabel.text = dateString;
        [outputFormat release];
        
        NSString *text = [c_ay objectAtIndex:1];
        CGSize constraint2 = CGSizeMake(230, 20000.0f);
        CGSize size2 = [text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:constraint2 lineBreakMode:UILineBreakModeWordWrap];
        float fixHeight = size2.height;
        fixHeight = fixHeight == 0 ? 10.f : fixHeight;
        [contentLabel setText:text];
        [contentLabel setFrame:CGRectMake(8*2+52, 25, 230, fixHeight)];
    
    }
	return cell;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
}

#pragma mark --- button 事件
- (void) handleEasyBuy:(id)sender{
    if (!_isLogin) {
        LoginViewController *login = [[LoginViewController alloc] init];
        login.delegate = self;
        [self.myNavigationController pushViewController:login animated:YES];
        [login release];
    }else{
        [self checkOnSubmit];
    }
}

- (void) goToEasyBuy{
    
    //判断是否有轻松购，有就下单，没有则走一般购物流程
    BOOL hasEasyLocal = NO;
    BOOL hasEasyServer = NO;
    NSArray *list = [DBOperate queryData:T_EASYBOOK_LIST theColumn:@"is_default" theColumnValue:@"1" withAll:NO];
    if (list != nil && [list count] > 0) {
        hasEasyLocal = YES;
    }
    
    NSArray *ay = [DBOperate queryData:T_SYSTEM_CONFIG theColumn:@"tag" theColumnValue:@"isEasybuy" withAll:NO];
    if (ay != nil && [ay count] > 0) {
        int temp = [[[ay objectAtIndex:0]objectAtIndex:system_config_value] intValue];
        if (temp != 0) {
            hasEasyServer = YES;
        }else{
            hasEasyServer = NO;
        }
    }
    if (hasEasyLocal) {
        NSArray *eay = [ay objectAtIndex:0];
        if ([[eay objectAtIndex:system_config_value] intValue] > 0) {
            //组装订单
            NSMutableArray *buyArray = [[NSMutableArray alloc] init];
            NSMutableArray *buy_product = [[NSMutableArray alloc] init];
            [buy_product addObject:[productDetailData objectAtIndex:product_id]];
            [buy_product addObject:[NSNumber numberWithInt:1]];
            [buy_product addObject:[productDetailData objectAtIndex:product_price]];
            [buy_product addObject:[productDetailData objectAtIndex:product_promotion_price]];
            [buy_product addObject:[productDetailData objectAtIndex:product_title]];
            [buy_product addObject:[productDetailData objectAtIndex:product_pic]];
            [buy_product addObject:[NSNumber numberWithInt:1]];
            [buyArray addObject:buy_product];
            [buy_product release];
            
            //跳转至订单页面
            SubmitOrderViewController *sc = [[SubmitOrderViewController alloc] init];
            sc.shopArray = buyArray;
            if ([[productDetailData objectAtIndex:product_promotion_price]intValue] > 0) {
                sc.totalMoney = [[productDetailData objectAtIndex:product_promotion_price] doubleValue] - promotionMoney;
                sc.totalPrice = [NSString stringWithFormat:@"￥ %.2f",[[productDetailData objectAtIndex:product_promotion_price]doubleValue] - promotionMoney];
            }else{
                sc.totalMoney = [[productDetailData objectAtIndex:product_price]doubleValue] - promotionMoney;
                sc.totalPrice = [NSString stringWithFormat:@"￥ %.2f",[[productDetailData objectAtIndex:product_price]doubleValue] - promotionMoney];
            }
            
            double save;
            if ([[productDetailData objectAtIndex:product_promotion_price]intValue] > 0) {
                save = [[productDetailData objectAtIndex:product_price]doubleValue] - [[productDetailData objectAtIndex:product_promotion_price]doubleValue];
            }else{
                save = 0.00;
            }
            //NSLog(@"save:%f",save);
            sc.savePrice = [NSString stringWithFormat:@"%.2f",save];
            sc.isEasyBuy = YES;
            sc.fullSendID = fullSendID;
            sc.promotionMoney = promotionMoney;
            [self.myNavigationController pushViewController:sc animated:YES];
            [buyArray release];
            [sc release];
        }else{
            if (hasEasyServer) {
                [self accessEasyListService];
            }else{//去到轻松购添加页面添加轻松购
                AddOrEditReservationViewController *arvc = [[AddOrEditReservationViewController alloc] init];
                arvc.delegate = self;
                [self.myNavigationController pushViewController:arvc animated:YES];
                [arvc release];
            }
        }
    }else{
        if (hasEasyServer) {
            [self accessEasyListService];
        }else{//去到轻松购添加页面添加轻松购
            AddOrEditReservationViewController *arvc = [[AddOrEditReservationViewController alloc] init];
            arvc.delegate = self;
            [self.myNavigationController pushViewController:arvc animated:YES];
            [arvc release];
        }
    }
    
}

#pragma mark 登录接口回调
- (void)loginWithResult:(BOOL)isLoginSuccess{
    
	if (isLoginSuccess)
    {
        [self performSelector:@selector(checkOnSubmit) withObject:nil afterDelay:0.5f];
	}
}

- (void)accessEasyListService
{
    progressHUD = [[MBProgressHUD alloc] initWithView:self];
    progressHUD.labelText = @"云端同步中...";
    [self addSubview:progressHUD];
    [self bringSubviewToFront:progressHUD];
    [progressHUD show:YES];
    
     int _userId = [[[[DBOperate queryData:T_MEMBER_INFO theColumn:nil theColumnValue:nil withAll:YES] objectAtIndex:0] objectAtIndex:member_info_memberId] intValue];
    
    NSMutableDictionary *jsontestDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        [Common getSecureString],@"keyvalue",
                                        [Common getMemberVersion:_userId commandID:EASYLIST_COMMAND_ID],@"ver",
                                        [NSNumber numberWithInt: SITE_ID],@"site_id",
                                        [NSNumber numberWithInt:_userId],@"user_id",nil];
    
    [[DataManager sharedManager] accessService:jsontestDic command:EASYLIST_COMMAND_ID accessAdress:@"book/easylist.do?param=%@" delegate:self withParam:jsontestDic];
}

#pragma mark AddOrEditReservationDelegate
- (void) finishEdit{
    [self accessEasyListService];
}

- (void) toSubbmitOrderView{
    if (progressHUD != nil) {
        if (progressHUD) {
            [progressHUD hide:YES];
            [progressHUD removeFromSuperViewOnHide];
        }
    }
    //组装订单
    NSMutableArray *buyArray = [[NSMutableArray alloc] init];
    NSMutableArray *buy_product = [[NSMutableArray alloc] init];
    [buy_product addObject:[productDetailData objectAtIndex:product_id]];
    [buy_product addObject:[NSNumber numberWithInt:1]];
    [buy_product addObject:[productDetailData objectAtIndex:product_price]];
    [buy_product addObject:[productDetailData objectAtIndex:product_promotion_price]];
    [buy_product addObject:[productDetailData objectAtIndex:product_title]];
    [buy_product addObject:[productDetailData objectAtIndex:product_pic]];
    [buy_product addObject:[NSNumber numberWithInt:1]];
    [buyArray addObject:buy_product];
    [buy_product release];
    
    //跳转至订单页面
    SubmitOrderViewController *sc = [[SubmitOrderViewController alloc] init];
    sc.shopArray = buyArray;
    if ([[productDetailData objectAtIndex:product_promotion_price]intValue] > 0) {
        sc.totalMoney = [[productDetailData objectAtIndex:product_promotion_price] doubleValue] - promotionMoney;
        sc.totalPrice = [NSString stringWithFormat:@"￥ %.2f",[[productDetailData objectAtIndex:product_promotion_price]doubleValue]];
    }else{
        sc.totalMoney = [[productDetailData objectAtIndex:product_price]doubleValue] - promotionMoney;
        sc.totalPrice = [NSString stringWithFormat:@"￥ %.2f",[[productDetailData objectAtIndex:product_price]doubleValue]];
    }
    
    double save;
    if ([[productDetailData objectAtIndex:product_promotion_price]intValue] > 0) {
        save = [[productDetailData objectAtIndex:product_price]doubleValue] - [[productDetailData objectAtIndex:product_promotion_price]doubleValue];
    }else{
        save = 0.00;
    }
    
    //NSLog(@"save:%f",save);
    sc.savePrice = [NSString stringWithFormat:@"%.2f",save];
    sc.isEasyBuy = YES;
    sc.fullSendID = fullSendID;
    sc.promotionMoney = promotionMoney;
    [self.myNavigationController pushViewController:sc animated:YES];
    [buyArray release];
    [sc release];
}

- (void) handleAddToCar:(id)sender{
    //购物车中还没有此商品
    NSArray *ay = [DBOperate queryData:T_SHOPCAR theColumn:@"product_id" theColumnValue:[productDetailData objectAtIndex:product_id] withAll:NO];
    BOOL flag = NO;
        
    if(ay != nil && [ay count] > 0)
    {
        NSArray *car_ay = [ay objectAtIndex:0];
        int preCount = [[car_ay objectAtIndex:shopcar_product_count] intValue];
        if(preCount > 0){
            if (preCount + 1 < [[productDetailData objectAtIndex:product_sum] intValue]) {
                flag = [DBOperate updateData:T_SHOPCAR tableColumn:@"product_count" columnValue:[NSString stringWithFormat:@"%d",preCount+1] conditionColumn:@"product_id" conditionColumnValue:[productDetailData objectAtIndex:product_id]];

            }else if(preCount + 1 == [[productDetailData objectAtIndex:product_sum] intValue]){
                flag = [DBOperate updateData:T_SHOPCAR tableColumn:@"product_count" columnValue:[NSString stringWithFormat:@"%d",preCount+1] conditionColumn:@"product_id" conditionColumnValue:[productDetailData objectAtIndex:product_id]];
                
                [buyButton setTitle:@"加入购物车" forState:UIControlStateNormal];
                
                UIImage *image = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"产品线详情灰色按钮" ofType:@"png"]];
                [buyButton setTitle:@"加入购物车" forState:UIControlStateNormal];
                [buyButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
                [easyBuy setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
                [buyButton setBackgroundImage:image forState:UIControlStateNormal];
                [easyBuy setBackgroundImage:image forState:UIControlStateNormal];
                buyButton.userInteractionEnabled = NO;
                easyBuy.userInteractionEnabled = NO;
                [image release];
            }
        }        
    }else{
        NSMutableArray *buy_product = [[NSMutableArray alloc] init];
        [buy_product addObject:[productDetailData objectAtIndex:product_id]];
        [buy_product addObject:[NSNumber numberWithInt:1]];
        [buy_product addObject:[productDetailData objectAtIndex:product_price]];
        [buy_product addObject:[productDetailData objectAtIndex:product_promotion_price]];
        [buy_product addObject:[productDetailData objectAtIndex:product_title]];
        [buy_product addObject:[productDetailData objectAtIndex:product_pic]];
        [buy_product addObject:[NSNumber numberWithInt:1]];
        [buy_product addObject:[productDetailData objectAtIndex:product_sum]];
        flag = [DBOperate insertDataWithnotAutoID:buy_product tableName:T_SHOPCAR];
        [buy_product release];
        //如果库存只有一件，按钮至灰,不可再购
        if ([[productDetailData objectAtIndex:product_sum] intValue] == 1) {
            [buyButton setTitle:@"加入购物车" forState:UIControlStateNormal];
            
            UIImage *image = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"产品线详情灰色按钮" ofType:@"png"]];
            [buyButton setTitle:@"加入购物车" forState:UIControlStateNormal];
            [buyButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [easyBuy setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [buyButton setBackgroundImage:image forState:UIControlStateNormal];
            [easyBuy setBackgroundImage:image forState:UIControlStateNormal];
            buyButton.userInteractionEnabled = NO;
            easyBuy.userInteractionEnabled = NO;
            [image release];
        }
    }
    //添加成功询问用户是否去结算
    if (flag) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil message:@"添加成功! \n 商品已成功加入购物车" delegate:self cancelButtonTitle:@"去购物车" otherButtonTitles:@"再逛逛",nil];
        [av show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 0)
    {
        
        NSArray *arrayViewControllers = self.myNavigationController.viewControllers;
        if ([[arrayViewControllers objectAtIndex:0] isKindOfClass:[CustomTabBar class]])
        {
            [self.myNavigationController popToRootViewControllerAnimated:NO];
            CustomTabBar *tabViewController = [arrayViewControllers objectAtIndex:0];
            tabViewController.selectedIndex = 2;
            
            UIButton *btn = (UIButton *)[tabViewController.view viewWithTag:90002];
            
            [tabViewController selectedTab:btn];
        }
        else
        {
            [self.myNavigationController popToRootViewControllerAnimated:NO];
            tabEntranceViewController *tabViewController = [arrayViewControllers objectAtIndex:0];
            tabViewController.selectedIndex = 2;
            
            [tabViewController tabBarController:tabViewController didSelectViewController:tabViewController.selectedViewController];
        }
        
    }
    else if(buttonIndex == 1)
    {
        
    }
    
}

#pragma mark ScrollViewDelegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!isLoadingMore && canLoadMore) {
        CGFloat scrollPosition = scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y;
        if (scrollPosition < 15){
            [self loadMore];
        }
    }
}

- (BOOL) loadMore
{
    if (isLoadingMore)
        return NO;
    [self willBeginLoadingMore];
    isLoadingMore = YES;
    return YES;
}

- (void) willBeginLoadingMore{
    [footerView.activityIndicator startAnimating];
    //请求更多评论数据,评论列表中索引为0的存储评论时间戳
    int created = [[[self.commentArray lastObject] objectAtIndex:0] intValue];
    int pid = [[productDetailData objectAtIndex:product_id] intValue];
	NSMutableDictionary *jsontestDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        [Common getSecureString],@"keyvalue",
                                        [NSNumber numberWithInt: SITE_ID],@"site_id",
                                        [NSNumber numberWithInt:pid],@"id",
                                        [NSNumber numberWithInt:0],@"type",
                                        [NSNumber numberWithInt:created],@"created",
                                        nil];
	
	[[DataManager sharedManager] accessService:jsontestDic command:PRODUCT_COMMENTLIST_COMMAND_ID accessAdress:@"comment/list.do?param=%@" delegate:self withParam:jsontestDic];
    
}

- (void) loadMoreCompleted:(NSMutableArray*)array
{
    if (array != nil && [array count] > 0) {
        [commentArray addObjectsFromArray:array];
        isLoadingMore = NO;
        [footerView.activityIndicator stopAnimating];
        [commentTableView reloadData];
    }else{
        footerView.infoLabel.hidden = NO;
        footerView.infoLabel.text = @"";
        [footerView.activityIndicator stopAnimating];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView{
    CGPoint offset = aScrollView.contentOffset;
	pageControl.currentPage = offset.x / self.frame.size.width;
    ccindex = pageControl.currentPage;
}

#pragma mark --- 获取网络图片
//获取网络图片
- (void)startIconDownload:(NSString*)photoURL forIndexPath:(NSIndexPath*)indexPath
{
    IconDownLoader *iconDownloader = [self.imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil && photoURL != nil && photoURL.length > 1)
    {
		if ([self.imageDownloadsInProgress count]>= 2) {
			imageDownLoadInWaitingObject *one = [[imageDownLoadInWaitingObject alloc]init:photoURL withIndexPath:indexPath withImageType:CUSTOMER_PHOTO];
			[self.imageDownloadsInWaiting addObject:one];
			[one release];
			return;
		}
        IconDownLoader *iconDownloader = [[IconDownLoader alloc] init];
        iconDownloader.downloadURL = photoURL;
        iconDownloader.indexPathInTableView = indexPath;
		iconDownloader.imageType = CUSTOMER_PHOTO;
        iconDownloader.delegate = self;
        [self.imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload];
        [iconDownloader release];
    }
}

//回调 获到网络图片后的回调函数
- (void)appImageDidLoad:(NSIndexPath *)indexPath withImageType:(int)Type
{
    int index = [indexPath row];
    IconDownLoader *iconDownloader = [self.imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader != nil)
    {
        // Display the newly loaded image
		if(iconDownloader.cardIcon.size.width>2.0)
		{
            if (index >= 150) {
                //保存图片
                if (productPicArray != nil  && [productPicArray count] > 0 && index-150 < [productPicArray count]) {
                    NSArray *pic_thrum_ay = [productPicArray objectAtIndex:index-150];
                    NSString *imageUrl = [pic_thrum_ay objectAtIndex:product_pic_pic];
                    NSString *picName = [Common encodeBase64:(NSMutableData *)[imageUrl dataUsingEncoding: NSUTF8StringEncoding]];
                    [FileManager savePhoto:picName withImage:iconDownloader.cardIcon];
                    
                    myImageView *iv = (myImageView*)[imageScrollView viewWithTag:(index)];
                    iv.image =  iconDownloader.cardIcon;
                }
            }else{
                UITableViewCell *cell = (UITableViewCell *)[commentTableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
                NSArray *cay = [commentArray objectAtIndex:index];
                //cay是单条评论列表数据，数组3位置放的是评论用户头像地址
                NSString *imageUrl;
                if (cay != nil && [cay count] > 0) {
                   imageUrl = [cay objectAtIndex:3];
                    NSString *picName = [Common encodeBase64:(NSMutableData *)[imageUrl dataUsingEncoding: NSUTF8StringEncoding]];
                    [FileManager savePhoto:picName withImage:iconDownloader.cardIcon];
                    UIImage *headImage = [self circleImage:iconDownloader.cardIcon withParam:0];
                    
                    UIImageView *headBackImageView = (UIImageView*)[cell viewWithTag:303];
                    UIImageView *headImageView = (UIImageView*)[headBackImageView viewWithTag:203];
                    headImageView.image = headImage;
                }                
            }
		}
		
		[self.imageDownloadsInProgress removeObjectForKey:indexPath];
		if ([self.imageDownloadsInWaiting count]>0)
		{
			imageDownLoadInWaitingObject *one = [self.imageDownloadsInWaiting objectAtIndex:0];
			[self startIconDownload:one.imageURL forIndexPath:one.indexPath];
			[self.imageDownloadsInWaiting removeObjectAtIndex:0];
		}
		
    }
}

#pragma mark -
#pragma mark 图片委托
- (void)imageViewTouchesEnd:(NSString*)picId{
    picDetailViewController *picDetail = [[picDetailViewController alloc] init];
	picDetail.picArray = (NSMutableArray*)productPicArray;
	picDetail.chooseIndex = [picId intValue];
	[self.myNavigationController pushViewController:picDetail animated:YES];
	[picDetail release];
	
}

//图片裁剪成圆形
-(UIImage*) circleImage:(UIImage*) image withParam:(CGFloat) inset {
    UIGraphicsBeginImageContext(image.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2);
    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
//    CGRect rect = CGRectMake(inset, inset, image.size.width - inset * 2.0f, image.size.height - inset * 2.0f);
    CGRect rect = CGRectMake(inset, inset, image.size.width, image.size.height);
    CGContextAddEllipseInRect(context, rect);
    CGContextClip(context);
    
    [image drawInRect:rect];
    CGContextAddEllipseInRect(context, rect);
    CGContextStrokePath(context);
    UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newimg;
}

//提交订单前check订单是都满足满送活动
- (void) checkOnSubmit{
    //所有促销的列表
    NSArray *ayArray = [DBOperate queryData:T_FULL_PROMOTION theColumn:nil theColumnValue:nil orderBy:@"total" orderType:@"desc" withAll:YES];
    //isDisCount为TRUE时为打折，为NO是立减
    BOOL isDisCount = NO;
    //记录多余1条，肯定是立减活动
    if ([ayArray count] > 1) {
        isDisCount = NO;
    }else if([ayArray count] == 1){
        int type = [[[ayArray objectAtIndex:0] objectAtIndex:fullpromotion_type] intValue];
        //type为1时,优惠活动是打折
        if (type == 1) {
            isDisCount = YES;
        }else{
            isDisCount = NO;
        }
    }
    if ([ayArray count] > 0) {
        NSArray *ay = nil;
        //是否直接减掉促销价格或打折
        BOOL flag = NO;
        for (int i = 0; i < [ayArray count]; i++) {
            ay = [ayArray objectAtIndex:i];
            if (totalMoney >= [[ay objectAtIndex:fullpromotion_total] doubleValue]) {
                //总价钱落在那个区间，直接减掉促销的金额
                flag = YES;
                break;
            }else{
                ay = nil;
            }
        }
        if (ay == nil) {
            ay = [ayArray lastObject];
            //需要再判断订单金额是否达到促销的百分点，弹出加单提示框
            flag = NO;
        }
        
        int startTime = [[ay objectAtIndex:fullpromotion_startTime] intValue];
        int endTime = [[ay objectAtIndex:fullpromotion_endTime] intValue];
        
        NSDate* nowDate = [NSDate date];
        NSDateFormatter *outputFormat = [[NSDateFormatter alloc] init];
        [outputFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *dateString = [outputFormat stringFromDate:nowDate];
        NSDate *currentDate = [outputFormat dateFromString:dateString];
        [outputFormat release];
        NSTimeInterval t = [currentDate timeIntervalSince1970];   //转化为时间戳
        long long int ttime = (long long int)t;
        NSNumber *num = [NSNumber numberWithLongLong:ttime];
        int currentInt = [num intValue];
        
        if (currentInt >= startTime && currentInt <= endTime) {
            if (flag) {
                if (isDisCount) {//打折优惠活动
                    double preTotal = totalMoney;
                    totalMoney = preTotal * [[ay objectAtIndex:fullpromotion_price] doubleValue] / 10;
                    promotionMoney = preTotal - totalMoney;
                }else{//后台设置是立减优惠活动
                    promotionMoney = [[ay objectAtIndex:fullpromotion_price] doubleValue];
                    totalMoney -= promotionMoney;
                }
                fullSendID = [[ay objectAtIndex:fullpromotion_fid] intValue];
                [self goToEasyBuy];
            }else{
                double priceInt = [[ay objectAtIndex:fullpromotion_total] doubleValue];
                
                double value = totalMoney;
                
                if (value >= priceInt * promotionPercent && value < priceInt) {
                    //添加到购物车的时候判断是否弹出优惠框提示加单
//                    NSString *valueStr = [NSString stringWithFormat:@"%.2f",priceInt - value];
//                    
//                    UIWindow *window = [UIApplication sharedApplication].keyWindow;
//                    if (!window)
//                    {
//                        window = [[UIApplication sharedApplication].windows objectAtIndex:0];
//                    }
//                    
//                    PromotionAlertView *shareAlertView = [[[PromotionAlertView alloc] initWithFrame:window.bounds withTotal:[NSString stringWithFormat:@"%.0f",value] withPrice:valueStr withName:[[ayArray objectAtIndex:0] objectAtIndex:fullpromotion_name]] autorelease];
//                    shareAlertView._delegate = self;
//                    [window addSubview:shareAlertView];
//                    [shareAlertView showFromPoint:[window center]];
                    [self goToEasyBuy];
                }else if (value > priceInt){
                    [self goToEasyBuy];
                }else {
                    [self goToEasyBuy];
                }
            }
            
        }else {
            [DBOperate deleteData:T_FULL_PROMOTION];
            [self goToEasyBuy];
        }
    }else{
        [self goToEasyBuy];
    }
}

#pragma mark -----PromotionAlertViewDelegate method
- (void)leftGoOnAction
{
    NSArray *arrayViewControllers = self.myNavigationController.viewControllers;
    if ([[arrayViewControllers objectAtIndex:0] isKindOfClass:[CustomTabBar class]])
    {
        CustomTabBar *tabViewController = [arrayViewControllers objectAtIndex:0];
        tabViewController.selectedIndex = 1;
        
        UIButton *btn = (UIButton *)[tabViewController.view viewWithTag:90001];
        [tabViewController selectedTab:btn];
    }
    else
    {
        tabEntranceViewController *tabViewController = [arrayViewControllers objectAtIndex:0];
        tabViewController.selectedIndex = 0;
        
        [tabViewController tabBarController:tabViewController didSelectViewController:tabViewController.selectedViewController];
    }
    
    [self.myNavigationController popToRootViewControllerAnimated:NO];
}

- (void)rightFinishAction
{
    [self goToEasyBuy];
}

@end