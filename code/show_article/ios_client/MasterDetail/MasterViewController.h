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

#import "global.h"
#import "Posts.h"
#import "PostsSqlite.h"
#import "ComponentUtil.h"
#import "UserProfile.h"
#import "MenuViewController.h"

@class DetailViewController;

@interface MasterViewController : UIViewController <
    UIPageViewControllerDataSource>

#define TAG_BUTTON_COIN 1000
#define TAG_MASTERVIEW_SCORE_TEXT 1001
@property (nonatomic, retain) NSString* navigationTitle;

@end
