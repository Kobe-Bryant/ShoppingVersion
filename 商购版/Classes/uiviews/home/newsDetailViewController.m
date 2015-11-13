//
//  newsDetailViewController.m
//  newsDetail
//
//  Created by MC374 on 12-8-21.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "newsDetailViewController.h"
#import "HPGrowingTextView.h"
#import "MBProgressHUD.h"
#import "alertView.h"
#import "manageActionSheet.h"
#import "IconDownLoader.h"
#import "FileManager.h"
#import "callSystemApp.h"
#import "downloadParam.h"
#import "DBOperate.h"
#import "Common.h"
#import "DataManager.h"
#import "ShareToBlogViewController.h"
#import "weiboSetViewController.h"
#import "LoginViewController.h"
#import "newsCommentViewController.h"
#import "UIImageScale.h"
#import "WXApi.h"
#import "WXApiObject.h"
#import "SendMsgToWeChat.h"

@implementation newsDetailViewController
@synthesize isFavorite;
@synthesize actionSheet;
@synthesize iconDownLoad;
@synthesize detailArray;
@synthesize totalheight;
@synthesize userId;
@synthesize operateType;
@synthesize textView;
@synthesize tempTextContent;
@synthesize commentTotal;
@synthesize isFrom;
@synthesize barbutton;
@synthesize newsId;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization.
 }
 return self;
 }
 */

-(id)init
{
	self = [super init];
	if(self)
	{
		//注册键盘通知
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(keyboardWillShow:) 
													 name:UIKeyboardWillShowNotification 
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(keyboardWillHide:) 
													 name:UIKeyboardWillHideNotification 
												   object:nil];		
	}
	
	return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"详细新闻";
    
    self.tempTextContent = @"";
	
	self.view.backgroundColor = [UIColor whiteColor];
    
    if ([detailArray count] == 0 && self.newsId != nil) {
        [self accessService];
    }else {
        [self update:detailArray];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    //获取当前用户的user_id
	NSMutableArray *memberArray = (NSMutableArray *)[DBOperate queryData:T_MEMBER_INFO theColumn:@"" theColumnValue:@"" withAll:YES];
	if ([memberArray count] > 0) 
	{
		self.userId = [[memberArray objectAtIndex:0] objectAtIndex:member_info_memberId];
	}
	else 
	{
		self.userId = @"0";
	}
	
    //判断该信息是否为当前用户收藏
	NSMutableArray *favorite = (NSMutableArray *)[DBOperate 
												  queryData:T_FAVORITED_NEWS theColumn:@"news_id" 
												  equalValue:[NSString stringWithFormat:@"%d",[[detailArray objectAtIndex:news_id] intValue]] 
												  theColumn:@"user_id" equalValue:userId];
    
    NSMutableArray *favoriteNew = (NSMutableArray *)[DBOperate queryData:T_FAVORITE_NEWS theColumn:@"id" theColumnValue:[NSString stringWithFormat:@"%d",[[detailArray objectAtIndex:favoritenews_id] intValue]] withAll:NO];
	
	if ([favorite count] > 0 || [favoriteNew count] > 0)
	{
		//已收藏
		isFavorite = YES;
	}
	else 
	{
        //没有收藏
		isFavorite = NO;
	}
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations.
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    
	[contentScrollView release];
	[containerView release];
	[textView release];
	[actionSheet release];
	[iconDownLoad release];
	[newsImageView release];
	[detailArray release];
	[userId release];
    [barbutton release];
    [super dealloc];
}

