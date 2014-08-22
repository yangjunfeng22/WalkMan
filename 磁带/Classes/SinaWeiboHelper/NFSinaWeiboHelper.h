//
//  NFSinaWeiboHelper.h
//  WalkMan
//
//  Created by yang on 14-8-18.
//  Copyright (c) 2014年 yang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NFSinaWeiboHelper : NSObject

+ (void)registerApp;

// 已经安装了客户端，那么是以客户端的形式来验证的。
+ (void)startAuthorize:(void (^)(NSString *screen_name))refresh;

+ (void)authorizeWithResponse:(id)response;

+ (void)startShare:(void (^)(NSString *screen_name))refresh;

+ (void)sendMessageWithResponse:(id)response;

// 如果没有安装客户端，那么是以网页请求url的形式来验证的。
+ (BOOL)startAuthorizeWithURL:(NSURL *)url finished:(void (^)(NSString *screen_name))refresh;

+ (NSString *)oauthUrlString;

+ (NSString *)accessToken;

+ (void)getScreenName:(void (^)(NSString *screen_name))refresh;

+ (void)logOut:(void (^)(NSString *screen_name))refresh;

+ (BOOL)handleWBOpenURL:(NSURL *)url delegate:(id)delegate;

@end
