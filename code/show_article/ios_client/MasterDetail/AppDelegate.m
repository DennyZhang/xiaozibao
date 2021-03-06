//
//  AppDelegate.m
//  MasterDetail
//
//  Created by mac on 13-7-13.
//  Copyright (c) 2013年 mac. All rights reserved.
//

#import "AppDelegate.h"
#import "PostsSqlite.h"

#import "CQIAPHelper.h"

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    //     UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    //     UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    //     splitViewController.delegate = (id)navigationController.topViewController;
    // }
    
    // set UserDefaults
    [ComponentUtil setDefaultConf];
    
    [Posts updateCategoryList:[NSUserDefaults standardUserDefaults]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = nil;
    if ([paths count] > 0){
        basePath = (NSString *)[paths objectAtIndex:0];
    }
    
    NSLog(@"basePath:%@", basePath);
    
    self.window.backgroundColor = DEFAULT_BACKGROUND_COLOR;

    // init db
    if ([PostsSqlite initDB] == NO) {
        NSLog(@"Error: Failed to open/create database");
    }

    [CQIAPHelper sharedInstance];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if ([ComponentUtil shouldMixpanel]) {
        [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
      // track open count
        [mixpanel track:@"open_count" properties:@{
                                                   @"userid": [ComponentUtil getUserId]
                                                   }];
      NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
      NSString* lastOpenDate = [userDefaults stringForKey:@"LastOpenDate"];
      // get current date
      NSDate * date=[NSDate date];
      NSDateFormatter *dateformatter=[[NSDateFormatter alloc] init];
      [dateformatter setDateFormat:@"YYYY-MM-dd"];
      NSString * currentDate = [dateformatter stringFromDate:date];
      //NSLog(@"LastOpenDate lastOpenDate:%@, currentDate:%@", lastOpenDate, currentDate);
      if (!lastOpenDate || ![lastOpenDate isEqualToString:currentDate]) {
        //NSLog(@"update LastOpenDate");
      // track daily users
        [mixpanel track:@"daily_users" properties:@{
            @"userid": [ComponentUtil getUserId]
              }];
        [userDefaults setObject:currentDate forKey:@"LastOpenDate"];
        //[userDefaults synchronize];
      }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