- (void) addButtomBar{

	containerView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(contentScrollView.frame), 320, 40)];
    
	textView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(6, 3, 235, 40)];
    textView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
    
	textView.minNumberOfLines = 1;
	textView.maxNumberOfLines = 3;
	textView.returnKeyType = UIReturnKeyDefault; //just as an example
	textView.font = [UIFont systemFontOfSize:15.0f];
    textView.textColor = [UIColor grayColor]; 
	textView.delegate = self;
    textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    textView.backgroundColor = [UIColor whiteColor];
    textView.text = @"我也说一句";
    
    // textView.text = @"test\n\ntest";
	// textView.animateHeightChange = NO; //turns off animation
	
    [self.view addSubview:containerView];
	
    UIImage *rawEntryBackground = [UIImage imageNamed:@"MessageEntryInputField.png"];
    UIImage *entryBackground = [rawEntryBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
    UIImageView *entryImageView = [[[UIImageView alloc] initWithImage:entryBackground] autorelease];
    entryImageView.frame = CGRectMake(5, 0, 240, 40);
    entryImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    entryImageView.tag = 2000;
	
    UIImage *rawBackground = [UIImage imageNamed:@"MessageEntryBackground.png"];
    UIImage *background = [rawBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
    UIImageView *imageView = [[[UIImageView alloc] initWithImage:background] autorelease];
    imageView.frame = CGRectMake(0, 0, containerView.frame.size.width, containerView.frame.size.height);
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // view hierachy
    [containerView addSubview:imageView];
    [containerView addSubview:textView];
    [containerView addSubview:entryImageView];
	
    //收藏按钮
	UIImageView *favoriteButton = [[UIImageView alloc]initWithFrame:CGRectMake(275.0f, 0.0f, 40.0f, 40.0f)];
	
	if (isFavorite) 
	{
		favoriteButton.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"已收藏按钮" ofType:@"png"]];
		favoriteButton.tag = 2002;
	}
	else
	{
		favoriteButton.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"收藏按钮" ofType:@"png"]];
		favoriteButton.tag = 2002;
		
		//绑定点击事件
		favoriteButton.userInteractionEnabled = YES;
		UITapGestureRecognizer *favoriteSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(favorite)];
		[favoriteButton addGestureRecognizer:favoriteSingleTap];
		[favoriteSingleTap release];
	}
	
	[containerView addSubview:favoriteButton];
	[favoriteButton release];
	
	//分享按钮
	UIImageView *shareButton = [[UIImageView alloc]initWithFrame:CGRectMake(240.0f, 0.0f, 40.0f, 40.0f)];
	shareButton.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"分享按钮" ofType:@"png"]];
	shareButton.tag = 2001;
	
	//绑定点击事件
	shareButton.userInteractionEnabled = YES;
	UITapGestureRecognizer *shareSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(share)];
	[shareButton addGestureRecognizer:shareSingleTap];
	[shareSingleTap release];
	
	[containerView addSubview:shareButton];
	[shareButton release];
	
	//字数统计
	UILabel *remainCountLabel = [[UILabel alloc]initWithFrame:CGRectMake(265.0f, 5.0f, 50.0f, 20.0f)];
	[remainCountLabel setFont:[UIFont systemFontOfSize:12.0f]];
	remainCountLabel.textColor = [UIColor colorWithRed:0.5 green: 0.5 blue: 0.5 alpha:1.0];
	remainCountLabel.tag = 2004;
	remainCountLabel.text = @"140/140";
	remainCountLabel.hidden = YES;
	remainCountLabel.backgroundColor = [UIColor clearColor];
	remainCountLabel.lineBreakMode = UILineBreakModeWordWrap | UILineBreakModeTailTruncation;
	remainCountLabel.textAlignment = UITextAlignmentCenter;
	[containerView addSubview:remainCountLabel];
	[remainCountLabel release];
	
	//添加发送按钮
	UIImage *sendBtnBackground = [[UIImage imageNamed:@"MessageEntrySendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
	UIImage *selectedSendBtnBackground = [[UIImage imageNamed:@"MessageEntrySendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
	
	UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	sendBtn.frame = CGRectMake(containerView.frame.size.width - 55, 8, 50, 27);
	sendBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
	[sendBtn setTitle:@"评论" forState:UIControlStateNormal];
	[sendBtn setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.4] forState:UIControlStateNormal];
	sendBtn.titleLabel.shadowOffset = CGSizeMake (0.0, -1.0);
	sendBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
	sendBtn.tag = 2003;
	sendBtn.hidden = YES;
	[sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[sendBtn addTarget:self action:@selector(publishComment:) forControlEvents:UIControlEventTouchUpInside];
	[sendBtn setBackgroundImage:sendBtnBackground forState:UIControlStateNormal];
	[sendBtn setBackgroundImage:selectedSendBtnBackground forState:UIControlStateSelected];
	[containerView addSubview:sendBtn];
	
	[self.view addSubview:containerView];
}

- (void)update:(NSMutableArray *)array {
    [self addToHistory:array];
    
    if (self.newsId != nil) {
        contentScrollView = [[UIScrollView alloc] initWithFrame:
                             CGRectMake(0, 0, 320, VIEW_HEIGHT - 20.0f - 40.0f)];
    }else {
        contentScrollView = [[UIScrollView alloc] initWithFrame:
                             CGRectMake(0, 0, 320, VIEW_HEIGHT - 20.0f - 44.0f - 40.0f)];
    }
    
	contentScrollView.pagingEnabled = NO;
	contentScrollView.delegate = self;
    contentScrollView.backgroundColor = [UIColor clearColor];
	contentScrollView.showsHorizontalScrollIndicator = NO;
	contentScrollView.showsVerticalScrollIndicator = YES;
	[self.view addSubview:contentScrollView];
	
    //标题
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	titleLabel.backgroundColor = [UIColor clearColor];
	[titleLabel setLineBreakMode:UILineBreakModeWordWrap];
	titleLabel.font = [UIFont systemFontOfSize:20];
	[titleLabel setNumberOfLines:0];
	titleLabel.textAlignment = UITextAlignmentCenter;
	NSString *titletext = [array objectAtIndex:news_title];
	CGSize titleconstraint = CGSizeMake(300, 20000.0f);
	CGSize titlesize = [titletext sizeWithFont:[UIFont systemFontOfSize:20] constrainedToSize:titleconstraint lineBreakMode:UILineBreakModeWordWrap];
	[titleLabel setText:titletext];
	titleLabel.textColor = [UIColor blackColor];
	titleLabel.frame = CGRectMake(10, 10, 300, MAX(titlesize.height, 40.0f));
	[contentScrollView addSubview:titleLabel];
	[titleLabel release];
	
	totalheight = titleLabel.frame.size.height;
	
    //时间
    UILabel *timelabel = [[UILabel alloc]
                          initWithFrame:CGRectMake(60, totalheight + 14, 200, 20)];
    timelabel.textAlignment = UITextAlignmentCenter;
    timelabel.textColor = [UIColor grayColor];
    timelabel.backgroundColor = [UIColor clearColor];
    timelabel.font = [UIFont systemFontOfSize:14];
    [contentScrollView addSubview:timelabel];
    [timelabel release];
    
    totalheight += 14+20;
    
    if ([[array objectAtIndex:news_updatetime] intValue] != 0) {
        int createTime = [[array objectAtIndex:news_updatetime] intValue];
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:createTime];
        NSDateFormatter *outputFormat = [[NSDateFormatter alloc] init];
        //[outputFormat setTimeZone:[NSTimeZone timeZoneWithName:@"H"]];
        [outputFormat setDateFormat:@"YYYY-MM-dd"];
        NSString *dateString = [outputFormat stringFromDate:date];
        timelabel.text = [NSString stringWithFormat:@"%@ %@",@"更新时间:",dateString];
        [outputFormat release];
    }else {
        timelabel.text = @"";
    }
    
    //线
	UIImageView *seplineview = [[UIImageView alloc]
								initWithFrame:CGRectMake(0,totalheight+13, 320, 2)];
	UIImage *sepimg = [[UIImage alloc]initWithContentsOfFile:
					   [[NSBundle mainBundle] pathForResource:@"线" ofType:@"png"]];
	seplineview.image = sepimg;
	[sepimg release];
	[contentScrollView addSubview:seplineview];
	[seplineview release];
	
	totalheight += 15;
	
    //图片
	newsImageView = [[UIImageView alloc]
                     initWithFrame:CGRectMake(20,totalheight+15, 280,205)];
	[contentScrollView addSubview:newsImageView];
    
    NSString *picUrl = [array objectAtIndex:news_recommend_img];
    NSString *picName = [Common encodeBase64:(NSMutableData *)[picUrl dataUsingEncoding: NSUTF8StringEncoding]];
	UIImage *img = [FileManager getPhoto:picName];
	if (img.size.width > 2)
    {
		newsImageView.image = [img fillSize:CGSizeMake(280,205)];
	}
    else
    {
        UIImage *newsimage = [[UIImage alloc]initWithContentsOfFile:
                              [[NSBundle mainBundle] pathForResource:@"活动资讯详情默认" ofType:@"png"]];
        [newsImageView setImage:newsimage];
        [newsimage release];
        
		if (picUrl.length > 0)
        {
			[self startIconDownload:picUrl forIndex:[NSIndexPath indexPathForRow:0 inSection:0]];
		}
	}
	
	totalheight += 220; // 15 + 205
	
    //描述
	descLable = [[UILabel alloc] initWithFrame:CGRectZero];
	descLable.backgroundColor = [UIColor clearColor];
	[descLable setLineBreakMode:UILineBreakModeWordWrap];
	[descLable setNumberOfLines:0];
	descLable.font = [UIFont systemFontOfSize:14];
	NSString *descText = [NSString stringWithFormat:@"%@%@",@"    ",[array objectAtIndex:news_content]];
	CGSize constraint = CGSizeMake(280, 20000.0f);
	CGSize size = [descText sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
	[descLable setText:descText];
	descLable.textColor = [UIColor blackColor];
	[descLable setFrame:CGRectMake(20, totalheight + 15, 280, MAX(size.height, 44.0f))];
	[contentScrollView addSubview:descLable];
	
	totalheight += 30 + descLable.frame.size.height;
    
	contentScrollView.contentSize = CGSizeMake(320,totalheight);
	
	//获取当前用户的user_id
	NSMutableArray *memberArray = (NSMutableArray *)[DBOperate queryData:T_MEMBER_INFO theColumn:@"" theColumnValue:@"" withAll:YES];
	if ([memberArray count] > 0)
	{
		self.userId = [[memberArray objectAtIndex:0] objectAtIndex:member_info_memberId];
	}
	else
	{
		self.userId = @"0";
	}
	
	//判断该信息是否为当前用户收藏
	NSMutableArray *favorite = (NSMutableArray *)[DBOperate
												  queryData:T_FAVORITED_NEWS theColumn:@"news_id"
												  equalValue:[NSString stringWithFormat:@"%d",[[array objectAtIndex:news_id] intValue]]
												  theColumn:@"user_id" equalValue:userId];
	
	if (favorite == nil || ![favorite count] > 0)
	{
		//没有收藏
		isFavorite = NO;
	}
	else
	{
		//已收藏
		isFavorite = YES;
	}
	
	//添加底部工具栏
	[self addButtomBar];
    
    NSString *_newsId = [NSString stringWithFormat:@"%d",[[array objectAtIndex:0] intValue]];
    NSArray *commentArray = [DBOperate queryData:T_HISTORY_NEW theColumn:@"id" theColumnValue:_newsId withAll:NO];
    NSLog(@"comment ----%@",commentArray);

    NSLog(@"commentArray ----%@",[[commentArray objectAtIndex:0] objectAtIndex:4]);
    NSString *str = nil;
    if (commentArray.count > 0) {
       
        str = [NSString stringWithFormat:@"%@评论",[[commentArray objectAtIndex:0] objectAtIndex:4]];
    } else {
        str = [NSString stringWithFormat:@"评论"];

    }
    barbutton = [[UIBarButtonItem alloc]
                 initWithTitle:str
                 style:UIBarButtonItemStyleBordered
                 target:self action:@selector(commentListAction)];
    self.navigationItem.rightBarButtonItem = barbutton;
}

- (void)addToHistory:(NSMutableArray *)array
{
    NSLog(@"historyArray = %@",array);
    NSString *_newsId = [NSString stringWithFormat:@"%d",[[array objectAtIndex:0] intValue]];
    NSArray *commentArray = [DBOperate queryData:T_HISTORY_NEW theColumn:@"id" theColumnValue:_newsId withAll:NO];
    if (commentArray.count > 0) {
        NSLog(@"评论后的数据");
        
    } else {
        [DBOperate deleteData:T_HISTORY_NEW tableColumn:@"id" columnValue:_newsId];
        [DBOperate insertDataWithnotAutoID:array tableName:T_HISTORY_NEW];
        [DBOperate insertData:array tableName:T_HISTORY_NEW];
    }
    
//    [DBOperate updateData:T_HISTORY_NEW tableColumn:@"comments" columnValue:@"100" conditionColumn:@"id" conditionColumnValue:_newsId];
//    NSLog(@"array===%@",[array objectAtIndex:4]);


}

- (void)accessService
{
    NSMutableDictionary *jsontestDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										[Common getSecureString],@"keyvalue",
										[NSNumber numberWithInt: SITE_ID],@"site_id",
                                        [NSNumber numberWithInt: [self.newsId intValue]],@"new_id",nil];
	
	[[DataManager sharedManager] accessService:jsontestDic command:NEW_DETAIL_COMMAND_ID
								  accessAdress:@"new/detail.do?param=%@" delegate:self withParam:nil];
}

- (void)didFinishCommand:(NSMutableArray*)resultArray cmd:(int)commandid withVersion:(int)ver{
    switch(commandid)
    {
        //评论
        case OPERAT_SEND_NEWS_COMMENT:
            [self performSelectorOnMainThread:@selector(commentResult:) withObject:resultArray waitUntilDone:NO];
            break;
            
        //收藏
        case OPERAT_SEND_NEWS_FAVORITE:
            [self performSelectorOnMainThread:@selector(favoriteResult:) withObject:resultArray waitUntilDone:NO];
            break;
        case NEW_DETAIL_COMMAND_ID:
            [self performSelectorOnMainThread:@selector(detailResult:) withObject:resultArray waitUntilDone:NO];
            break;
        default: ;
    }
}

- (void)detailResult:(NSMutableArray *)resultArray
{
//    self.detailArray = resultArray;
    NSLog(@"resultArray === %@",resultArray);
    [self update:resultArray];
    
}

//网络获取数据
//-(void)accessItemService
//{
//    NSString *reqUrl = @"comment/list.do?param=%@";
//    
//    NSDictionary *jsontestDic = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 [Common getSecureString],@"keyvalue",
//                                 [NSNumber numberWithInt: SITE_ID],@"site_id",
//                                 [NSNumber numberWithInt: self.newsId],@"id",
//                                 [NSNumber numberWithInt: 1],@"type",
//                                 [NSNumber numberWithInt: 0],@"created",
//                                 nil];
//    
//    [[DataManager sharedManager] accessService:jsontestDic
//                                       command:OPERAT_NEWS_COMMENT_REFRESH
//                                  accessAdress:reqUrl 
//                                      delegate:self
//                                     withParam:nil];
//}

- (void)commentResult:(NSMutableArray *)resultArray
{
    int isSuccess = [[resultArray objectAtIndex:0] intValue];
    if (isSuccess == 1 ) {
        if (progressHUDTmp) {
            progressHUDTmp.labelText = @"评论成功";
            progressHUDTmp.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"提示icon-ok.png"]] autorelease];
            progressHUDTmp.mode = MBProgressHUDModeCustomView;
            [progressHUDTmp hide:YES afterDelay:1.0];
        }
        
        //置空
        self.tempTextContent = @"";
        self.textView.text = @"我也说一句";
        self.textView.textColor = [UIColor grayColor]; 
        
        if (isFrom == YES) {
            
            NSString *_newsId = [NSString stringWithFormat:@"%d",[[detailArray objectAtIndex:0] intValue]];
            NSArray *countArray = [DBOperate queryData:T_HISTORY_NEW theColumn:@"id" theColumnValue:_newsId withAll:NO];
            
            NSLog(@"countArray = %@",countArray);
            
            int count = [[[countArray objectAtIndex:0] objectAtIndex:4] intValue];
            
            ++count;
            
            NSLog(@"count = %d",count);
            [DBOperate updateData:T_HISTORY_NEW tableColumn:@"comments" columnValue:[NSString stringWithFormat:@"%lu",(unsigned long)count] conditionColumn:@"id" conditionColumnValue:_newsId];
            
         
            NSString *str = [NSString stringWithFormat:@"%lu评论",(unsigned long)count];
            [barbutton setTitle:str];
        }
        
    }else if(isSuccess == 0 ){
        if (progressHUDTmp) {
            progressHUDTmp.labelText = @"发送失败";
            progressHUDTmp.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"提示icon-信息.png"]] autorelease];
            progressHUDTmp.mode = MBProgressHUDModeCustomView;
            [progressHUDTmp hide:YES afterDelay:1.0];
        }
    }
    
}

