//
//  WriteCommentViewController.m
//  shopping
//
//  Created by 来 云 on 13-1-25.
//  Copyright (c) 2013年 __MyCompanyName__. All rights reserved.
//

#import "WriteCommentViewController.h"
#import "Common.h"
#import "alertView.h"

@interface WriteCommentViewController ()

@end

@implementation WriteCommentViewController
@synthesize myTextView;
@synthesize progressHUD;
@synthesize infoIdStr;
@synthesize orderIdStr;
@synthesize commentType = __commentType;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor whiteColor];
	
	self.title = @"我的评价";
	
	UITextView *tempTextView = [[UITextView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height - 300.0f)];
	tempTextView.returnKeyType = UIReturnKeyDefault; //just as an example
	tempTextView.font = [UIFont systemFontOfSize:16.0f];
	tempTextView.textColor = [UIColor grayColor]; 
	tempTextView.delegate = self;
    tempTextView.backgroundColor = [UIColor clearColor];
	tempTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	tempTextView.text = @"";
	self.myTextView = tempTextView;
	[self.view addSubview:self.myTextView];
	[tempTextView release];
    
    UILabel *remainCountLabel = [[UILabel alloc]initWithFrame:CGRectMake(265.0f, self.myTextView.frame.size.height - 25.0f, 50.0f, 20.0f)];
	remainCountLabel.tag = 200;
	remainCountLabel.font = [UIFont systemFontOfSize:12.0f];
	remainCountLabel.textColor = [UIColor grayColor];
	remainCountLabel.text = @"140/140";	
	remainCountLabel.textAlignment = UITextAlignmentCenter;
	remainCountLabel.backgroundColor = [UIColor clearColor];
	[self.view addSubview:remainCountLabel];
	[remainCountLabel release];
	
	UILabel *tipLabel = [[UILabel alloc]initWithFrame:CGRectMake(10.0f, 3.0f, 300.0f, 30.0f)];
	tipLabel.tag = 100;
	tipLabel.font = [UIFont systemFontOfSize:16.0f];
	tipLabel.textColor = [UIColor grayColor];
	tipLabel.text = @"说两句";	
	tipLabel.textAlignment = UITextAlignmentLeft;
	tipLabel.backgroundColor = [UIColor clearColor];
	[self.myTextView addSubview:tipLabel];
	[tipLabel release];
	
	[self.myTextView becomeFirstResponder];
	
	//添加发送按钮
//	UIButton *sendbutton = [UIButton buttonWithType:UIButtonTypeCustom];  
//    sendbutton.frame = CGRectMake(0.0f, 7.0f, 50.0f, 30.0f);  
//	[sendbutton addTarget:self action:@selector(publishFeedback:) forControlEvents:UIControlEventTouchDown];
//	[sendbutton setBackgroundImage:[[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"发送按钮" ofType:@"png"]] forState:UIControlStateNormal]; 
//	
//	UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:sendbutton]; 
//	self.navigationItem.rightBarButtonItem = barButton;
//	[barButton release];
    UIBarButtonItem *mrightbto = [[UIBarButtonItem alloc]
                                  initWithTitle:@"发送"
                                  style:UIBarButtonItemStyleBordered
                                  target:self
                                  action:@selector(publishFeedback:)];
    self.navigationItem.rightBarButtonItem = mrightbto;
    [mrightbto release];


}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.myTextView.delegate = nil;
	self.myTextView = nil;
	self.progressHUD.delegate = nil;
	self.progressHUD = nil;
}


