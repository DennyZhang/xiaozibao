//
//  QCViewController.m
//  MasterDetail
//
//  Created by mac on 14-4-20.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "QCViewController.h"
#import "AFJSONRequestOperation.h"
#import "DetailViewController.h"
#import "CQIAPHelper.h"
#import <StoreKit/StoreKit.h>

@interface QCViewController () {
    NSArray *_products;
}
@property (atomic, retain) QuestionCategory *currentQC;
@property (nonatomic, retain) NSString* navigationTitle;
@property (retain, nonatomic) IBOutlet UIView *footerView;
@property (assign, nonatomic) int bottom_num;

@property (nonatomic, retain) NSMutableArray *savedQuestions;
@property (retain, nonatomic) IBOutlet UITextView *stubTextView;
@property (nonatomic,strong) UIRefreshControl *refreshControl;
@end

@implementation QCViewController

- (void) init_data:(QuestionCategory *)qc
   navigationTitle:(NSString*)navigationTitle_t
{
    NSLog(@"QCViewController init_data");
    self.currentQC = qc;
    self.navigationTitle = navigationTitle_t;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"QCViewController viewDidLoad");
    [super viewDidLoad];
    [ComponentUtil printFrame:self.view.frame leadingMsg:@"QCViewController "];
    [ComponentUtil printFrame:self.tableView.frame leadingMsg:@"QCViewController tableView "];
    // IAP
    _products = nil;