- (void)favoriteResult:(NSMutableArray *)resultArray
{
    int isSuccess = [[resultArray objectAtIndex:0] intValue];
    if (isSuccess == 1 ) {
        NSMutableArray *memberArray = (NSMutableArray *)[DBOperate queryData:T_MEMBER_INFO theColumn:@"" theColumnValue:@"" withAll:YES];
        if ([memberArray count] > 0) 
        {
            self.userId = [[memberArray objectAtIndex:0] objectAtIndex:member_info_memberId];
        }
        else 
        {
            self.userId = @"0";
        }
        
        progressHUDTmp.labelText = @"添加收藏成功";
        progressHUDTmp.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"提示icon-ok.png"]] autorelease];
        progressHUDTmp.mode = MBProgressHUDModeCustomView;
        [progressHUDTmp hide:YES afterDelay:1.0];
        
        //将收藏新闻写入新闻收藏表
        NSMutableArray *infoList = [[NSMutableArray alloc] init];	
        [infoList addObject:userId];		
        [infoList addObject:[detailArray objectAtIndex:news_id]];
        [DBOperate insertDataWithnotAutoID:infoList tableName:T_FAVORITED_NEWS];
        [infoList release];
        
        isFavorite = YES;
        UIImageView *favoriteButton = (UIImageView *)[containerView viewWithTag:2002];
        favoriteButton.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"已收藏按钮" ofType:@"png"]];
    }else {
        progressHUDTmp.labelText = @"收藏失败";
        progressHUDTmp.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"提示icon-信息.png"]] autorelease];
        progressHUDTmp.mode = MBProgressHUDModeCustomView;
        [progressHUDTmp hide:YES afterDelay:1.0];
    }
    
}

