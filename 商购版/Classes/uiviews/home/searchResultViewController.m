//
//  searchResultViewController.m
//  searchResult
//
//  Created by siphp on 13-01-05.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "searchResultViewController.h"
#import "Common.h"
#import "DBOperate.h"
#import "UIImageScale.h"
#import "FileManager.h"
#import "downloadParam.h"
#import "imageDownLoadInWaitingObject.h"
#import "productTableCellViewController.h"
#import "ProductDetailViewController.h"

@implementation searchResultViewController

@synthesize myTableView;
@synthesize productItems;
@synthesize spinner;
@synthesize moreLabel;
@synthesize _loadingMore;
@synthesize imageDownloadsInProgress;
@synthesize imageDownloadsInWaiting;
@synthesize keyWord;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:BG_IMAGE]];
    
    self.title = [NSString stringWithFormat:@"搜索 %@",self.keyWord] ;
    
    NSMutableArray *tempProductItems = [[NSMutableArray alloc] init];
	self.productItems = tempProductItems;
	[tempProductItems release];
    
    NSMutableDictionary *idip = [[NSMutableDictionary alloc]init];
	self.imageDownloadsInProgress = idip;
	[idip release];
	
	NSMutableArray *wait = [[NSMutableArray alloc]init];
	self.imageDownloadsInWaiting = wait;
	[wait release];

    picWidth = 70.0f;
    picHeight = 70.0f;
    
    currentPageNo = 2;
    
    //增加的遮盖图层
    UIImage *coverImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"上bar底部遮盖" ofType:@"png"]];
    UIImageView *coverImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0.0f , 0.0f , coverImage.size.width , coverImage.size.height)];
    coverImageView.image = coverImage;
    [coverImage release];
    [self.view addSubview:coverImageView];
	[coverImageView release];
    
    //添加loading图标
    UIActivityIndicatorView *tempSpinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    [tempSpinner setCenter:CGPointMake(self.view.frame.size.width / 3, self.view.frame.size.height / 2.0 - 20.0f)];
    self.spinner = tempSpinner;
    
    UILabel *loadingLabel = [[UILabel alloc]initWithFrame:CGRectMake(30, 0, 100, 20)];
    loadingLabel.font = [UIFont systemFontOfSize:14];
    loadingLabel.textColor = [UIColor colorWithRed:0.5 green: 0.5 blue: 0.5 alpha:1.0];
    loadingLabel.text = LOADING_TIPS;		
    loadingLabel.textAlignment = UITextAlignmentCenter;
    loadingLabel.backgroundColor = [UIColor clearColor];
    [self.spinner addSubview:loadingLabel];
    [loadingLabel release];
    [self.view addSubview:self.spinner];
    [self.spinner startAnimating];
    [tempSpinner release];
    
    //网络获取
    [self accessItemService];
    
}

-(void) viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
}

//添加数据表视图
-(void)addTableView;
{
	UITableView *tempTableView = [[UITableView alloc] initWithFrame:CGRectMake( 0.0f , 0.0f , self.view.frame.size.width , self.view.frame.size.height)];
    [tempTableView setDelegate:self];
    [tempTableView setDataSource:self];
    tempTableView.scrollsToTop = YES;
    self.myTableView = tempTableView;
    [tempTableView release];
    self.myTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:myTableView];
    [self.view sendSubviewToBack:self.myTableView];
    [self.myTableView reloadData];
    
    //分割线
    self.myTableView.separatorColor = [UIColor clearColor];
    
    //遮盖物离顶部距离
    UIImage *coverImage = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"上bar底部遮盖" ofType:@"png"]];
    UIView *topMarginView = [[UIView alloc] initWithFrame:CGRectMake(0.0f , 0.0f , self.view.frame.size.width , coverImage.size.height)];
    [coverImage release];
    self.myTableView.tableHeaderView = topMarginView;
    [topMarginView release];
    
}

