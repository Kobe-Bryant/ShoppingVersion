//
//  MyAddressViewController.m
//  shopping
//
//  Created by 来 云 on 13-1-5.
//  Copyright (c) 2013年 __MyCompanyName__. All rights reserved.
//

#import "MyAddressViewController.h"
#import "Common.h"
#import "DBOperate.h"
#import "DataManager.h"
#import "AddReceivingAddressViewController.h"
@interface MyAddressViewController ()

@end

@implementation MyAddressViewController
@synthesize myTableView = _myTableView;
@synthesize listArray = __listArray;
@synthesize commandOper;
@synthesize spinner;
@synthesize userId;
@synthesize _isHidden;
@synthesize fromType = __fromType;
@synthesize _isService;
@synthesize info;
@synthesize delegate;
@synthesize prizeInfoId;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        __listArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (__fromType == FromTypeMy) {
        self.title = @"我的常用地址";
    }else if (__fromType == FromTypePrize) {
        self.title = @"奖品收货地址";
    }else {
        self.title = @"收货地址";
    }
    
    _myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 5, 320, self.view.frame.size.height - 50) style:UITableViewStylePlain];
    _myTableView.delegate = self;
    _myTableView.dataSource = self;
    _myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_myTableView];
    self.myTableView.backgroundColor = [UIColor clearColor];
    
    UIBarButtonItem *mrightbto = [[UIBarButtonItem alloc]
                                  initWithTitle:@"新增"
                                  style:UIBarButtonItemStyleBordered
                                  target:self
                                  action:@selector(addAction)];
    self.navigationItem.rightBarButtonItem = mrightbto;
    [mrightbto release];
    
    _loadingMore = NO;
    _isAllowLoadingMore = NO;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //NSLog(@"===%@",self.userId);
    if (noLabel != nil) {
        [noLabel removeFromSuperview];
    }
    
    NSMutableArray *dbArr = (NSMutableArray *)[DBOperate queryData:T_ADDRESS_LIST theColumn:@"memberId" theColumnValue:self.userId orderBy:@"updatetime" orderType:@"DESC" withAll:NO];
    if ([dbArr count] == 0) {
        [self accessService];
    }else {
        [self.listArray removeAllObjects];
        self.listArray = dbArr;
        
        if (__fromType == FromTypeReceive) {
            NSMutableArray *bigArr = (NSMutableArray *)[DBOperate queryData:T_ADDRESS_LIST theColumn:@"memberId" theColumnValue:self.userId orderBy:@"updatetime" orderType:@"DESC" withAll:NO];;
            NSMutableArray *itemArr = [[NSMutableArray alloc] init];
            for (int i = 0; i < [bigArr count]; i ++) {
                NSMutableArray *dbArr = [bigArr objectAtIndex:i];
                [dbArr removeObjectAtIndex:0];
                [dbArr removeObjectAtIndex:0];
                [dbArr removeObjectAtIndex:7];
                [dbArr removeObjectAtIndex:7];
                [dbArr removeObjectAtIndex:7];
                [itemArr addObject:dbArr];
            }
            NSMutableArray *ay = [[NSMutableArray alloc] initWithObjects:self.info.per_name,self.info.per_tel,self.info.per_province,self.info.per_city,self.info.per_area,self.info.per_detailAddress,self.info.per_post, nil];
            //NSLog(@"ay======%@",ay);
            if ([itemArr indexOfObject:ay] != NSNotFound) {
                int _index = [itemArr indexOfObject:ay];
            
                int _addressId = [[[self.listArray objectAtIndex:_index] objectAtIndex:address_list_id] intValue];
                //NSLog(@"addressId == %d",_addressId);
                
                [DBOperate updateWithTwoConditions:T_ADDRESS_LIST theColumn:@"isReceiveDefault" theColumnValue:@"0" ColumnOne:@"memberId" valueOne:self.userId columnTwo:@"1" valueTwo:[NSNumber numberWithInt:1]];
                
                [DBOperate updateWithTwoConditions:T_ADDRESS_LIST theColumn:@"isReceiveDefault" theColumnValue:@"1" ColumnOne:@"memberId" valueOne:self.userId columnTwo:@"id" valueTwo:[NSString stringWithFormat:@"%d",_addressId]];
            }else {
                [DBOperate updateWithTwoConditions:T_ADDRESS_LIST theColumn:@"isReceiveDefault" theColumnValue:@"0" ColumnOne:@"memberId" valueOne:self.userId columnTwo:@"1" valueTwo:[NSNumber numberWithInt:1]];
            }
            
            self.listArray = (NSMutableArray *)[DBOperate queryData:T_ADDRESS_LIST theColumn:@"memberId" theColumnValue:self.userId orderBy:@"updatetime" orderType:@"DESC" withAll:NO];
        }
        
        
        [self.myTableView reloadData];
    }
    
    if (_isService == YES) {
        int _id = [[[[DBOperate queryData:T_ADDRESS_LIST theColumn:@"memberId" equalValue:self.userId theColumn:@"isPrizeDefault" equalValue:@"1"] objectAtIndex:0] objectAtIndex:address_list_isPrizeDefault] intValue];
        NSMutableDictionary *jsontestDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [Common getSecureString],@"keyvalue",
                                            [NSNumber numberWithInt: SITE_ID],@"site_id",
                                            [NSNumber numberWithInt:[self.userId intValue]],@"user_id",
                                            [NSNumber numberWithInt:_id],@"id",nil];
        
        [[DataManager sharedManager] accessService:jsontestDic command:SETPRIZEADDRESS_COMMAND_ID accessAdress:@"luckdraw/setluckdrawAddress.do?param=%@" delegate:self withParam:jsontestDic];
    }
}