#pragma mark 收藏操作
-(void)favorite
{
	if (!isFavorite) 
	{
		//判断用户是否登陆
		if (_isLogin) 
		{
			if (progressHUDTmp == nil) {
				progressHUDTmp = [[MBProgressHUD alloc] initWithFrame:CGRectMake(0, 0, 320, 420)];
				progressHUDTmp.delegate = self;
				progressHUDTmp.labelText = @"发送中... ";
				[self.view addSubview:progressHUDTmp];
				[self.view bringSubviewToFront:progressHUDTmp];
			}
			[progressHUDTmp show:YES];
			
			
			NSString *reqUrl = @"member/favorite.do?param=%@";
			
			NSDictionary *jsontestDic = [NSDictionary dictionaryWithObjectsAndKeys:
										 [Common getSecureString],@"keyvalue",
										 [NSNumber numberWithInt: SITE_ID],@"site_id",
										 self.userId,@"user_id",
										 [detailArray objectAtIndex:news_id],@"info_id",
										 [NSNumber numberWithInt: 1],@"type",
										 nil];
			
			[[DataManager sharedManager] accessService:jsontestDic 
											   command:OPERAT_SEND_NEWS_FAVORITE
										  accessAdress:reqUrl 
											  delegate:self 
											 withParam:nil];			
		}
		else 
		{
			LoginViewController *login = [[LoginViewController alloc] init];
			login.delegate = self;
			self.operateType = 2;
			[self.navigationController pushViewController:login animated:YES];
			[login release];
		}
		
	}
}