//   TODO
//    [[RageIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
//        if (success) {
//            _products = products;
//            [self.tableView reloadData];
//        }
//        [self.refreshControl endRefreshing];
//    }];
//

    self.view.backgroundColor = DEFAULT_BACKGROUND_COLOR;

    // stub TextView to caculate dynamic cell height
    CGFloat textWidth = self.view.frame.size.width - 15;
    self.stubTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, textWidth, 0)];
    [self.stubTextView setFont:[UIFont fontWithName:FONT_NAME1 size:FONT_NORMAL]];

    if (self.currentQC) {
        [self.currentQC loadPosts];
        
        // init table indicator
        [self initTableIndicatorView];
        self.refreshControl = [[UIRefreshControl alloc] init];
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing data..."];
        [self.refreshControl addTarget:self action:@selector(refreshTableHead) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:self.refreshControl];
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.backgroundColor = DEFAULT_BACKGROUND_COLOR;

        // add tooltip if empty
        [[MyToolTip singleton] reset:self.view]; // reset popTipView
        UIButton *tooltipSwipeBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        tooltipSwipeBtn.center = (CGPoint){self.view.frame.size.width/2, 20};
        [self.view addSubview:tooltipSwipeBtn];
        if ([self.currentQC.questions count]==0) {
          [[MyToolTip singleton] addToolTip:tooltipSwipeBtn msg:@"Pull to update data.."];
        }
        [[MyToolTip singleton] showToolTip];
    }
    else {
        if ([self.navigationTitle isEqualToString:SAVED_QUESTIONS]) {
            
            self.tableView.backgroundColor = DEFAULT_BACKGROUND_COLOR;
            self.tableView.rowHeight = 80.0f;
            
            self.savedQuestions = [[NSMutableArray alloc] init];
            [PostsSqlite loadSavedPosts:self.savedQuestions];

            // add tooltip if empty
            [[MyToolTip singleton] reset:self.view]; // reset popTipView
            UIButton *tooltipSwipeBtn = [[UIButton alloc] initWithFrame:CGRectZero];
            tooltipSwipeBtn.center = (CGPoint){self.view.frame.size.width/2, 20};
            [self.view addSubview:tooltipSwipeBtn];
            if ([self.savedQuestions count]==0) {
              [[MyToolTip singleton] addToolTip:tooltipSwipeBtn msg:@"So far no questions are saved yet."];
            }
            [[MyToolTip singleton] showToolTip];

        }
    }
    NSLog(@"QCViewController viewDidLoad. current category:%@, currentQC questions count:%d",
          self.currentQC.category, (int)[self.currentQC.questions count]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark - Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self.navigationTitle isEqualToString:APP_SETTING]) {
        return 2;
    }
    
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if ([self.navigationTitle isEqualToString:APP_SETTING]) {
        return @" ";
    }
    else
        return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    Posts *post = [self getPostByIndex:(int)indexPath.row];
    post.readcount = [NSNumber numberWithInt:(1+[post.readcount intValue])];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self markCellAsRead:cell post:post];

    // remove the read post from tableview
    if ([self isQuestionChannel] && 
        [[NSUserDefaults standardUserDefaults] integerForKey:@"HideReadPosts"] == 1) {
        [self.currentQC.questions removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadData];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.navigationTitle isEqualToString:APP_SETTING]) {
        if (section == 0) {
            return 5;
        }
        if (section == 1) {
            return 2;
        }
        return 0;
    }
    if ([self.navigationTitle isEqualToString:SAVED_QUESTIONS]) {
        return [self.savedQuestions count];
    }
    
    return [self.currentQC.questions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.backgroundColor = DEFAULT_BACKGROUND_COLOR;
    cell.textLabel.font = [UIFont fontWithName:FONT_NAME1 size:FONT_NORMAL];
    if ([self.navigationTitle isEqualToString:APP_SETTING]) {
        [self appSettingRows:cell indexPath:indexPath];
    }
    else {
        [self configQuestionCell:cell index:(int)indexPath.row];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.navigationTitle isEqualToString:APP_SETTING]) {
        return 50.0f;
    }
    
    // configure dynamic cell height
    Posts *post = [self getPostByIndex:(int)indexPath.row];
    self.stubTextView.text = post.title;
    
    // NSLog(@"heightForRowAtIndexPath return height: %f. self.stubTextView:%@", [ComponentUtil measureHeightOfUITextView:self.stubTextView]
    //       + HEIGHT_IN_CELL_OFFSET + HEIGHT_CELL_BANNER, self.stubTextView);
    
    return [ComponentUtil measureHeightOfUITextView:self.stubTextView]
    + HEIGHT_IN_CELL_OFFSET + HEIGHT_CELL_BANNER;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"He press Cancel");
    }
    else {
        NSLog(@"clean cache");
        [PostsSqlite cleanCache];
        if ([[NSUserDefaults standardUserDefaults] integerForKey:@"IsEditorMode"] == 1) {
            [UserProfile cleanAllCategoryKey];
        }
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([self.navigationTitle isEqualToString:APP_SETTING]) {
        if([cell.textLabel.text isEqualToString:CLEAN_CACHE]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Clean cache Confirmation" message: @"Are you sure to clean all cache, except favorite questions?" delegate:self  cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil];
            
            [alert show];
        }
        
        if([cell.textLabel.text isEqualToString:FOLLOW_MAILTO]) {
            NSString* to=@"denny.zhang001@gmail.com";
            NSString* subject=@"Feedback for CoderQuiz";
            NSString* body=@"hi CoderQuiz\n";
            NSString* mailString = [NSString stringWithFormat:@"mailto:?to=%@&subject=%@&body=%@",
                                    [to stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                                    
                                    [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                                    [body stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
            NSLog(@"mailstring:%@", mailString);
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mailString]];
        }
        
        if([cell.textLabel.text isEqualToString:FOLLOW_TWITTER]) {
            NSString* snsUserName=@"dennyzhang001";
            UIApplication *app = [UIApplication sharedApplication];
            NSURL *snsURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetie://user?screen_name=%@", snsUserName]];
            if ([app canOpenURL:snsURL])
            {
                [app openURL:snsURL];
            }
            else {
                NSString* msg=[[NSString alloc] initWithFormat:@"Follow us by \nhttp://twitter.com/%@", snsUserName];
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:nil message:msg delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:nil, nil];
                [alert show];
                [ComponentUtil timedAlert:alert];
            }
        }
        
        return nil;
    }
    
    return indexPath;
}

- (void)markCellAsRead:(UITableViewCell *)cell post:(Posts *)post
{
    UIView *view = (UIView *)[cell viewWithTag:TAG_CELL_VIEW];
    if ([post.readcount intValue] !=0) {
        view.alpha = 0.3f;
    }
    else {
        view.alpha = 1.0;
    }
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if ([self.navigationTitle isEqualToString:APP_SETTING])
        return 30;
    return 10;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"MasterViewController segue identifier: %@", [segue identifier]);
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSLog(@"increate visit count, for category:%@. previous key:%d", self.currentQC.category,
              (int)[UserProfile integerForKey:self.currentQC.category key:POST_VISIT_KEY]);
        
        Posts *post = [self getPostByIndex:(int)indexPath.row];

        DetailViewController* dvc = [segue destinationViewController];
        if ([self.currentQC.category isEqualToString:SAVED_QUESTIONS]) {
            [dvc setShouldShowCoin:[NSNumber numberWithInt:0]];
        }
        else {
            [dvc setShouldShowCoin:[NSNumber numberWithInt:1]];
        }
        dvc.detailItem = post;
    }
}