- (void)dealloc
{
    [_myTableView release];
    [__listArray release];
    [progressHUD release];
    [noLabel release];
    self.commandOper.delegate = nil;
	self.commandOper = nil;
    [super dealloc];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    self.commandOper.delegate = nil;
	self.commandOper = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) {
		return [self.listArray count];
	}else {
		return 0;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section ==0) {
		return 86.0f;
	}else {
		return 0;
	}	
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if (section == 1) {
		UIView *vv = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
		UILabel *moreLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 5, 320, 30)];
		moreLabel.text = @"上拉加载更多";
		moreLabel.tag = 200;
        moreLabel.font = [UIFont systemFontOfSize:14.0f];
		moreLabel.textColor = [UIColor colorWithRed:0.3 green: 0.3 blue: 0.3 alpha:1.0];
		moreLabel.textAlignment = UITextAlignmentCenter;
		moreLabel.backgroundColor = [UIColor clearColor];
		[vv addSubview:moreLabel];
		[moreLabel release];
		
		//添加loading图标
		indicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
		[indicatorView setCenter:CGPointMake(320 / 3, 40 / 2.0)];
		indicatorView.hidesWhenStopped = YES;
		[vv addSubview:indicatorView];
		
		return vv;
	}else {
		return nil;		
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if (section == 1 && self.listArray.count >= 20) {
		return 40;
	}else {
		return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	
	//NSInteger row = [indexPath row];
	
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIImage *bgImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"商品列表背景" ofType:@"png"]];
        UIImageView *bgImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0 , 0 , bgImage.size.width, bgImage.size.height)];
        bgImageView.userInteractionEnabled = YES;
        [cell.contentView addSubview:bgImageView];
        bgImageView.image = bgImage;
        [bgImage release];
        
        UIImage *btnImg1 = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"input_未选中" ofType:@"png"]];
        
        UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        leftButton.frame = CGRectMake(15, (86 - btnImg1.size.height) * 0.5, btnImg1.size.width, btnImg1.size.height);
        //[leftButton addTarget:self action:@selector(leftButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        leftButton.tag = indexPath.row + 1000;
        [bgImageView addSubview:leftButton];
        [leftButton setImage:btnImg1 forState:UIControlStateNormal];
        
        UIView *bgView;
        if (_isHidden == NO) {
            leftButton.hidden = NO;
            
            bgView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftButton.frame), 0, 200, 86)];
        }else {
            leftButton.hidden = YES;
            bgView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 230, 86)];
        }
        
        bgView.backgroundColor = [UIColor clearColor];
        bgView.userInteractionEnabled = YES;
        [bgImageView addSubview:bgView];
        
        UILabel *cName = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 100, 25)];
		cName.text = @"张山";
        cName.textColor = [UIColor darkGrayColor];
        cName.tag = 'n';
		cName.font = [UIFont systemFontOfSize:14.0f];
		cName.textAlignment = UITextAlignmentLeft;
		cName.backgroundColor = [UIColor clearColor];
		[bgView addSubview:cName];
        [cName release];
    
        UILabel *cTel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(cName.frame) + 10, 10, 120, 25)];
		cTel.text = @"13888888888";
        cTel.textColor = [UIColor darkGrayColor];
        cTel.tag = 't';
		cTel.font = [UIFont systemFontOfSize:14.0f];
		cTel.textAlignment = UITextAlignmentLeft;
		cTel.backgroundColor = [UIColor clearColor];
		[bgView addSubview:cTel];
        [cTel release];
        
        UILabel *cAddr = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(cName.frame), 200, 40)];
		cAddr.text = @"深圳市南山区科技园留学生创业大厦906 云来网络 111111";
        cAddr.textColor = [UIColor darkGrayColor];
        cAddr.numberOfLines = 0;
        cAddr.lineBreakMode = UILineBreakModeWordWrap;
        cAddr.tag = 'a';
		cAddr.font = [UIFont systemFontOfSize:14.0f];
		cAddr.textAlignment = UITextAlignmentLeft;
		cAddr.backgroundColor = [UIColor clearColor];
		[bgView addSubview:cAddr];
        [cAddr release];
        [bgView release];
        
        if (_isHidden == NO) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(0, 0, 240, 86);
            [btn addTarget:self action:@selector(leftButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            btn.tag = indexPath.row + 10000;
            [bgImageView addSubview:btn];
        }
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = indexPath.row + 1;
        button.frame = CGRectMake(320 - 60,  30, 50, 30);
        [button addTarget:self action:@selector(changeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [button setBackgroundImage:[UIImage imageNamed:@"button_白色.png"] forState:UIControlStateNormal];
        [bgImageView addSubview:button];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
		label.text = @"修改";
        label.textColor = [UIColor darkGrayColor];
		label.font = [UIFont systemFontOfSize:16.0f];
		label.textAlignment = UITextAlignmentCenter;
		label.backgroundColor = [UIColor clearColor];
		[button addSubview:label];
        [label release];

        [bgImageView release];
    }
    if ([self.listArray count] > 0 && indexPath.row < [self.listArray count]) {
        NSArray *ayArr = [self.listArray objectAtIndex:indexPath.row];
        
        if (_isHidden == NO) {
            UIImage *btnImg1 = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"input_未选中" ofType:@"png"]];
            UIImage *btnImg2 = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"input_选中" ofType:@"png"]];
            
            UIButton *btn = (UIButton *)[cell.contentView viewWithTag:indexPath.row + 1000];
            
            if (__fromType == FromTypePrize) {
                int value = [[ayArr objectAtIndex:address_list_isPrizeDefault] intValue];
                if (value == 0) {
                    [btn setImage:btnImg1 forState:UIControlStateNormal];    
                }else {
                    [btn setImage:btnImg2 forState:UIControlStateNormal];
                }
            }else if (__fromType == FromTypeReceive){
                int value = [[ayArr objectAtIndex:address_list_isReceiveDefault] intValue];
                if (value == 0) {
                    [btn setImage:btnImg1 forState:UIControlStateNormal];    
                }else {
                    [btn setImage:btnImg2 forState:UIControlStateNormal];
                }
            }
            
        }
        
        UILabel *labelName = (UILabel *)[cell.contentView viewWithTag:'n'];
        labelName.text = [ayArr objectAtIndex:address_list_name];
        
        UILabel *labelTel = (UILabel *)[cell.contentView viewWithTag:'t'];
        labelTel.text = [ayArr objectAtIndex:address_list_mobile];
        
        UILabel *labelAddr = (UILabel *)[cell.contentView viewWithTag:'a'];
        labelAddr.text = [NSString stringWithFormat:@"%@ %@ %@ %@ %@",[ayArr objectAtIndex:address_list_province],[ayArr objectAtIndex:address_list_city],[ayArr objectAtIndex:address_list_area],[ayArr objectAtIndex:address_list_address],[ayArr objectAtIndex:address_list_zip_code]];
    }
    
	return cell;	
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    rowValue = indexPath.row;

	_infoId = [[self.listArray objectAtIndex:indexPath.row] objectAtIndex:address_list_id];
	NSLog(@"_infoId=======%d",[_infoId intValue]);
    
    [DBOperate deleteData:T_ADDRESS_LIST tableColumn:@"id" columnValue:_infoId];
    
    NSMutableDictionary *jsontestDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [Common getSecureString],@"keyvalue",
                                        [NSNumber numberWithInt: SITE_ID],@"site_id",
                                        [NSNumber numberWithInt:[self.userId intValue]],@"user_id",
                                        [NSNumber numberWithInt:[_infoId intValue]],@"id",nil];
	
	[[DataManager sharedManager] accessService:jsontestDic command:MEMBER_ADDRESSDELETE_COMMAND_ID accessAdress:@"member/deladdress.do?param=%@" delegate:self withParam:jsontestDic];
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath 
{ 
    return UITableViewCellEditingStyleDelete; 
} 