//滚动loading图片
- (void)loadImagesForOnscreenRows
{
    NSArray *visiblePaths = [self.myTableView indexPathsForVisibleRows];
	for (NSIndexPath *indexPath in visiblePaths)
	{
		int countItems = [self.productItems count];
		if (countItems >[indexPath row])
		{
            productTableCellViewController *productTableCell = (productTableCellViewController *)[self.myTableView cellForRowAtIndexPath:indexPath];
            
            NSArray *productArray = [self.productItems objectAtIndex:[indexPath row]];
			NSString *picUrl = [productArray objectAtIndex:product_pic];
            NSString *picName = [Common encodeBase64:(NSMutableData *)[picUrl dataUsingEncoding: NSUTF8StringEncoding]];
            
            if (picUrl.length > 1) 
            {
                UIImage *pic = [[FileManager getPhoto:picName] fillSize:CGSizeMake(picWidth, picHeight)];
                if (pic.size.width > 2)
                {
                    productTableCell.picView.image = pic;
                }
                else
                {
                    UIImage *defaultPic = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"商品列表默认图片" ofType:@"png"]];
                    productTableCell.picView.image = [defaultPic fillSize:CGSizeMake(picWidth, picHeight)];
                    
                    if (self.myTableView.dragging == NO && self.myTableView.decelerating == NO)
                    {
                        [self startIconDownload:picUrl forIndexPath:indexPath];
                    }
                }
            }
            else
            {
                UIImage *defaultPic = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"商品列表默认图片" ofType:@"png"]];
                productTableCell.picView.image = [defaultPic fillSize:CGSizeMake(picWidth, picHeight)];
            }
			
		}
		
	}
}

//保存缓存图片
-(bool)savePhoto:(UIImage*)photo atIndexPath:(NSIndexPath*)indexPath
{
    int countItems = [self.productItems count];
	
	if (countItems > [indexPath row]) 
	{
		NSArray *productArray = [self.productItems objectAtIndex:[indexPath row]];
        NSString *picUrl = [productArray objectAtIndex:product_pic];
        NSString *picName = [Common encodeBase64:(NSMutableData *)[picUrl dataUsingEncoding: NSUTF8StringEncoding]];
        
		//保存缓存图片
		if([FileManager savePhoto:picName withImage:photo])
		{
			return YES;
		}
		else 
		{
			return NO;
		}
		
	}
	return NO;
}

//获取网络图片
- (void)startIconDownload:(NSString*)photoURL forIndexPath:(NSIndexPath*)indexPath
{
    IconDownLoader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil && photoURL != nil && photoURL.length > 1) 
    {
		if ([imageDownloadsInProgress count]>= 5) {
			imageDownLoadInWaitingObject *one = [[imageDownLoadInWaitingObject alloc]init:photoURL withIndexPath:indexPath withImageType:CUSTOMER_PHOTO];
			[imageDownloadsInWaiting addObject:one];
			[one release];
			return;
		}
        IconDownLoader *iconDownloader = [[IconDownLoader alloc] init];
        iconDownloader.downloadURL = photoURL;
        iconDownloader.indexPathInTableView = indexPath;
		iconDownloader.imageType = CUSTOMER_PHOTO;
        iconDownloader.delegate = self;
        [imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload];
        [iconDownloader release];
    }
}

//回调 获到网络图片后的回调函数
- (void)appImageDidLoad:(NSIndexPath *)indexPath withImageType:(int)Type
{
    IconDownLoader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader != nil)
    {
        productTableCellViewController *productTableCell = (productTableCellViewController *)[self.myTableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        
        // Display the newly loaded image
		if(iconDownloader.cardIcon.size.width>2.0)
		{ 
			//保存图片
			[self savePhoto:iconDownloader.cardIcon atIndexPath:indexPath];
			
			UIImage *pic = [iconDownloader.cardIcon fillSize:CGSizeMake(picWidth, picHeight)];
			productTableCell.picView.image = pic;
		}
		
		[imageDownloadsInProgress removeObjectForKey:indexPath];
		if ([imageDownloadsInWaiting count]>0) 
		{
			imageDownLoadInWaitingObject *one = [imageDownloadsInWaiting objectAtIndex:0];
			[self startIconDownload:one.imageURL forIndexPath:one.indexPath];
			[imageDownloadsInWaiting removeObjectAtIndex:0];
		}
		
    }
}

//更新记录
-(void)update
{
    //添加表
    [self addTableView];
    
    //回归常态
    [self backNormal];
    
}