- (void) hideSwitchChanged:(id)sender {
    if ([sender isKindOfClass:[UISwitch class]]) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        UISwitch* switchControl = sender;
        if (switchControl.tag == TAG_SWITCH_HIDE_READ_POST) {
            [QuestionCategory clearIsLoaded];
            [userDefaults setInteger:(int)switchControl.on forKey:@"HideReadPosts"];
            [userDefaults synchronize];
        }
        if (switchControl.tag == TAG_SWITCH_EDITOR_MODE) {
            [userDefaults setInteger:(int)switchControl.on forKey:@"IsEditorMode"];
            [userDefaults synchronize];
        }
        if (switchControl.tag == TAG_SWITCH_DEBUG_MODE) {
            [userDefaults setInteger:(int)switchControl.on forKey:@"IsDebugMode"];
            [userDefaults synchronize];
        }
    }
}


- (void) appSettingRows:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            aSwitch.on = YES;
            aSwitch.tag = TAG_SWITCH_HIDE_READ_POST;
            [aSwitch addTarget:self action:@selector(hideSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.textLabel.text = @"Auto hide read questions";
            cell.accessoryView = aSwitch;
            if ([userDefaults integerForKey:@"HideReadPosts"] == 0) {
                aSwitch.on = false;
            }
            else {
                aSwitch.on = true;
            }
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = USER_ID;
            CGFloat field_width = 225;
            CGFloat frame_width = self.view.frame.size.width;
            UITextField *playerTextField = [[UITextField alloc]
                                            initWithFrame:CGRectMake(frame_width - field_width,
                                                                     10, field_width, 30)];
            playerTextField.text = [ComponentUtil getUserId];
            playerTextField.font = [UIFont systemFontOfSize:FONT_TINY];
            playerTextField.textAlignment = NSTextAlignmentRight;
            playerTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            playerTextField.returnKeyType = UIReturnKeyDone;
            playerTextField.borderStyle = UITextBorderStyleNone;
            playerTextField.autocorrectionType = UITextAutocorrectionTypeNo;
            playerTextField.delegate = self;
            cell.accessoryView = playerTextField;
        }
        if (indexPath.row == 2) {
            cell.textLabel.text = CLEAN_CACHE;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        if (indexPath.row == 3) {
            UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            aSwitch.on = YES;
            aSwitch.tag = TAG_SWITCH_EDITOR_MODE;
            [aSwitch addTarget:self action:@selector(hideSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.textLabel.text = @"Enable editor mode";
            cell.accessoryView = aSwitch;
            if ([userDefaults integerForKey:@"IsEditorMode"] == 0) {
                aSwitch.on = false;
            }
            else {
                aSwitch.on = true;
            }
        }
        if (indexPath.row == 4) {
            UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            aSwitch.on = YES;
            aSwitch.tag = TAG_SWITCH_DEBUG_MODE;
            [aSwitch addTarget:self action:@selector(hideSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.textLabel.text = @"Show verbose errmsg";
            cell.accessoryView = aSwitch;
            if ([userDefaults integerForKey:@"IsDebugMode"] == 0) {
                aSwitch.on = false;
            }
            else {
                aSwitch.on = true;
            }
        }
    }
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = FOLLOW_TWITTER;
        }
        
        if (indexPath.row == 1) {
            cell.textLabel.text = FOLLOW_MAILTO;
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString* uid = textField.text;
    uid = [uid stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    [[NSUserDefaults standardUserDefaults] setObject:uid forKey:@"Userid"];
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - refresh
- (void)toggleActivityIndicator:(bool)isHeader isStartAnimation:(bool)isStartAnimation {
    UIView* tableIndicatorView;
    UIActivityIndicatorView * tableActivityIndicator;
    if(isHeader && !isStartAnimation) {
        [self.refreshControl endRefreshing];
    }
    else {
        // footer indicator
        tableIndicatorView = self.footerView;
        tableActivityIndicator = (UIActivityIndicatorView *)[tableIndicatorView viewWithTag:TAG_TABLE_FOOTER_INDIACTOR];
        
        CGFloat indicatorHeight = 20.0f;
        if (isStartAnimation) {
            // start animation
            if (![tableActivityIndicator isAnimating]) {
                [tableActivityIndicator startAnimating];
            }
            [tableIndicatorView setFrame:CGRectMake(tableIndicatorView.frame.origin.x,
                                                    tableIndicatorView.frame.origin.y,
                                                    tableIndicatorView.frame.size.width,
                                                    indicatorHeight)];
        }
        else {
            if ([tableActivityIndicator isAnimating]) {
                [tableActivityIndicator stopAnimating];
            }
            
            [tableIndicatorView setFrame:CGRectMake(tableIndicatorView.frame.origin.x,
                                                    tableIndicatorView.frame.origin.y,
                                                    tableIndicatorView.frame.size.width,
                                                    0)];
        }
    }
}

-(void)initTableIndicatorView
{
    // footerView
    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0,
                                                               self.view.frame.size.width, 20.0)];
    self.tableView.tableFooterView = self.footerView;
    
    self.footerView.backgroundColor = DEFAULT_BACKGROUND_COLOR;
    UIActivityIndicatorView * actIndFooter = [[UIActivityIndicatorView alloc]
                                              initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.footerView addSubview:actIndFooter];
    
    actIndFooter.tag = TAG_TABLE_FOOTER_INDIACTOR;
    actIndFooter.hidesWhenStopped = YES;
    [self.footerView setFrame:CGRectMake(0.0, 0.0,
                                         self.view.frame.size.width, 20.0)];
    actIndFooter.frame = CGRectMake(150.0, 0, 20.0, 20.0);
}

- (void) refreshTableHead
{
    NSLog(@"refreshTableHead");
    [self fetchArticleList:[ComponentUtil getUserId] category_t:self.currentQC.category
               start_num_t:0
          shouldAppendHead:YES];
}

- (void) refreshTableTail
{
    NSLog(@"refreshTableTail");
    [self toggleActivityIndicator:NO isStartAnimation:YES];
    [self fetchArticleList:[ComponentUtil getUserId] category_t:self.currentQC.category
               start_num_t:self.bottom_num * PAGE_COUNT
          shouldAppendHead:NO];
}

#pragma mark - load data
- (bool)addToTableView:(int)index
                  post:(Posts*)post
{
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"HideReadPosts"] == 1) {
        if (post.readcount.intValue !=0 )
            return YES;
    }
    
    bool ret = YES;
    [self.currentQC.questions insertObject:post atIndex:index];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    //NSLog(@"after addToTableView currentQuestions.count:%d", [self.currentQC.questions count]);
    return ret;
}

- (void)fetchArticleList:(NSString*)userid
              category_t:(NSString*)category_t
             start_num_t:(int)start_num_t
        shouldAppendHead:(bool)shouldAppendHead
{
    if ([self.navigationItem.title isEqualToString:SAVED_QUESTIONS])
        return;
    NSString *urlPrefix=SERVERURL;
    // TODO: voteup defined by users
    NSString *sortMethod;
    NSString *urlStr;
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"IsEditorMode"] == 0) {
        // If anyone votedown, it's not shown
        sortMethod = @"hotest";
        urlStr= [NSString stringWithFormat: @"%@api_list_posts_in_topic?uid=%@&topic=%@&start_num=%d&count=%d&sort_method=%@&votedown=0",
                 urlPrefix, userid, category_t, start_num_t, PAGE_COUNT, sortMethod];
    }
    else {
        sortMethod = @"latest";
        urlStr= [NSString stringWithFormat: @"%@api_list_posts_in_topic?uid=%@&topic=%@&start_num=%d&count=%d&sort_method=%@",
                 urlPrefix, userid, category_t, start_num_t, PAGE_COUNT, sortMethod];
    }
    
    NSLog(@"fetchArticleList, url:%@", urlStr);
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [self toggleActivityIndicator:shouldAppendHead isStartAnimation:NO];
        NSArray *idList = [JSON valueForKeyPath:@"postid"];
        NSArray *metadataList = [JSON valueForKeyPath:@"metadata"];
        Posts *post = nil;
        int i, count = (int)[idList count];
        
        NSLog(@"merge result. count:%d", count);
        
        // bypass sqlite lock problem
        if (shouldAppendHead) {
            // TODO remove code duplication
            for(i=count-1; i>=0; i--) {
                //NSLog(@"fetchArticleList i:%d, id:%@, metadata:%@", i, idList[i], metadataList[i]);
                if ([Posts containId:self.currentQC.questions postId:idList[i]] == NO) {
                    post = [PostsSqlite getPost:idList[i]];
                    if (!post || [post isPostStale:metadataList[i]]) {
                        BOOL isUpdated = (post)?YES:NO;
                        [self fetchJson:self.currentQC.questions
                                 urlStr:[[urlPrefix stringByAppendingString:@"api_get_post?postid="] stringByAppendingString:idList[i]]
                       shouldAppendHead:shouldAppendHead
                              isUpdated:isUpdated];
                    }
                    else {
                        int index = 0;
                        if (shouldAppendHead != YES){
                            index = (int)[self.currentQC.questions count];
                        }
                        [self addToTableView:index post:post];
                    }
                }
            }
        }
        else{
            for(i=0; i<count; i++) {
                if ([Posts containId:self.currentQC.questions postId:idList[i]] == NO) {
                    post = [PostsSqlite getPost:idList[i]];
                    if (!post || [post isPostStale:metadataList[i]]) {
                        BOOL isUpdated = (post)?YES:NO;
                        [self fetchJson:self.currentQC.questions
                                 urlStr:[[urlPrefix stringByAppendingString:@"api_get_post?postid="] stringByAppendingString:idList[i]]
                       shouldAppendHead:shouldAppendHead
                              isUpdated:isUpdated];
                    }
                    else {
                        int index = 0;
                        if (shouldAppendHead != YES){
                            index = (int)[self.currentQC.questions count];
                        }
                        [self addToTableView:index post:post];
                    }
                }
            }
        }
        
        for(i=0; i<count; i++) {
            [PostsSqlite updatePostMetadata:idList[i] metadata:metadataList[i]
                                   category:self.currentQC.category];
            
        }
        if (shouldAppendHead == NO) {
            self.bottom_num = 1 + self.bottom_num;
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [self toggleActivityIndicator:shouldAppendHead isStartAnimation:NO];
        [ComponentUtil infoMessage:@"Error to get specific post list"
                               msg:[NSString stringWithFormat:@"url:%@, error:%@", urlStr, error]
                     enforceMsgBox:FALSE];
    }];
    
    [operation start];
}