#pragma mark UIScrollViewDelegate Methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (_isAllowLoadingMore && !_loadingMore && [self.listArray count] > 0)
    {
        UILabel *label = (UILabel*)[self.myTableView viewWithTag:200];
        
        float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
        if (bottomEdge > scrollView.contentSize.height + 10.0f) 
        {
            //松开 载入更多
            label.text=@"松开加载更多";
        }
        else
        {
            label.text=@"上拉加载更多";
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
    if (!decelerate)
	{
		//[self loadImagesForOnscreenRows];
    }
    
    if (_isAllowLoadingMore && !_loadingMore)
    {
        UILabel *label = (UILabel*)[self.myTableView viewWithTag:200];
        
        float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
        if (bottomEdge > scrollView.contentSize.height + 10.0f) 
        {
            //松开 载入更多
            _loadingMore = YES;
            
            label.text=@" 加载中 ...";
            [indicatorView startAnimating];
            
            //数据
            [self accessMoreService];
        }
        else
        {
            label.text=@"上拉加载更多";
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    
    float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
    if (bottomEdge >= scrollView.contentSize.height && bottomEdge > self.myTableView.frame.size.height && [self.listArray count] >= 20) 
    {
        _isAllowLoadingMore = YES;
    }
    else 
    {
        _isAllowLoadingMore = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //[self loadImagesForOnscreenRows];
}

#pragma mark -------private methods
- (void)popAction
{
    if (delegate != nil && [delegate respondsToSelector:@selector(getMyAddress)]) {
        [delegate getMyAddress];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)leftButtonPressed:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSArray *dbArr = [self.listArray objectAtIndex:btn.tag - 10000];
    NSString *infoId = [NSString stringWithFormat:@"%d",[[dbArr objectAtIndex:address_list_id] intValue]];
    self.prizeInfoId = [NSString stringWithFormat:@"%d",[[dbArr objectAtIndex:address_list_id] intValue]];
    
    if (__fromType == FromTypePrize) {
        if ([[dbArr objectAtIndex:address_list_isPrizeDefault] intValue] != 1) {
            
            NSMutableDictionary *jsontestDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [Common getSecureString],@"keyvalue",
                                                [NSNumber numberWithInt: SITE_ID],@"site_id",
                                                [NSNumber numberWithInt:[self.userId intValue]],@"user_id",
                                                [NSNumber numberWithInt:[infoId intValue]],@"id",nil];
            
            [[DataManager sharedManager] accessService:jsontestDic command:SETPRIZEADDRESS_COMMAND_ID accessAdress:@"luckdraw/setluckdrawAddress.do?param=%@" delegate:self withParam:jsontestDic];
        }
        
    }else if (__fromType == FromTypeReceive) {
        if ([[dbArr objectAtIndex:address_list_isReceiveDefault] intValue] != 1) {
            [DBOperate updateWithTwoConditions:T_ADDRESS_LIST theColumn:@"isReceiveDefault" theColumnValue:@"0" ColumnOne:@"memberId" valueOne:self.userId columnTwo:@"1" valueTwo:[NSNumber numberWithInt:1]];
            
            [DBOperate updateWithTwoConditions:T_ADDRESS_LIST theColumn:@"isReceiveDefault" theColumnValue:@"1" ColumnOne:@"memberId" valueOne:self.userId columnTwo:@"id" valueTwo:infoId];
            
            self.listArray = (NSMutableArray *)[DBOperate queryData:T_ADDRESS_LIST theColumn:@"memberId" theColumnValue:self.userId orderBy:@"updatetime" orderType:@"DESC" withAll:NO];
            
            [self.myTableView reloadData];
            
            NSArray *ay = [self.listArray objectAtIndex:btn.tag - 10000];
            self.info.per_name = [ay objectAtIndex:address_list_name];
            self.info.per_tel = [ay objectAtIndex:address_list_mobile];
            self.info.per_post = [ay objectAtIndex:address_list_zip_code];
            self.info.per_province = [ay objectAtIndex:address_list_province];
            self.info.per_city = [ay objectAtIndex:address_list_city];
            self.info.per_area = [ay objectAtIndex:address_list_area];
            self.info.per_detailAddress = [ay objectAtIndex:address_list_address];
            
            [self performSelector:@selector(popAction) withObject:nil afterDelay:1.0];
        }
    }
}

- (void)changeBtnAction:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    //NSLog(@"=====%d",btn.tag - 1);
    NSArray *ayArr = [self.listArray objectAtIndex:btn.tag - 1];
    
    ReservationInfo *_info = [[ReservationInfo alloc] init];
    _info.per_name = [ayArr objectAtIndex:address_list_name];
    _info.per_tel = [ayArr objectAtIndex:address_list_mobile];
    _info.per_post = [ayArr objectAtIndex:address_list_zip_code];
    _info.per_province = [ayArr objectAtIndex:address_list_province];
    _info.per_city = [ayArr objectAtIndex:address_list_city];
    _info.per_area = [ayArr objectAtIndex:address_list_area];
    _info.per_detailAddress = [ayArr objectAtIndex:address_list_address];
    
    AddReceivingAddressViewController *addAddr = [[AddReceivingAddressViewController alloc] initWithStyle:UITableViewStyleGrouped];
    addAddr.info = _info;
    addAddr.addrId = [NSString stringWithFormat:@"%d",[[ayArr objectAtIndex:address_list_id] intValue]];
    //NSLog(@"addAddr.addrId===%@",addAddr.addrId);
    if (__fromType == FromTypePrize) {
        addAddr._fromPrize = YES;
    }
    [self.navigationController pushViewController:addAddr animated:YES];
    [addAddr release];
    [_info release];
}

- (void)addAction
{
    AddReceivingAddressViewController *addAddr = [[AddReceivingAddressViewController alloc] initWithStyle:UITableViewStyleGrouped];
    if (__fromType == FromTypePrize) {
        addAddr.myAddress = self;
        addAddr._fromPrize = YES;
    }
    [self.navigationController pushViewController:addAddr animated:YES];
    [addAddr release];
}

- (void)accessMoreService
{
    int _update = [[[self.listArray objectAtIndex:[self.listArray count] - 1] objectAtIndex:address_list_updatetime] intValue];
    
    NSMutableDictionary *jsontestDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [Common getSecureString],@"keyvalue",
                                        [NSNumber numberWithInt: SITE_ID],@"site_id",
                                        [NSNumber numberWithInt:[self.userId intValue]],@"user_id",
                                        [NSNumber numberWithInt:_update],@"updatetime",nil];
    
    [[DataManager sharedManager] accessService:jsontestDic command:MEMBER_ADDRESSMORELIST_COMMAND_ID accessAdress:@"member/addresslist.do?param=%@" delegate:self withParam:jsontestDic];
}

- (void)accessService
{
    //添加loading图标
    UIActivityIndicatorView *tempSpinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    [tempSpinner setCenter:CGPointMake(self.view.frame.size.width / 3, self.view.frame.size.height / 2.0)];
    self.spinner = tempSpinner;
    
    UILabel *loadingLabel = [[UILabel alloc]initWithFrame:CGRectMake(30, 0, 100, 20)];
    loadingLabel.font = [UIFont systemFontOfSize:14];
    loadingLabel.textColor = [UIColor colorWithRed:0.5 green: 0.5 blue: 0.5 alpha:1.0];
    loadingLabel.text = LOADING_TIPS;		
    loadingLabel.textAlignment = UITextAlignmentCenter;
    loadingLabel.backgroundColor = [UIColor clearColor];
    [self.spinner addSubview:loadingLabel];
    [self.view addSubview:self.spinner];
    [self.spinner startAnimating];
    [tempSpinner release];
    
    NSMutableDictionary *jsontestDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [Common getSecureString],@"keyvalue",
                                        [NSNumber numberWithInt: SITE_ID],@"site_id",
                                        [NSNumber numberWithInt:[self.userId intValue]],@"user_id",nil];
    
    [[DataManager sharedManager] accessService:jsontestDic command:MEMBER_ADDRESSLIST_COMMAND_ID accessAdress:@"member/addresslist.do?param=%@" delegate:self withParam:jsontestDic];
}