#pragma mark 改变键盘按钮
-(void)buttonChange:(BOOL)isKeyboardShow
{
	//判断软键盘显示
	if (isKeyboardShow) 
	{
        UIButton *sendBtn = (UIButton *)[containerView viewWithTag:2003];
        
        //增长输入框
        if (sendBtn.hidden) 
        {
            UIImageView *entryImageView = (UIImageView *)[containerView viewWithTag:2000];
            CGRect entryFrame = entryImageView.frame;
            entryFrame.size.width += 20.0f;
            
            CGRect textFrame = self.textView.frame;
            textFrame.size.width += 20.0f;
            
            entryImageView.frame = entryFrame;
            self.textView.frame = textFrame;
        }
        
		//隐藏分享 收藏按钮 
		UIImageView *shareButton = (UIImageView *)[containerView viewWithTag:2001];
		UIImageView *favoriteButton = (UIImageView *)[containerView viewWithTag:2002];
		shareButton.hidden = YES;
		favoriteButton.hidden = YES;
		
		//显示字数统计
		UILabel *remainCountLabel = (UILabel *)[containerView viewWithTag:2004];
		remainCountLabel.hidden = NO;
		
		//显示发送按钮
		sendBtn.hidden = NO;
        
	}
	else
	{
		//显示分享 收藏按钮 
		UIImageView *shareButton = (UIImageView *)[containerView viewWithTag:2001];
		UIImageView *favoriteButton = (UIImageView *)[containerView viewWithTag:2002];
		shareButton.hidden = NO;
		favoriteButton.hidden = NO;
		
		//隐藏字数统计
		UILabel *remainCountLabel = (UILabel *)[containerView viewWithTag:2004];
		remainCountLabel.hidden = YES;
		
		//隐藏发送按钮
		UIButton *sendBtn = (UIButton *)[containerView viewWithTag:2003];
		sendBtn.hidden = YES;
		
		//缩小输入框
		UIImageView *entryImageView = (UIImageView *)[containerView viewWithTag:2000];
		CGRect entryFrame = entryImageView.frame;
		entryFrame.size.width -= 20.0f;
		
		CGRect textFrame = self.textView.frame;
		textFrame.size.width -= 20.0f;
		
		entryImageView.frame = entryFrame;
		self.textView.frame = textFrame; 
        
	}
    
}