- (void)dealloc {
	self.myTextView.delegate = nil;
	self.myTextView = nil;
	self.progressHUD.delegate = nil;
	self.progressHUD = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark progressHUD委托
//在该函数 [progressHUD hide:YES afterDelay:1.0f] 执行后回调

- (void)hudWasHidden:(MBProgressHUD *)hud{
	
	if (self.progressHUD) {
		[self.progressHUD removeFromSuperview];
		self.progressHUD = nil;
	}
	
    if (__commentType == CommentTypeOrderDetail) {
        NSArray *arr = self.navigationController.viewControllers;
        //NSLog(@"[arr count]====%d",[arr count]);
        if ([arr count] >= 4){
            [self.navigationController popToViewController:[arr objectAtIndex:arr.count-3] animated:YES];
            return;
        }
    }else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark 键盘通知调用
//Code from Brett Schumann
-(void) keyboardWillShow:(NSNotification *)note{
	
    // get keyboard size and loctaion
	CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    
    // Need to translate the bounds to account for rotation.
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
	
	//设置文本框的高度
	CGRect myTextViewFrame = myTextView.frame;
	myTextViewFrame.size.height = self.view.frame.size.height - keyboardBounds.size.height;
	
	self.myTextView.frame = myTextViewFrame;
	
    UILabel *remainCountLabel = (UILabel *)[self.view viewWithTag:200];
	[remainCountLabel setFrame:CGRectMake(265.0f, myTextViewFrame.size.height - 25.0f, 50.0f, 20.0f)];
	
}

-(void) keyboardWillHide:(NSNotification *)note{
    
}


#pragma mark -
#pragma mark TextView
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
	
	[self performSelectorOnMainThread:@selector(doEditing) withObject:nil waitUntilDone:NO];
	
	return YES;
	
}

#pragma mark -----private method
//编辑中
-(void) doEditing
{
	UILabel *tipLabel = (UILabel *)[self.myTextView viewWithTag:100];
	[tipLabel removeFromSuperview];
	
	UILabel *remainCountLabel = (UILabel *)[self.view viewWithTag:200];
	int textCount = [self.myTextView.text length];
	if (textCount > 140) 
	{
		remainCountLabel.textColor = [UIColor colorWithRed:1.0 green: 0.0 blue: 0.0 alpha:1.0];
	}
	else 
	{
		remainCountLabel.textColor = [UIColor grayColor];
	}
	
	remainCountLabel.text = [NSString stringWithFormat:@"%d/140",140 - [self.myTextView.text length]];
}

//发表反馈
-(void)publishFeedback:(id)sender
{	
	NSString *content = self.myTextView.text;
	
	//把回车 转化成 空格
	content = [content stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
	content = [content stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	
	if ([content length] > 0) 
	{
		if ([content length] > 140)
		{
			[alertView showAlert:@"反馈内容不能超过140个字符"];
		}
		else
		{
			MBProgressHUD *progressHUDTmp = [[MBProgressHUD alloc] initWithFrame:CGRectMake(0, 0, 320, self.myTextView.frame.size.height)];
			self.progressHUD = progressHUDTmp;
			[progressHUDTmp release];
			self.progressHUD.delegate = self;
			self.progressHUD.labelText = @"发送中... ";
			[self.view addSubview:self.progressHUD];
			[self.view bringSubviewToFront:self.progressHUD];
			[self.progressHUD show:YES];
			
			//获取当前用户的user_id
			NSString *userId;
			NSMutableArray *memberArray = (NSMutableArray *)[DBOperate queryData:T_MEMBER_INFO theColumn:@"" theColumnValue:@"" withAll:YES];
			if ([memberArray count] > 0) 
			{
				userId = [[memberArray objectAtIndex:0] objectAtIndex:member_info_memberId];
			}
			else 
			{
				userId = @"0";
			}
            
            NSMutableDictionary *jsontestDic = nil;
            if (__commentType == CommentTypeMyCommentlist) {
                jsontestDic = [NSDictionary dictionaryWithObjectsAndKeys:
                               [Common getSecureString],@"keyvalue",
                               [NSNumber numberWithInt: SITE_ID],@"site_id",
                               [NSNumber numberWithInt:[userId intValue]],@"user_id",
                               [NSNumber numberWithInt:[self.infoIdStr intValue]],@"info_id",
                               [NSNumber numberWithInt:2],@"type",
                               [NSNumber numberWithInt:[self.orderIdStr intValue]],@"order_id",
                               [NSNumber numberWithInt:1],@"isPurchase",
                               content,@"content",nil];
            }else if (__commentType == CommentTypeOrderDetail) {
                jsontestDic = [NSDictionary dictionaryWithObjectsAndKeys:
                               [Common getSecureString],@"keyvalue",
                               [NSNumber numberWithInt: SITE_ID],@"site_id",
                               [NSNumber numberWithInt:[userId intValue]],@"user_id",
                               [NSNumber numberWithInt:[self.infoIdStr intValue]],@"info_id",
                               [NSNumber numberWithInt:[self.orderIdStr intValue]],@"order_id",
                               [NSNumber numberWithInt:2],@"type",
                               [NSNumber numberWithInt:1],@"isPurchase",
                               content,@"content",nil];
            }
            
            [[DataManager sharedManager] accessService:jsontestDic command:MEMBER_WRITECOMMENT_COMMAND_ID accessAdress:@"member/comment.do?param=%@" delegate:self withParam:jsontestDic];
		}
	}
	else 
	{
		[alertView showAlert:@"请输入反馈内容"];
	}
}

//评论成功
- (void)feedbackSuccess
{	
	self.myTextView.text = @"";
	if (self.progressHUD) {
		[progressHUD hide:YES afterDelay:1.0f];
	}
}

- (void)didFinishCommand:(NSMutableArray*)resultArray cmd:(int)commandid withVersion:(int)ver{
	
	NSMutableArray* array = (NSMutableArray*)resultArray;
	int isSuccess = [[array objectAtIndex:0] intValue];
    
	if (isSuccess == 1 ) {
		if (self.progressHUD) {
			self.progressHUD.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"提示icon-ok.png"]] autorelease];
			self.progressHUD.mode = MBProgressHUDModeCustomView;
			self.progressHUD.labelText = @"反馈成功";
            
            [self performSelectorOnMainThread:@selector(feedbackSuccess) withObject:nil waitUntilDone:NO];
		}
	}else if(isSuccess == 0 ){
		if (self.progressHUD != nil) {
			[self.progressHUD removeFromSuperview];
            self.progressHUD = nil;
            
            MBProgressHUD *progressHUDTmp = [[MBProgressHUD alloc] initWithFrame:CGRectMake(0, 0, 320, self.myTextView.frame.size.height)];
            progressHUDTmp.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"提示icon-信息.png"]] autorelease];
            progressHUDTmp.mode = MBProgressHUDModeCustomView;
            progressHUDTmp.labelText = @"反馈失败";
			[self.view addSubview:progressHUDTmp];
			[self.view bringSubviewToFront:progressHUDTmp];
			[progressHUDTmp show:YES];
            [progressHUDTmp release];
		}
	}
}

@end