- (void)fetchJson:(NSMutableArray*) listObject
           urlStr:(NSString*)urlStr
 shouldAppendHead:(bool)shouldAppendHead
        isUpdated:(bool)isUpdated
{
    
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        Posts* post = [[Posts alloc] init];
        [post setPostid:[JSON valueForKeyPath:@"id"]];
        [post setTitle:[JSON valueForKeyPath:@"title"]];
        [post setSummary:[JSON valueForKeyPath:@"summary"]];
        [post setCategory:[JSON valueForKeyPath:@"category"]];
        [post setContent:[JSON valueForKeyPath:@"content"]];
        [post setSource:[JSON valueForKeyPath:@"source"]];
        [post set_metadata:[JSON valueForKeyPath:@"metadata"]];
        [post setReadcount:[NSNumber numberWithInt:0]];
        
        if (isUpdated) {
            if ([PostsSqlite updatePost:post.postid summary:post.summary category:post.category
                                  title:post.title source:post.source content:post.content
                               metadata:post.metadata] == NO) {
                [ComponentUtil infoMessage:@"Error to update post"
                                       msg:[NSString stringWithFormat:@"postid:%@, title:%@", post.postid, post.title]
                             enforceMsgBox:FALSE];
            }
        }
        else {
            if ([PostsSqlite savePost:post.postid summary:post.summary category:post.category
                                title:post.title source:post.source content:post.content
                             metadata:post.metadata] == NO) {
                [ComponentUtil infoMessage:@"Error to insert post"
                                       msg:[NSString stringWithFormat:@"postid:%@, title:%@", post.postid, post.title]
                             enforceMsgBox:FALSE];
            }
        }
        
        int index = 0;
        if (shouldAppendHead != YES){
            index = (int)[listObject count];
        }
        [self addToTableView:index post:post];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [ComponentUtil infoMessage:@"Error to get specific post"
                               msg:[NSString stringWithFormat:@"url:%@, error:%@", urlStr, error]
                     enforceMsgBox:FALSE];
        
    }];
    
    [operation start];
}