#pragma mark 发表评论
-(void)publishComment:(id)sender
{
    NSString *content = textView.text;
    
    //把回车 转化成 空格
    content = [content stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    content = [content stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    
    if ([content length] > 0) 
    {
        if ([content length] > 140)
        {
            [alertView showAlert:@"回复内容不能超过140个字符"];
        }
        else
        {
            progressHUDTmp = [[MBProgressHUD alloc] initWithFrame:CGRectMake(0, 0, 320, 420)];
            progressHUDTmp.delegate = self;
            progressHUDTmp.labelText = @"发送中... ";
            [self.view addSubview:progressHUDTmp];
            [self.view bringSubviewToFront:progressHUDTmp];
            [progressHUDTmp show:YES];
            
            NSString *reqUrl = @"member/comment.do?param=%@";					
            NSDictionary *jsontestDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [Common getSecureString],@"keyvalue",
                                         [NSNumber numberWithInt: SITE_ID],@"site_id",
                                         self.userId,@"user_id",
                                         [NSNumber numberWithInt: 1],@"type",
                                         [detailArray objectAtIndex:news_id],@"info_id",
                                         [NSNumber numberWithInt: 0],@"isPurchase",
                                         content,@"content",
                                         nil];
            
            [[DataManager sharedManager] accessService:jsontestDic 
                                               command:OPERAT_SEND_NEWS_COMMENT 
                                          accessAdress:reqUrl 
                                              delegate:self 
                                             withParam:nil];
            
            [textView resignFirstResponder];			
        }
    }
    else 
    {
        //[alertView showAlert:@"请输入留言内容"];
        [textView resignFirstResponder];
    }
    
}

#pragma mark -
#pragma mark manageActionSheetDelegate
- (void) actionSheetAppear:(int)actionID actionSheet:(UIActionSheet *)actionSheet{
	
}

- (void)getChoosedIndex:(int)actionID chooseIndex:(int)index{
    isShowPromotionAlert = NO;
	NSString *str = @"news/view/";
	NSString *link = [NSString stringWithFormat:@"%@%@%d",DETAIL_SHARE_LINK,str,[[detailArray objectAtIndex:news_id] intValue]];
	NSString *content = [detailArray objectAtIndex:news_title];
	NSString *allContent = [NSString stringWithFormat:@"%@  %@",content,link];
	
	switch (index) {
		case 0:
		{
			SendMsgToWeChat *sendMsg = [[SendMsgToWeChat alloc] init];
            UIImage *simg = [newsImageView.image fillSize:CGSizeMake(114, 114)];
            if (app_wechat_share_type == app_to_wechat) {
                [sendMsg sendNewsContent:content newsDescription:allContent newsImage:simg newUrl:link shareType:index];
            }else if (app_wechat_share_type == wechat_to_app) {
                [sendMsg RespNewsContent:content newsDescription:allContent newsImage:simg newUrl:link];
            }
            [sendMsg release];
		}
			break;
		case 1:
		{
			SendMsgToWeChat *sendMsg = [[SendMsgToWeChat alloc] init];
            UIImage *simg = [newsImageView.image fillSize:CGSizeMake(114, 114)];
            if (app_wechat_share_type == app_to_wechat) {
                [sendMsg sendNewsContent:content newsDescription:allContent newsImage:simg newUrl:link shareType:index];
            }else if (app_wechat_share_type == wechat_to_app) {
                [sendMsg RespNewsContent:content newsDescription:allContent newsImage:simg newUrl:link];
            }
            [sendMsg release];
		}
			break;
		case 2:
		{
			NSArray *weiboArray = [DBOperate queryData:T_WEIBO_USERINFO theColumn:@"weiboType" 
										theColumnValue:SINA withAll:NO];
			if (weiboArray != nil && [weiboArray count] > 0) {
				ShareToBlogViewController *share = [[ShareToBlogViewController alloc] init];
				share.weiBoType = 0;
				share.shareImage = newsImageView.image;
				share.checkBoxSelected =YES;
				share.defaultContent = [NSString stringWithFormat:@"%@   %@",allContent,SHARE_CONTENTS];
				//share.defaultContent = [detailArray objectAtIndex:recommend_news_title];
				[self.navigationController pushViewController:share animated:YES];
				[share release];
			}else {
				SinaViewController *sc = [[SinaViewController alloc] init];
				sc.delegate = self;
				[self.navigationController pushViewController:sc animated:YES];
				[sc release];
			}
            
		}
			break;
		case 3:
		{
			NSArray *weiboArray = [DBOperate queryData:T_WEIBO_USERINFO theColumn:@"weiboType" 
										theColumnValue:TENCENT withAll:NO];
			if (weiboArray != nil && [weiboArray count] > 0) {
				ShareToBlogViewController *share = [[ShareToBlogViewController alloc] init];
				share.weiBoType = 1;
				share.shareImage = newsImageView.image;
				share.checkBoxSelected =YES;
				share.defaultContent = [NSString stringWithFormat:@"%@   %@",allContent,SHARE_CONTENTS];
				//share.defaultContent = [detailArray objectAtIndex:recommend_news_title];
				[self.navigationController pushViewController:share animated:YES];
				[share release];
			}else {
				TencentViewController *tc = [[TencentViewController alloc] init];
				tc.delegate = self;
				[self.navigationController pushViewController:tc animated:YES];
				[tc release];
			}
		}
			break;
		default :
			break;
	}
}

//分享
-(void)share
{
	NSArray *actionSheetMenu = [NSArray arrayWithObjects:@"分享至微信朋友圈",@"微信分享给好友",@"分享到新浪微博",@"分享到腾讯微博",nil];
	manageActionSheet *tempActionsheet = [[manageActionSheet alloc]initActionSheetWithStrings:actionSheetMenu];
	tempActionsheet.manageDeleage = self;
	self.actionSheet = tempActionsheet;
	[tempActionsheet release];
	[actionSheet showActionSheet:self.view];
	
}

#pragma mark OauthSinaSeccessDelagate
- (void) oauthSinaSuccess{
    isShowPromotionAlert = NO;
    NSString *str = @"news/view/";
	NSString *link = [NSString stringWithFormat:@"%@%@%d",DETAIL_SHARE_LINK,str,[[detailArray objectAtIndex:news_id] intValue]];
	NSString *content = [detailArray objectAtIndex:news_title];
	NSString *allContent = [NSString stringWithFormat:@"%@  %@",content,link];
    
	ShareToBlogViewController *share = [[ShareToBlogViewController alloc] init];
	share.weiBoType = 0;
	share.shareImage = newsImageView.image;
	share.checkBoxSelected =YES;
    share.defaultContent = [NSString stringWithFormat:@"%@   %@",allContent,SHARE_CONTENTS];
    [self.navigationController pushViewController:share animated:YES];
	[share release];
}

#pragma mark OauthTencentSeccessDelagate
- (void) oauthTencentSuccess{
    isShowPromotionAlert = NO;
    NSString *str = @"news/view/";
	NSString *link = [NSString stringWithFormat:@"%@%@%d",DETAIL_SHARE_LINK,str,[[detailArray objectAtIndex:news_id] intValue]];
	NSString *content = [detailArray objectAtIndex:news_title];
	NSString *allContent = [NSString stringWithFormat:@"%@  %@",content,link];
    
	ShareToBlogViewController *share = [[ShareToBlogViewController alloc] init];
	share.weiBoType = 1;
	share.shareImage = newsImageView.image;
	share.checkBoxSelected =YES;
    share.defaultContent = [NSString stringWithFormat:@"%@   %@",allContent,SHARE_CONTENTS];
	[self.navigationController pushViewController:share animated:YES];
	[share release];
}

//编辑中
-(void)doEditing
{
	UILabel *remainCountLabel = (UILabel *)[containerView viewWithTag:2004];
	int textCount = [textView.text length];
	if (textCount > 140) 
	{
		remainCountLabel.textColor = [UIColor colorWithRed:1.0 green: 0.0 blue: 0.0 alpha:1.0];
	}
	else 
	{
		remainCountLabel.textColor = [UIColor colorWithRed:0.5 green: 0.5 blue: 0.5 alpha:1.0];
	}
	
	remainCountLabel.text = [NSString stringWithFormat:@"%d/140",140 - [textView.text length]];
}

-(void)resignTextView
{
	[textView resignFirstResponder];
}

#pragma mark -
#pragma mark 键盘通知调用
//Code from Brett Schumann
-(void) keyboardWillShow:(NSNotification *)note{
	
    // get keyboard size and loctaion
	CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    // Need to translate the bounds to account for rotation.
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    
	// get a rect for the textView frame
	CGRect containerFrame = containerView.frame;
	
	//新增一个遮罩按钮
    UIButton *bgBtn = (UIButton *)[self.view viewWithTag:2005];
    if (bgBtn != nil) {
        [bgBtn removeFromSuperview];
    }  //解决评论后不能拖动的问题
	UIButton *backGrougBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	backGrougBtn.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - (keyboardBounds.size.height + containerFrame.size.height));
	backGrougBtn.tag = 2005;
	[backGrougBtn addTarget:self action:@selector(hiddenKeyboard) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:backGrougBtn];
	
    containerFrame.origin.y = self.view.bounds.size.height - (keyboardBounds.size.height + containerFrame.size.height);
	
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
	
	// set views with new info
	containerView.frame = containerFrame;
	
	// commit animations
	[UIView commitAnimations];
	
	//更改按钮状态
	[self buttonChange:YES];
	
}

