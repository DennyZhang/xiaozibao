//
//  MasterViewController.h
//  MasterDetail
//
//  Created by mac on 13-7-13.
//  Copyright (c) 2013年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

//#import "/usr/include/sqlite3.h"
#import "/usr/local/opt/sqlite/include/sqlite3.h"

#import "Posts.h"
#import "PostsSqlite.h"
#import "UserProfile.h"

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (retain, nonatomic) DetailViewController *detailViewController;
@property (nonatomic, retain) CLLocationManager *locationManager;

@property (nonatomic, retain) NSString* topic;
@property (nonatomic, retain) NSString* username;
@property (atomic, retain) NSNumber* bottom_num;
@property (atomic, retain) NSNumber* page_count;

@property (retain, nonatomic) IBOutlet UITextField *serverUITextField;

- (void) init_data:(NSString*)username_t
           topic_t:(NSString*)topic_t;

#define TAG_TEXTVIEW_IN_CELL 1001
#define TAG_ICON_IN_CELL 1002
#define TAG_SWITCH_HIDE_READ_POST 1003
#define TAG_SWITCH_EDITOR_MODE 1004

#define CLEAN_CACHE @"Clean cache"
#define FOLLOW_TWITTER @"Follow us on Twitter"
#define FOLLOW_WEIBO @"Follow us on Weibo"
#define FOLLOW_MAILTO @"Mail to us"

#define ROW_HEIGHT 120.0f
@end