#pragma mark - scroll
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // NSLog(@"scrollViewDidScroll, scrollView:%@, x:%f, y:%f",
    //       scrollView, scrollView.contentOffset.x, scrollView.contentOffset.y);
    
    if (![self isQuestionChannel])
        return;
    // when reach the top
    if (scrollView.contentOffset.y <= 0)
    {
        [self toggleActivityIndicator:YES isStartAnimation:YES];
    }
    else {
        if (scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.bounds.size.height)
        {
            [self toggleActivityIndicator:NO isStartAnimation:YES];
        }
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // NSLog(@"scrollViewDidEndDecelerating, scrollView:%@, x:%f, y:%f",
    //       scrollView, scrollView.contentOffset.x, scrollView.contentOffset.y);
    
    if (![self isQuestionChannel])
        return;
    
    // when reach the top
    if (scrollView.contentOffset.y <= 0)
    {
        [self refreshTableHead];
    }
    else {
        // when reaching the bottom
        if (scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.bounds.size.height)
        {
            [self refreshTableTail];
        }
    }
}

#pragma mark - private functions
- (BOOL) isQuestionChannel
{
    return (![self.navigationTitle isEqualToString:SAVED_QUESTIONS] &&
            ![self.navigationTitle isEqualToString:APP_SETTING]);
}