-(void) keyboardWillHide:(NSNotification *)note{
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	// get a rect for the textView frame
	CGRect containerFrame = containerView.frame;
    containerFrame.origin.y = self.view.bounds.size.height - containerFrame.size.height;
	
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:[duration doubleValue]];
    [UIView setAnimationCurve:[curve intValue]];
	
	// set views with new info
	containerView.frame = containerFrame;
	
	// commit animations
	[UIView commitAnimations];
    
	//移出遮罩按钮
	UIButton *backGrougBtn = (UIButton *)[self.view viewWithTag:2005];
	[backGrougBtn removeFromSuperview];
	
	//更改按钮状态
	[self buttonChange:NO];
}

//关闭键盘
-(void)hiddenKeyboard
{
    //输入内容 存起来
	self.tempTextContent = self.textView.text;
    self.textView.text = @"我也说一句";
	self.textView.textColor = [UIColor grayColor];
	[textView resignFirstResponder];
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
	
	CGRect r = containerView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	containerView.frame = r;
}

- (BOOL)growingTextViewShouldBeginEditing:(HPGrowingTextView *)growingTextView
{
	//判断用户是否登陆
	if (_isLogin == YES) 
	{
		if ([self.userId intValue] != 0)
		{
			return YES;
		}
		else
		{
			LoginViewController *login = [[LoginViewController alloc] init];
            login.delegate = self;
            operateType = 1;
			[self.navigationController pushViewController:login animated:YES];
			[login release];
			return NO;
		}
        
	}
	else 
	{
		LoginViewController *login = [[LoginViewController alloc] init];
        login.delegate = self;
        operateType = 1;
		[self.navigationController pushViewController:login animated:YES];
		[login release];
		return NO;
	}
}