//更多的操作
-(void)appendTableWith:(NSMutableArray *)data
{
    //合并数据
	if (data != nil && [data count] > 0) 
	{
		for (int i = 0; i < [data count];i++ ) 
		{
			NSArray *productArray = [data objectAtIndex:i];
			[self.productItems addObject:productArray];
		}
		
		NSMutableArray *insertIndexPaths = [NSMutableArray arrayWithCapacity:[data count]];
		for (int ind = 0; ind < [data count]; ind++) 
		{
			NSIndexPath *newPath = [NSIndexPath indexPathForRow:[self.productItems indexOfObject:[data objectAtIndex:ind]] inSection:0];
			[insertIndexPaths addObject:newPath];
		}
		[self.myTableView insertRowsAtIndexPaths:insertIndexPaths 
								withRowAnimation:UITableViewRowAnimationFade];
        
        //页数自增
        currentPageNo = currentPageNo + 1;
		
	}	
	
	[self moreBackNormal];
}


//网络获取数据
-(void)accessItemService
{
    NSString *reqUrl = @"search.do?param=%@";
	
	NSDictionary *jsontestDic = [NSDictionary dictionaryWithObjectsAndKeys:
								 [Common getSecureString],@"keyvalue",
								 [NSNumber numberWithInt: SITE_ID],@"site_id",
                                 self.keyWord,@"keywords",
								 [NSNumber numberWithInt: 1],@"page_no",
								 nil];
	
	[[DataManager sharedManager] accessService:jsontestDic
									   command:OPERAT_SEARCH_REFRESH 
								  accessAdress:reqUrl 
									  delegate:self
									 withParam:nil];
}

//网络获取更多数据
-(void)accessMoreService
{
    NSString *reqUrl = @"search.do?param=%@";
	
	NSDictionary *jsontestDic = [NSDictionary dictionaryWithObjectsAndKeys:
								 [Common getSecureString],@"keyvalue",
								 [NSNumber numberWithInt: SITE_ID],@"site_id",
                                 self.keyWord,@"keywords",
								 [NSNumber numberWithInt: currentPageNo],@"page_no",
								 nil];
	
	[[DataManager sharedManager] accessService:jsontestDic
									   command:OPERAT_SEARCH_MORE 
								  accessAdress:reqUrl 
									  delegate:self
									 withParam:nil];

}

//回归常态
-(void)backNormal
{
    //移出loading
    [self.spinner removeFromSuperview];
}

//更多回归常态
-(void)moreBackNormal
{
    _loadingMore = NO;
    
	//loading图标移除
	if (self.spinner != nil) {
		[self.spinner stopAnimating];
	}
    
	if (self.moreLabel) {
        self.moreLabel.text = @"上拉加载更多";	
    }
	
}