- (void)didFinishCommand:(NSMutableArray*)resultArray cmd:(int)commandid withVersion:(int)ver{
	NSLog(@"information finish");
	NSLog(@"=====%@",resultArray);
    switch (commandid) {
        case MEMBER_ADDRESSLIST_COMMAND_ID:
        {
            [self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
        }
            break;
        case MEMBER_ADDRESSDELETE_COMMAND_ID:
        {
            [self performSelectorOnMainThread:@selector(deleteResult:) withObject:resultArray waitUntilDone:NO];
        }
            break;
        case MEMBER_ADDRESSMORELIST_COMMAND_ID:
        {
            [self performSelectorOnMainThread:@selector(getMoreResult:) withObject:resultArray waitUntilDone:NO];
        }
            break;
        case SETPRIZEADDRESS_COMMAND_ID:
        {
            [self performSelectorOnMainThread:@selector(setPrizeAddressResult:) withObject:resultArray waitUntilDone:NO];
        }
            break;
            
        default:
            break;
    }
}

- (void)update
{
    //移出loading
    [self.spinner removeFromSuperview];
    
    self.listArray = (NSMutableArray *)[DBOperate queryData:T_ADDRESS_LIST theColumn:@"memberId" theColumnValue:self.userId orderBy:@"updatetime" orderType:@"DESC" withAll:NO];
    
    if (noLabel != nil) {
        [noLabel removeFromSuperview];
    }
    
    if ([self.listArray count] == 0) {
        self.myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        noLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
        noLabel.text = @"您还未添加常用地址信息";
        noLabel.backgroundColor = [UIColor clearColor];
        noLabel.textColor = [UIColor grayColor];
        noLabel.textAlignment = UITextAlignmentCenter;
        noLabel.font = [UIFont systemFontOfSize:16.0f];
        [self.view addSubview:noLabel];
    }
    [self.myTableView reloadData];
}

- (void)getMoreResult:(NSMutableArray *)resultArray
{
	UILabel *label = (UILabel*)[self.myTableView viewWithTag:200];
	label.text = @"上拉加载更多";	
	[indicatorView stopAnimating];
    _loadingMore = NO;
	
	for (int i = 0; i < [resultArray count];i++ ) 
	{
		NSMutableArray *item = [resultArray objectAtIndex:i];
		[self.listArray addObject:item];
	}
	//NSLog(@"self.listArray========%@",self.listArray);

    NSMutableArray *insertIndexPaths = [NSMutableArray arrayWithCapacity:[resultArray count]];
    for (int ind = 0; ind < [resultArray count]; ind ++) 
    {
        NSIndexPath *newPath = [NSIndexPath indexPathForRow:
                                [self.listArray indexOfObject:[resultArray objectAtIndex:ind]] inSection:0];
        [insertIndexPaths addObject:newPath];
    }
    [self.myTableView insertRowsAtIndexPaths:insertIndexPaths 
                            withRowAnimation:UITableViewRowAnimationFade];
}

- (void)deleteResult:(NSMutableArray *)resultArray
{
	int retInt = [[resultArray objectAtIndex:0] intValue];
	if (retInt == 1) {
        [DBOperate deleteDataWithTwoConditions:T_ADDRESS_LIST columnOne:@"id" valueOne:[NSString stringWithFormat:@"%d",[_infoId intValue]] columnTwo:@"memberId" valueTwo:self.userId];
        
        [self.listArray removeObjectAtIndex:rowValue];
        
        NSMutableArray *deleteIndexPaths = [[NSMutableArray alloc] init];
        NSIndexPath *newPath = [NSIndexPath indexPathForRow:rowValue inSection:0];
        [deleteIndexPaths addObject:newPath];
        [self.myTableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
        [deleteIndexPaths release];
		
        self.listArray = (NSMutableArray *)[DBOperate queryData:T_ADDRESS_LIST theColumn:@"memberId" theColumnValue:self.userId orderBy:@"updatetime" orderType:@"DESC" withAll:NO];
        
        [self.myTableView reloadData];
        
        if (noLabel != nil) {
            [noLabel removeFromSuperview];
        }
        
		if ([self.listArray count] == 0) {
			self.myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
			noLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
			noLabel.text = @"您还未添加常用地址信息";
			noLabel.backgroundColor = [UIColor clearColor];
			noLabel.textColor = [UIColor grayColor];
			noLabel.textAlignment = UITextAlignmentCenter;
			noLabel.font = [UIFont systemFontOfSize:16.0f];
			[self.view addSubview:noLabel];
		}
	}else {
		MBProgressHUD *mbprogressHUD = [[MBProgressHUD alloc] initWithView:self.view];
		mbprogressHUD.delegate = self;
		mbprogressHUD.customView= [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"提示icon-信息.png"]] autorelease];
		mbprogressHUD.mode = MBProgressHUDModeCustomView; 
		mbprogressHUD.labelText = @"删除失败";
		[self.view addSubview:mbprogressHUD];
		[self.view bringSubviewToFront:mbprogressHUD];
		[mbprogressHUD show:YES];
		[mbprogressHUD hide:YES afterDelay:1];
		[mbprogressHUD release];
	}
}

