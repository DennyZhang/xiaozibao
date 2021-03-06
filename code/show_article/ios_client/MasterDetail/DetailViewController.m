//
//  DetailViewController.m
//  MasterDetail
//
//  Created by mac on 13-7-13.
//  Copyright (c) 2013年 mac. All rights reserved.
//

#import "DetailViewController.h"
#import "AFJSONRequestOperation.h"
#import "AFHTTPClient.h"

@interface DetailViewController () {
    NSTimeInterval startTime;
    UIActivityIndicatorView *activityIndicator;
}
@end

@implementation DetailViewController
@synthesize detailItem, scrollView, questionTextView, detailUITextView;
@synthesize shouldShowCoin, coinButton, adContainerView, bannerIsVisible;

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"DetailViewController load");
    if (floor(NSFoundationVersionNumber) == NSFoundationVersionNumber_iOS_6_1) {
      [self.navigationController.navigationBar setTintColor:
                                      [UIColor colorWithRed:40.0/255.0 green:108.0/255.0 blue:179.0/255.0 alpha:1.0f]];
    }

    [[MyToolTip singleton] reset:self.view]; // reset popTipView
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //NSLog(@"self.detailItem.readcount: %d", [self.detailItem.readcount intValue]);
    if ([self.detailItem.readcount intValue] == 1){
        [UserProfile addInteger:self.detailItem.category key:POST_VISIT_KEY offset:1];
    }
    // update readcount
    self.detailItem.readcount = [NSNumber numberWithInt:(1+[self.detailItem.readcount intValue])];
    
    [PostsSqlite addPostReadCount:self.detailItem.postid category:self.detailItem.category];
    
    // hide navigationbar
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    self.scrollView = [[UIScrollView alloc] init];
    scrollView.frame =CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:scrollView];
    
    [self addMenuCompoents];
    [self addPostComponents];
    [self configureLayout];
    
    // configure tooltip
    // ToolTip
    UIButton *tooltipSwipeBtn = [[UIButton alloc]
                                 initWithFrame:CGRectMake(90.0f, self.detailUITextView.frame.origin.y + 5, 0, 0)];
    [self.view addSubview:tooltipSwipeBtn];
    
    [[MyToolTip singleton] addToolTip:tooltipSwipeBtn msg:@"Swipe right to go back."];
    [[MyToolTip singleton] addToolTip:self.navigationItem.leftBarButtonItem msg:@"Click to see more."];
    
    [[MyToolTip singleton] addToolTip:(UIButton *)[self.view viewWithTag:TAG_BUTTON_VOTEDOWN]
                                  msg:@"Click to voteup, votedown, or save to local."];
    
    [[MyToolTip singleton] addToolTip:(UIButton *)[self.view viewWithTag:TAG_BUTTON_INFO]
                                  msg:@"Click to see the original web page link."];
    
    [[MyToolTip singleton] showToolTip];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - user defined event selectors