//网络请求回调函数
- (void)didFinishCommand:(NSMutableArray*)resultArray cmd:(int)commandid withVersion:(int)ver
{
    switch(commandid)
    {
        //搜索刷新
        case OPERAT_SEARCH_REFRESH:
            self.productItems = resultArray;
            [self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
            break;
            
        //搜索更多
        case OPERAT_SEARCH_MORE:
            [self performSelectorOnMainThread:@selector(appendTableWith:) withObject:resultArray waitUntilDone:NO];
            break;
            
        default:   ;
    }
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([self.productItems count] >= 20)
    {
        return [self.productItems count] + 1;
    }
    else
    {
        if ([self.productItems count] == 0)
        {
            return 1;
        }
        else
        {
            return [self.productItems count];
        }
    }
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.productItems != nil && [self.productItems count] > 0)
    {
        if ([indexPath row] == [self.productItems count])
        {
            //更多
            return 50.0f;
        }
        else 
        {
            //记录
            return 86.0f;
        }
    }
    else
    {
        //没有记录
        return 50.0f;
    }
	
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *CellIdentifier = @"";
	UITableViewCell *cell;
	
	int productItemsCount =  [self.productItems count];
    int cellType;
    if (self.productItems != nil && productItemsCount > 0)
    {
        if ([indexPath row] == productItemsCount)
        {
            //更多
            CellIdentifier = @"moreCell";
            cellType = 1;
        }
        else 
        {
            //记录
            CellIdentifier = @"listCell";
            cellType = 2;
        }
    }
    else
    {
        //没有记录
        CellIdentifier = @"noneCell";
        cellType = 0;
    }
	
	cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) 
	{
        switch(cellType)
		{
            //没有记录
			case 0:
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                self.myTableView.separatorColor = [UIColor clearColor];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                UILabel *noneLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 300, 30)];
				noneLabel.tag = 101;
				[noneLabel setFont:[UIFont systemFontOfSize:12.0f]];
				noneLabel.textColor = [UIColor colorWithRed:0.3 green: 0.3 blue: 0.3 alpha:1.0];
				noneLabel.text = @"抱歉，没有找到符合条件的商品";			
				noneLabel.textAlignment = UITextAlignmentCenter;
				noneLabel.backgroundColor = [UIColor clearColor];
				[cell.contentView addSubview:noneLabel];
				[noneLabel release];
                
                break;
            }
            //更多
			case 1:
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                self.myTableView.separatorColor = [UIColor clearColor];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                UILabel *tempMoreLabel = [[UILabel alloc]initWithFrame:CGRectMake(105, 10, 120, 30)];
                tempMoreLabel.tag = 200;
                [tempMoreLabel setFont:[UIFont systemFontOfSize:14.0f]];
				tempMoreLabel.textColor = [UIColor colorWithRed:0.3 green: 0.3 blue: 0.3 alpha:1.0];
                tempMoreLabel.text = @"上拉加载更多";			
                tempMoreLabel.textAlignment = UITextAlignmentCenter;
                tempMoreLabel.backgroundColor = [UIColor clearColor];
                self.moreLabel = tempMoreLabel;
                [tempMoreLabel release];
                [cell.contentView addSubview:self.moreLabel];
                cell.tag = 201;
                break;
            }
            //记录
			case 2:
            {
                cell = [[[productTableCellViewController alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                
                break;
            }
				
			default:   ;
		}
        
        cell.backgroundColor = [UIColor clearColor];
	}
	
	if (cellType == 2)
    {
        //数据填充
        NSArray *productArray = [self.productItems objectAtIndex:[indexPath row]];
        
        productTableCellViewController *productTableCell = (productTableCellViewController *)cell;
        
        //标题
        productTableCell.titleLabel.text = [productArray objectAtIndex:product_title];
        
        //价格判断
        if ([[productArray objectAtIndex:product_promotion_price] intValue] != 0 && [[productArray objectAtIndex:product_promotion_price] length] > 0) 
        {
            //有优惠价格
            productTableCell.originalLabel.hidden = NO;
            productTableCell.lineView.hidden = NO;
            
            NSString *priceString = [NSString stringWithFormat:@"￥%@",[productArray objectAtIndex:product_promotion_price]];
            CGSize constraint = CGSizeMake(20000.0f, 20.0f);
            CGSize size = [priceString sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
            CGFloat fixWidth = (size.width + 5.0f) > 60.0f ? 60.0f : (size.width + 5.0f);
            
            productTableCell.priceLabel.frame = CGRectMake( productTableCell.priceLabel.frame.origin.x, productTableCell.priceLabel.frame.origin.y , fixWidth , productTableCell.priceLabel.frame.size.height) ;
            
            
            NSString *originalString = [NSString stringWithFormat:@"/ ￥%@",[productArray objectAtIndex:product_price]];
            
            CGSize constraint1 = CGSizeMake(20000.0f, 20.0f);
            CGSize size1 = [originalString sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:constraint1 lineBreakMode:UILineBreakModeWordWrap];
            CGFloat fixWidth1 = (size1.width + 5.0f) > 60.0f ? 60.0f : (size1.width + 5.0f);
            
            productTableCell.originalLabel.frame = CGRectMake( CGRectGetMaxX(productTableCell.priceLabel.frame), productTableCell.originalLabel.frame.origin.y , fixWidth1 , productTableCell.originalLabel.frame.size.height) ;
            
            productTableCell.lineView.frame = CGRectMake( CGRectGetMaxX(productTableCell.priceLabel.frame) + 5.0f, productTableCell.lineView.frame.origin.y , fixWidth1 - 12.0f , productTableCell.lineView.frame.size.height) ;
            
            productTableCell.priceLabel.text = priceString;
            productTableCell.originalLabel.text = originalString;
        }
        else
        {
            //没有优惠价格
            productTableCell.originalLabel.hidden = YES;
            productTableCell.lineView.hidden = YES;
            
            NSString *priceString = [NSString stringWithFormat:@"￥%@",[productArray objectAtIndex:product_price]];
            
            CGSize constraint = CGSizeMake(20000.0f, 20.0f);
            CGSize size = [priceString sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
            CGFloat fixWidth = (size.width + 5.0f) > 120.0f ? 120.0f : (size.width + 5.0f);
            
            productTableCell.priceLabel.frame = CGRectMake( productTableCell.priceLabel.frame.origin.x, productTableCell.priceLabel.frame.origin.y , fixWidth , productTableCell.priceLabel.frame.size.height) ;
            
            productTableCell.priceLabel.text = priceString;
            productTableCell.originalLabel.text = @"";
        }
        
        //喜欢
        productTableCell.likeLabel.text = [productArray objectAtIndex:product_likes];
        
        //评论
        productTableCell.commentLabel.text = [productArray objectAtIndex:product_comment_num];
        
        //图片
        NSString *picUrl = [productArray objectAtIndex:product_pic];
        NSString *picName = [Common encodeBase64:(NSMutableData *)[picUrl dataUsingEncoding: NSUTF8StringEncoding]];
        
        if (picUrl.length > 1) 
        {
            UIImage *pic = [[FileManager getPhoto:picName] fillSize:CGSizeMake(picWidth, picHeight)];
            if (pic.size.width > 2)
            {
                productTableCell.picView.image = pic;
            }
            else
            {
                UIImage *defaultPic = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"商品列表默认图片" ofType:@"png"]];
                productTableCell.picView.image = [defaultPic fillSize:CGSizeMake(picWidth, picHeight)];
                
				if (tableView.dragging == NO && tableView.decelerating == NO)
				{
					[self startIconDownload:picUrl forIndexPath:indexPath];
				}
            }
        }
        else
        {
            UIImage *defaultPic = [[UIImage alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"商品列表默认图片" ofType:@"png"]];
            productTableCell.picView.image = [defaultPic fillSize:CGSizeMake(picWidth, picHeight)];
        }
        
        return productTableCell;
        
	}
    
    return cell; 
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
    int countItems = [self.productItems count];
	
	if (countItems > [indexPath row]) 
    {
        NSArray *productArray = [self.productItems objectAtIndex:[indexPath row]];
        ProductDetailViewController *ProductDetailView = [[ProductDetailViewController alloc] init];
        ProductDetailView.productID = [[productArray objectAtIndex:product_id] intValue];
        //ProductDetailView.productList = self.productItems;
        [self.navigationController pushViewController:ProductDetailView animated:YES];
        [ProductDetailView release];
    }
    
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (_isAllowLoadingMore && !_loadingMore && [self.productItems count] > 0)
    {
        float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
        if (bottomEdge > scrollView.contentSize.height + 10.0f) 
        {
            //松开 载入更多
            self.moreLabel.text=@"松开加载更多";
            
        }
        else
        {
            self.moreLabel.text=@"上拉加载更多";
        }
    }

}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	//[super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    if (!decelerate)
	{
		[self loadImagesForOnscreenRows];
    }
    
    if (_isAllowLoadingMore && !_loadingMore)
    {
        float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
        if (bottomEdge > scrollView.contentSize.height + 10.0f) 
        {
            //松开 载入更多
            _loadingMore = YES;
            
            self.moreLabel.text=@" 加载中 ...";
            
            UITableViewCell *cell = (UITableViewCell *)[self.myTableView viewWithTag:201];
            
            //添加loading图标
            UIActivityIndicatorView *tempSpinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
            [tempSpinner setCenter:CGPointMake(cell.frame.size.width / 3, cell.frame.size.height / 2.0)];
            self.spinner = tempSpinner;
            [cell.contentView addSubview:self.spinner];
            [self.spinner startAnimating];
            [tempSpinner release];
            
            //数据
            [self accessMoreService];
        }
        else
        {
            self.moreLabel.text=@"上拉加载更多";
        }
    }
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    
    float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
    if (bottomEdge >= scrollView.contentSize.height && bottomEdge > self.myTableView.frame.size.height && [self.productItems count] >= 20) 
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
    [self loadImagesForOnscreenRows];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
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
    
	self.myTableView.delegate = nil;
	self.myTableView = nil;
    self.productItems = nil;
	self.spinner = nil;
    self.moreLabel = nil;
    for (IconDownLoader *one in [imageDownloadsInProgress allValues]){
		one.delegate = nil;
	}
	self.imageDownloadsInProgress = nil;
	self.imageDownloadsInWaiting = nil;
    self.keyWord = nil;
}


- (void)dealloc {
	self.myTableView.delegate = nil;
	self.myTableView = nil;
    self.productItems = nil;
	self.spinner = nil;
    self.moreLabel = nil;
    for (IconDownLoader *one in [imageDownloadsInProgress allValues]){
		one.delegate = nil;
	}
	self.imageDownloadsInProgress = nil;
	self.imageDownloadsInWaiting = nil;
    self.keyWord = nil;
    [super dealloc];
}

@end
