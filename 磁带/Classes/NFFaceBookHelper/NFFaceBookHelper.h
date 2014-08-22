//
//  NFFaceBookHelper.h
//  WalkMan
//
//  Created by yang on 14-8-21.
//  Copyright (c) 2014年 yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

@interface NFFaceBookHelper : NSObject

+ (void)registerApp;

// 已经安装了客户端，那么是以客户端的形式来验证的。
+ (void)startAuthorize:(void (^)(NSString *))refresh;

+ (void)getScreenName:(void (^)(NSString *screen_name))refresh;

+ (void)startShare:(void (^)(NSString *screen_name))refresh;

+ (void)logOut:(void (^)(NSString *))refresh;

+ (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error;

+ (void)handleStateChange;

+ (void)handleBecomeActive;

+ (BOOL)handleFBOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;

+ (void)close;

@end