-(IBAction) barButtonEvent:(id)sender
{
    UIButton* btn = sender;
    if (btn.tag == TAG_BUTTON_COIN_DETAILVIEW) {
        ReviewViewController *reviewViewController = [[ReviewViewController alloc]init];
        
        self.navigationController.navigationBarHidden = NO;
        reviewViewController.category = self.detailItem.category;
        [self.navigationController pushViewController:reviewViewController animated:YES];
    }
    
    if (btn.tag == TAG_BUTTON_VOTEUP || btn.tag == TAG_BUTTON_VOTEDOWN || btn.tag == TAG_BUTTON_FAVORITE) {
        if ([ComponentUtil shouldMixpanel]) {
            [[Mixpanel sharedInstance] track:@"question_feedback_count" properties:@{
                                                                                     @"category": self.detailItem.category,
                                                                                     @"userid": [ComponentUtil getUserId]
                                                                                     }];
        }
        // mark locally, then send request to remote server
        NSString* imgName = @"";
        NSString* fieldName = @"";
        BOOL boolValue = false;
        if (btn.tag == TAG_BUTTON_VOTEUP) {
            // exclusive check
            if ((detailItem.isvoteup == FALSE) && (detailItem.isvotedown == TRUE)) {
                NSString* msg = @"You can only either voteup or votedown the same post.";
                [ComponentUtil infoMessage:nil msg:msg enforceMsgBox:TRUE];
                return;
            }
            
            imgName = (detailItem.isvoteup == NO)?@"thumbs_up-512.png":@"thumb_up-512.png";
            detailItem.isvoteup = !detailItem.isvoteup;
            fieldName = @"isvoteup";
            boolValue = detailItem.isvoteup;
            NSLog(@"detailItem.isvoteup:%d, imgName:%@", detailItem.isvoteup, imgName);
            if (boolValue) {
                [UserProfile addInteger:self.detailItem.category key:POST_VOTEUP_KEY offset:1];
            }
            else {
                [UserProfile addInteger:self.detailItem.category key:POST_VOTEUP_KEY offset:-1];
            }
        }
        if (btn.tag == TAG_BUTTON_VOTEDOWN) {
            // exclusive check
            if ((detailItem.isvotedown == FALSE) && (detailItem.isvoteup == TRUE)) {
                NSString* msg = @"You can only either voteup or votedown the same post.";
                [ComponentUtil infoMessage:nil msg:msg enforceMsgBox:TRUE];
                return;
            }
            
            imgName = (detailItem.isvotedown == NO)?@"thumbs_down-512.png":@"thumb_down-512.png";
            detailItem.isvotedown = !detailItem.isvotedown;
            fieldName = @"isvotedown";
            boolValue = detailItem.isvotedown;
            if (boolValue) {
                [UserProfile addInteger:self.detailItem.category key:POST_VOTEDOWN_KEY offset:1];
            }
            else {
                [UserProfile addInteger:self.detailItem.category key:POST_VOTEDOWN_KEY offset:-1];
            }
        }
        if (btn.tag == TAG_BUTTON_FAVORITE) {
            imgName = (detailItem.isfavorite == NO)?@"hearts-512.png":@"heart-512.png";
            detailItem.isfavorite = ! detailItem.isfavorite;
            fieldName = @"isfavorite";
            boolValue = detailItem.isfavorite;
            if (boolValue) {
                [UserProfile addInteger:self.detailItem.category key:POST_FAVORITE_KEY offset:1];
            }
            else {
                [UserProfile addInteger:self.detailItem.category key:POST_FAVORITE_KEY offset:-1];
            }
        }
        
        [PostsSqlite updatePostBoolField:detailItem.postid boolValue:boolValue
                               fieldName:fieldName category:detailItem.category];
        [btn setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
        
        NSString* userid = [[NSUserDefaults standardUserDefaults] stringForKey:@"Userid"];
        NSLog(@"userid:%@", userid);
        [self feedbackPost:userid
                    postid:detailItem.postid
                  category:detailItem.category btn:btn];
        
        // tell client where to find favorite questions
        if (btn.tag == TAG_BUTTON_FAVORITE) {
            NSString* msg = @"Save the question to as favorite.\nSee: Preference --> Saved questions";
            if (detailItem.isfavorite == NO) {
                msg = @"Unsave the question";
            }
            [ComponentUtil showHintOnce:btn msg:msg];
        }
    }
    [ComponentUtil updateScoreText:self.detailItem.category btn:self.coinButton tag:TAG_SCORE_TEXT];
}

- (void) feedbackPost:(NSString*) userid
               postid:(NSString*) postid
             category:(NSString*) category
                  btn:(UIButton *) btn
{
    NSString *urlStr=SERVERURL;
    NSURL *url = [NSURL URLWithString:urlStr];
    
    NSString* comment = INVALID_STRING;
    if (btn.tag == TAG_BUTTON_VOTEUP) {
        if (detailItem.isvoteup)
            comment = FEEDBACK_ENVOTEUP;
        else
            comment = FEEDBACK_DEVOTEUP;
    }
    if (btn.tag == TAG_BUTTON_VOTEDOWN) {
        if (detailItem.isvotedown)
            comment = FEEDBACK_ENVOTEDOWN;
        else
            comment = FEEDBACK_DEVOTEDOWN;
    }
    if (btn.tag == TAG_BUTTON_FAVORITE) {
        if (detailItem.isfavorite)
            comment = FEEDBACK_ENFAVORITE;
        else
            comment = FEEDBACK_DEFAVORITE;
    }
    
    comment = [NSString stringWithFormat:@"%@%@score=%d", comment, FIELD_SEPARATOR,
               (int)[UserProfile scoreByCategory:self.detailItem.category]];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            userid, @"uid", postid, @"postid",
                            category, @"category", comment, @"comment",
                            nil];
    NSLog(@"feedbackPost, url:%@, postid:%@, comment:%@", urlStr, postid, comment);
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:url];
    NSURLRequest *request = [client requestWithMethod:@"POST" path:@"api_feedback_post" parameters:params];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSString *status = [JSON valueForKeyPath:@"status"];
        if ([status isEqualToString:@"ok"]) {
            NSLog(@"perform operation after success");
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:
                                  [JSON valueForKeyPath:@"errmsg"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [ComponentUtil infoMessage:@"Error to send feed back"
                               msg:[NSString stringWithFormat:@"url:%@, error:%@", urlStr, error]
                     enforceMsgBox:FALSE];
        
    }];
    [operation start];
}

