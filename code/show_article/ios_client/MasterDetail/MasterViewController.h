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

#import "AFJSONRequestOperation.h"
#import "DetailViewController.h"
#import "MenuViewController.h"
#import "Posts.h"
#import "PostsSqlite.h"
#import "QCViewController.h"
#import "QuestionCategory.h"
#import "QuestionCategory.h"
#import "SWRevealViewController.h"
#import "global.h"

@class DetailViewController;

@interface MasterViewController : UIViewController <
    UIPageViewControllerDataSource>

#define TAG_BUTTON_COIN 1000
#define TAG_MASTERVIEW_SCORE_TEXT 1001

- (void) updateNavigationTitle:(NSString*) navigationTitle;
@end
