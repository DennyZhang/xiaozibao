//
//  posts.h
//  MasterDetail
//
//  Created by mac on 13-7-22.
//  Copyright (c) 2013年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Posts : NSObject

@property (nonatomic, retain) NSString* postid;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* summary;
@property (nonatomic, retain) NSString* category;
@property (nonatomic, retain) NSString* content;
@property (nonatomic, retain) NSString* source;
@property (nonatomic, retain) NSNumber* readcount;
@property (nonatomic, assign) BOOL issaved;

+ (void) feedbackPost:(NSString*) userid
               postid:(NSString*) postid
               category:(NSString*) category
               comment:(NSString*) comment
                button:(UIButton *) button;

+ (bool)containId:(NSMutableArray*) objects
           postId:(NSString*)postId;

+ (void)getCategoryList:(NSUserDefaults *)userDefaults;

// TODO manage below code in a dedicated class
+(void)timedAlert:(UIAlertView *) alertView;
+(void)dismissAlert:(UIAlertView *) alertView;

@end