- (void) configQuestionCell:(UITableViewCell *)cell
                      index:(int)index
{
    Posts *post = [self getPostByIndex:index];
    
    UIView* view = [[UIView alloc] init];
    view.tag = TAG_CELL_VIEW;
    view.backgroundColor = [UIColor whiteColor];

    [[cell.contentView viewWithTag:TAG_CELL_VIEW] removeFromSuperview];
    [[cell contentView] addSubview:view];
    cell.textLabel.text = @"";
    
    CGFloat textHeight, textWidth = self.view.frame.size.width - 15;
    
    NSString* iconPath = [ComponentUtil getLogoIcon:post.source];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:iconPath]];
    
    
    [imageView setTag:TAG_ICON_IN_CELL];
    imageView.userInteractionEnabled = NO;
    [view addSubview:imageView];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, textWidth, 0)];
    [textView setFont:[UIFont fontWithName:FONT_NAME1 size:FONT_NORMAL]];
    [textView setTextColor:[UIColor blackColor]];
    //textView.textColor = [UIColor colorWithRed:136.0f/255.0f green:136.0f/255.0f blue:136.0f/255.0f alpha:1.0f];
    [textView setBackgroundColor:[UIColor clearColor]];
    [textView setTag:TAG_TEXTVIEW_IN_CELL];
    textView.userInteractionEnabled = NO;
    [view addSubview:textView];
    [textView setText:post.title];
    
    UITextView *metadataTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    [metadataTextView setTextColor:[UIColor blackColor]];
    [metadataTextView setFont:[UIFont fontWithName:FONT_NAME1 size:FONT_TINY]];
    [metadataTextView setBackgroundColor:[UIColor clearColor]];
    [metadataTextView setTag:TAG_METADATA_IN_CELL];
    metadataTextView.userInteractionEnabled = NO;
    [view addSubview:metadataTextView];
    //[metadataTextView setText:post.metadata];
    CGFloat voteIconWidth = 18.0f;
    CGFloat voteIconHeight = 18.0f;
    NSString* voteupStr = [post.metadataDictionary objectForKey:@"voteup"];
    NSInteger voteup = [voteupStr intValue];
    if (voteup > 0) {
        UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = TAG_VOTEUP_IN_CELL;
        [btn setImage:[UIImage imageNamed:@"thumbs_up2.png"] forState:UIControlStateNormal];
        
        UITextView* voteTextView = [[UITextView alloc] initWithFrame:CGRectZero];
        [metadataTextView addSubview:voteTextView];
        [metadataTextView addSubview:btn];
        
        [btn setFrame:CGRectMake(0.0f, 3.0f, voteIconWidth, voteIconHeight)];
        
        [voteTextView setFrame:CGRectMake(voteIconWidth, 0, FONT_TINY, 18)];
        voteTextView.text = voteupStr;
        voteTextView.textAlignment = NSTextAlignmentLeft;
        [voteTextView setFont:[UIFont fontWithName:FONT_NAME1 size:FONT_TINY]];
    }
    [self markCellAsRead:cell post:post];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    // configure frame
    textHeight = [ComponentUtil measureHeightOfUITextView:textView];
    [cell setFrame:CGRectMake(0, 0, self.view.frame.size.width, textHeight + HEIGHT_IN_CELL_OFFSET+ HEIGHT_CELL_BANNER)];
    [view setFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height - 5)];
    [textView setFrame:CGRectMake(10, 5, textWidth, textHeight)];
    CGFloat imageHeight = 25, imageWidth;
    imageWidth = imageHeight*imageView.image.size.width/imageView.image.size.height;
    [imageView setFrame:CGRectMake(10, cell.frame.size.height - imageHeight - 10,
                                   imageWidth, imageHeight)];
    
    CGFloat metaWidth = voteIconWidth + FONT_TINY, metaHeight = 33;
    [metadataTextView setFrame:CGRectMake(cell.frame.size.width - metaWidth - 15,
                                          cell.frame.size.height - metaHeight,
                                          metaWidth, metaHeight)];
    // set alpha
    imageView.alpha = 0.5f;
    metadataTextView.alpha = 0.5f;
    // NSLog(@"configQuestionCell, height:%f, textHeight:%f", cell.frame.size.height, textHeight);
}

- (Posts*) getPostByIndex:(int)index
{
    Posts *post;
    if ([self.navigationTitle isEqualToString:SAVED_QUESTIONS]) {
        post = self.savedQuestions[index];
    }
    else {
        post = self.currentQC.questions[index];
    }
    return post;
}
@end