#pragma mark - Private functions
- (void)addMenuCompoents
{
    UIButton *btn;
    if ([self.shouldShowCoin intValue] == 1) {
        btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setFrame:CGRectMake(0.0f, 0.0f, ICON_WIDTH, ICON_HEIGHT)];
        [btn addTarget:self action:@selector(barButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = TAG_BUTTON_COIN_DETAILVIEW;
        [btn setImage:[UIImage imageNamed:@"coin.png"] forState:UIControlStateNormal];
        self.coinButton = btn;
        NSInteger score = [UserProfile scoreByCategory:self.detailItem.category];
        [ComponentUtil addTextToButton:btn text:[NSString stringWithFormat: @"%d", (int)score]
                              fontSize:FONT_TINY2 chWidth:ICON_CHWIDTH chHeight:ICON_CHHEIGHT tag:TAG_SCORE_TEXT];
        
        UIBarButtonItem* coinBarButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
        
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:coinBarButton, nil];
    }
    else {
        self.navigationItem.rightBarButtonItems = nil;
    }
}

- (void)addPostComponents
{
    UIButton *btn;
    NSString* imgName;
    float frame_width = self.view.frame.size.width;
    
    // post header
    UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[ComponentUtil getPostHeaderImg]]];
    [imageView setFrame:CGRectMake(0.0f, 0.0f, frame_width, INIT_HEADER_HEIGHT)];
    imageView.userInteractionEnabled = TRUE;
    [scrollView addSubview:imageView];
    
    self.questionTextView = [[UITextView alloc] initWithFrame:CGRectMake(5.0f, 0.0f,
                                                                         imageView.frame.size.width - 20.0f,
                                                                         imageView.frame.size.height - 10.0f)];
    questionTextView.editable = NO;
    questionTextView.backgroundColor = [UIColor clearColor];
    [questionTextView setFont:[UIFont fontWithName:FONT_NAME_TITLE size:FONT_SIZE_TITLE]];
    [imageView addSubview:questionTextView];
    
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"info.png"] forState:UIControlStateNormal];
    btn.tag = TAG_BUTTON_INFO;
    btn.multipleTouchEnabled = TRUE;
    
    float icon_height, icon_width;
    icon_height = 60;
    icon_width = 60;
    [btn setFrame:CGRectMake(imageView.frame.size.width - icon_width - 10,
                             imageView.frame.size.height - icon_height - 10,
                             icon_width, icon_height)];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]
                                         initWithTarget:self action:@selector(linkTextSingleTapRecognized:)];
    singleTap.numberOfTapsRequired = 1;
    [btn addGestureRecognizer:singleTap];
    [imageView addSubview:btn];
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(textWithSwipe:)];
    [self.view addGestureRecognizer:swipe];
    swipe.delegate = self;
    
    // Add buttons
    UIView* buttonsView = [[UIView alloc] initWithFrame:CGRectZero];
    [buttonsView setFrame:CGRectMake(0.0f, imageView.frame.size.height,
                                     frame_width, 110.0f)];
    
    [scrollView addSubview:buttonsView];
    
    float icon1_width, icon2_width, icon3_width;
    icon1_width = icon3_width = 100.0f;
    icon2_width = 35.0f;
    
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:CGRectMake(frame_width/2 - icon2_width/2 - icon1_width, 0.0f, 100.0f, 100.0f)];
    imgName = (detailItem.isvotedown == YES)?@"thumbs_down-512.png":@"thumb_down-512.png";
    [btn setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(barButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    btn.tag = TAG_BUTTON_VOTEDOWN;
    [buttonsView addSubview:btn];
    
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:CGRectMake(frame_width/2 - icon2_width/2, 30.0f, 35.0f, 35.0f)];
    imgName = (detailItem.isfavorite == YES)?@"hearts-512.png":@"heart-512.png";
    [btn setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(barButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    btn.tag = TAG_BUTTON_FAVORITE;
    [buttonsView addSubview:btn];
    
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:CGRectMake(frame_width/2 + icon2_width/2, 0.0f, 100.0f, 100.0f)];
    imgName = (detailItem.isvoteup == YES)?@"thumbs_up-512.png":@"thumb_up-512.png";
    [btn setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(barButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    btn.tag = TAG_BUTTON_VOTEUP;
    [buttonsView addSubview:btn];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectZero];
    [lineView setFrame:CGRectMake(CONTENT_MARGIN_OFFSET, 103.0f, frame_width - CONTENT_MARGIN_OFFSET*2, 1)];
    lineView.backgroundColor = [UIColor grayColor];
    [buttonsView addSubview:lineView];
    
    // draw text
    self.detailUITextView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.detailUITextView.backgroundColor = [UIColor whiteColor];
    self.detailUITextView.userInteractionEnabled = NO;
    [self.detailUITextView setFrame:CGRectMake(0.0f,
                                               buttonsView.frame.origin.y +
                                               buttonsView.frame.size.height,
                                               frame_width,
                                               100)];
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        self.detailUITextView.textContainerInset =
        UIEdgeInsetsMake(0, CONTENT_MARGIN_OFFSET, 0, CONTENT_MARGIN_OFFSET);
    }
    else {
        self.detailUITextView.contentInset = UIEdgeInsetsMake(0, CONTENT_MARGIN_OFFSET, 0, CONTENT_MARGIN_OFFSET);
    }
    
    [scrollView addSubview:self.detailUITextView];
    
    // add iAd
    self.adContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.adContainerView setFrame:CGRectMake(0.0f,
                                              self.detailUITextView.frame.origin.y +
                                              self.detailUITextView.frame.size.height,
                                              frame_width - 20, 80)];
    [scrollView addSubview:self.adContainerView];
    
    ADBannerView *adView = [[ADBannerView alloc] initWithFrame:CGRectZero];
    [adView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    adView.delegate = self;
    [adContainerView addSubview:adView];
    // hide iAd by default
    [self displayBanner:adView isDisplay:NO];
}

- (void)configureLayout
{
    // configure data
    self.questionTextView.text = [self getQuestion:self.detailItem.content];
    // align for center
if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
  {

    self.questionTextView.frame = CGRectMake(self.questionTextView.frame.origin.x,
                                             [ComponentUtil yoffsetVerticalAlign:self.questionTextView],
                                             self.questionTextView.frame.size.width,
                                             self.questionTextView.frame.size.height);
  }
 else {
   [ComponentUtil configureVerticalAlign:self.questionTextView];
 }
    
    self.detailUITextView.text = [self getContent:self.detailItem.content];
    // refresh layout
    
    CGFloat textViewContentHeight = [ComponentUtil measureHeightOfUITextView:self.detailUITextView];
    // NSLog(@"textViewContentHeight: %f, self.detailUITextView.contentSize.height: %f, self.detailUITextView.frame.size.height:%f",
    //       textViewContentHeight, self.detailUITextView.contentSize.height, self.detailUITextView.frame.size.height);
    
    [self.detailUITextView setFrame:CGRectMake(self.detailUITextView.frame.origin.x,
                                               self.detailUITextView.frame.origin.y,
                                               self.detailUITextView.frame.size.width,
                                               textViewContentHeight + 20)];
    
    [self.adContainerView setFrame:CGRectMake(self.adContainerView.frame.origin.x,
                                              self.detailUITextView.frame.origin.y +
                                              self.detailUITextView.frame.size.height,
                                              self.view.bounds.size.width - 20, 80)];
    
    self.scrollView.contentSize=CGSizeMake(self.view.frame.size.width,
                                           self.adContainerView.frame.origin.y +
                                           self.adContainerView.frame.size.height + 40);
}
#pragma mark - loading web page
- (void)browseWebPage:(NSString*)url
{
    UIViewController *webViewController = [[UIViewController alloc]init];
    
    UIWebView *webView = [[UIWebView alloc]initWithFrame:CGRectMake(0,0,
                                                                    self.view.frame.size.width,
                                                                    self.view.frame.size.height
                                                                    + self.navigationController.navigationBar.frame.size.height
                                                                    + 20)];
    // show activity indicator
    activityIndicator = [[UIActivityIndicatorView alloc]
                         initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.frame = CGRectMake(webView.frame.size.width/2,
                                         webView.frame.size.height/2,
                                         20, 20);
    activityIndicator.hidesWhenStopped = YES;
    [webView addSubview:activityIndicator];
    webView.delegate = self;
    
    self.navigationController.navigationBarHidden = NO;
    webView.scalesPageToFit= YES;
    NSURL *nsurl = [NSURL URLWithString:url];
    
    NSURLRequest *nsrequest = [NSURLRequest requestWithURL:nsurl];
    [webView loadRequest:nsrequest];
    [webViewController.view addSubview:webView];
    webViewController.navigationItem.title = @"Webpage";
    
    // enable swipe right
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(textWithSwipe:)];
    [webView addGestureRecognizer:swipe];
    
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [activityIndicator startAnimating];
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [activityIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [activityIndicator stopAnimating];
}

#pragma mark - iAd

-(void) bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"DetailViewController bannerViewDidLoadAd");
    if(!self.bannerIsVisible)
    {
        [self displayBanner:banner isDisplay:YES];
        self.bannerIsVisible = YES;
    }
}