- (void)growingTextViewDidBeginEditing:(HPGrowingTextView *)growingTextView
{
	if([growingTextView.text isEqualToString:@"我也说一句"])
	{
		//内容设置回来
		growingTextView.text = self.tempTextContent;
	}
	growingTextView.textColor = [UIColor blackColor];
	
}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	[self performSelectorOnMainThread:@selector(doEditing) withObject:nil waitUntilDone:NO];
	
	return YES;
}
#pragma mark -
#pragma mark 登录接口回调
- (void)loginWithResult:(BOOL)isLoginSuccess{
    
	if (isLoginSuccess) 
    {
        //获取当前用户的user_id
        NSMutableArray *memberArray = (NSMutableArray *)[DBOperate queryData:T_MEMBER_INFO theColumn:@"" theColumnValue:@"" withAll:YES];
        if ([memberArray count] > 0) 
        {
            self.userId = [[memberArray objectAtIndex:0] objectAtIndex:member_info_memberId];
        }
        else 
        {
            self.userId = @"0";
        }
        
		if (operateType == 1) 
        {
            //评论操作，调用评论接口
			[textView becomeFirstResponder];
		}
        else if (operateType == 2) 
        {
            //收藏操作
			[self favorite];
		}
	}
    //    else
    //    {
    //		[alertView showAlert:@"登录失败，请重试！"];
    //	}
    
}

- (void)startIconDownload:(NSString*)imageURL forIndex:(NSIndexPath*)index
{
	
    if (iconDownLoad == nil && imageURL != nil && imageURL.length > 1) 
    {
        IconDownLoader *iconDownloader = [[IconDownLoader alloc] init];
        iconDownloader.downloadURL = imageURL;
        iconDownloader.indexPathInTableView = index;
		iconDownloader.imageType = CUSTOMER_PHOTO;
		self.iconDownLoad = iconDownloader;
		iconDownLoad.delegate = self;
        [iconDownLoad startDownload];
        [iconDownloader release];   
    }
}
- (void)appImageDidLoad:(NSIndexPath *)indexPath withImageType:(int)Type
{
    if(iconDownLoad.cardIcon.size.width>2.0)
    {
        NSString *picUrl = [detailArray objectAtIndex:news_recommend_img];
        NSString *picName = [Common encodeBase64:(NSMutableData *)[picUrl dataUsingEncoding: NSUTF8StringEncoding]];
        UIImage *photo = iconDownLoad.cardIcon;
        [FileManager savePhoto:picName withImage:photo];
        newsImageView.frame = CGRectMake(20, newsImageView.frame.origin.y, 280, 205);
        descLable.frame = CGRectMake(20,CGRectGetMaxY(newsImageView.frame) + 10, 280, descLable.frame.size.height);
        UIImage *img = iconDownLoad.cardIcon;
        newsImageView.image = [img fillSize:CGSizeMake(280,205)];
    }
}

- (void)commentListAction
{
    newsCommentViewController *newsCommentView = [[newsCommentViewController alloc] init];
    newsCommentView.infoTitle =[detailArray objectAtIndex:news_title];
    newsCommentView.newsId = [[detailArray objectAtIndex:news_id] intValue];
    [self.navigationController pushViewController:newsCommentView animated:YES];
}
@end
