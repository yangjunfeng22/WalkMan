//
//  NFAppDelegate.m
//  磁带
//
//  Created by yang on 14-8-15.
//  Copyright (c) 2014年 yang. All rights reserved.
//

#import "NFAppDelegate.h"

#import "NFRootViewController.h"

#import "NFSinaWeiboHelper.h"
#import "NFFaceBookHelper.h"

@implementation NFAppDelegate
{
    NFRootViewController *rootViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [NFSinaWeiboHelper registerApp];
    [NFFaceBookHelper registerApp];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    rootViewController = [[NFRootViewController alloc] initWithNibName:@"NFRootViewController" bundle:nil];
    
    self.window.rootViewController = rootViewController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
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
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [NFFaceBookHelper handleBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [NFFaceBookHelper close];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"sourceApplication: %@; annotation: %@", sourceApplication, annotation);
    
    [NFFaceBookHelper handleStateChange];
    
    BOOL fb = [NFFaceBookHelper handleFBOpenURL:url sourceApplication:sourceApplication];;
     
    BOOL wb = [WeiboSDK handleOpenURL:url delegate:self];
    return (fb || wb);
}

#pragma mark - Weibo Delegate
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request
{
    NSLog(@"%@, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response
{
    if ([response isKindOfClass:[WBSendMessageToWeiboResponse class]])
    {
        [NFSinaWeiboHelper sendMessageWithResponse:response];
    }
    else if ([response isKindOfClass:[WBAuthorizeResponse class]])
    {
        [NFSinaWeiboHelper authorizeWithResponse:response];
    }
}

@end