-(void) bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"DetailViewController didFailToReceiveAdWithError");
    if(self.bannerIsVisible)
    {
        [self displayBanner:banner isDisplay:NO];
    }
    self.bannerIsVisible = NO;
}

-(void)displayBanner:(ADBannerView *)banner isDisplay:(BOOL)isDisplay
{
    if(isDisplay) {
        [self.adContainerView setFrame:CGRectMake(0.0f,
                                                  self.detailUITextView.frame.origin.y +
                                                  self.detailUITextView.frame.size.height,
                                                  self.view.frame.size.width - 20, 80)];
        [banner setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    }
    else {
        banner.frame = CGRectZero;
        self.adContainerView.frame = CGRectZero;
    }
    [self configureLayout];
}

#pragma mark - private functions
-(NSString*) getQuestion:(NSString*) content
{
    NSString* ret = @"";
    NSRange range = [content rangeOfString:@"\n-"];
    if (range.location == NSNotFound) {
        [ComponentUtil infoMessage:@"Error to find question/answer seperator"
                               msg:[NSString stringWithFormat:@"range.location:%d", (int)range.location]
                     enforceMsgBox:FALSE];
        ret = content;
    }
    else {
        ret = [content substringToIndex:range.location];
    }
    return ret;
}

-(NSString*) getContent:(NSString*) content
{
    NSString* ret = @"";
    NSRange range = [content rangeOfString:@"\n-"];
    if (range.location == NSNotFound) {
        [ComponentUtil infoMessage:@"Error to find question/answer seperator"
                               msg:[NSString stringWithFormat:@"range.location:%d", (int)range.location]
                     enforceMsgBox:FALSE];
    }
    else {
        ret = [content substringFromIndex:(range.location + 1)];
        if ([ret length] > MAX_POST_CONTENT){
            ret = [NSString stringWithFormat:@"%@... ...",
                   [content substringWithRange:NSMakeRange(0, MAX_POST_CONTENT)]];
            
        }
    }
    return ret;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"DetailViewController viewWillAppear");
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    self.navigationItem.title = @"Question";
    
    [ComponentUtil updateScoreText:self.detailItem.category
                               btn:self.coinButton tag:TAG_SCORE_TEXT];
    
    startTime = [NSDate timeIntervalSinceReferenceDate];
    if ([ComponentUtil shouldMixpanel]) {
        [[Mixpanel sharedInstance] track:@"question_visit_count" properties:@{
                                                                              @"category": self.detailItem.category,
                                                                              @"userid": [ComponentUtil getUserId]
                                                                              }];
    }
    
    self.navigationItem.leftBarButtonItem.title = self.detailItem.category;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"DetailViewController viewWillDisappear");
    
    int seconds = (int)ceilf([NSDate timeIntervalSinceReferenceDate] - startTime);
    
    if (seconds > MAX_SECONDS_FOR_VALID_STAY) {
        NSLog(@"Skip caculating: stay in the post for %d, which is over %d seconds",
              seconds, MAX_SECONDS_FOR_VALID_STAY);
    }
    else {
        NSLog(@"Stay for ove %d seconds", seconds);
        [UserProfile addInteger:self.detailItem.category key:POST_STAY_SECONDS_KEY offset:seconds];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGesture
{
    return YES;
}

-(void) textWithSwipe:(UISwipeGestureRecognizer*)recognizer {
    NSLog(@"textWithSwipe is triggered");
    if (recognizer.direction == UISwipeGestureRecognizerDirectionRight){
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

- (void)linkTextSingleTapRecognized:(UIGestureRecognizer *)gestureRecognizer {
    NSLog(@"loading: %@", self.detailItem.source);
    [self browseWebPage:self.detailItem.source];
}

@end