- (void)setPrizeAddressResult:(NSMutableArray *)resultArray
{
    int retInt = [[resultArray objectAtIndex:0] intValue];
	if (retInt == 1) {
        [DBOperate updateWithTwoConditions:T_ADDRESS_LIST theColumn:@"isPrizeDefault" theColumnValue:@"0" ColumnOne:@"memberId" valueOne:self.userId columnTwo:@"1" valueTwo:[NSNumber numberWithInt:1]];
        
        [DBOperate updateWithTwoConditions:T_ADDRESS_LIST theColumn:@"isPrizeDefault" theColumnValue:@"1" ColumnOne:@"memberId" valueOne:self.userId columnTwo:@"id" valueTwo:self.prizeInfoId];
        self.listArray = (NSMutableArray *)[DBOperate queryData:T_ADDRESS_LIST theColumn:@"memberId" theColumnValue:self.userId orderBy:@"updatetime" orderType:@"DESC" withAll:NO];
        
        [self.myTableView reloadData];
        [self performSelector:@selector(popAction) withObject:nil afterDelay:1.0];
	}else {
		MBProgressHUD *mbprogressHUD = [[MBProgressHUD alloc] initWithView:self.view];
		mbprogressHUD.delegate = self;
		mbprogressHUD.customView= [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"提示icon-信息.png"]] autorelease];
		mbprogressHUD.mode = MBProgressHUDModeCustomView;
		mbprogressHUD.labelText = @"设置地址失败";
		[self.view addSubview:mbprogressHUD];
		[self.view bringSubviewToFront:mbprogressHUD];
		[mbprogressHUD show:YES];
		[mbprogressHUD hide:YES afterDelay:1];
		[mbprogressHUD release];
	}
}
@end
