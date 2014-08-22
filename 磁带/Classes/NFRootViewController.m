//
//  NFRootViewController.m
//  WalkMan
//
//  Created by yang on 14-8-15.
//  Copyright (c) 2014年 yang. All rights reserved.
//

#import "NFRootViewController.h"
#import <FacebookSDK/FacebookSDK.h>

#import "NFAppDelegate.h"

#import "NFSinaWeiboHelper.h"
#import "NFThirdLoginViewController.h"
#import "NFThirdShareViewController.h"

#import "NFFaceBookHelper.h"

#import "WeiboSDK.h"

@interface NFRootViewController ()

@end

@implementation NFRootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshUserWBNameShow];
    [self refreshUserFBNameShow];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Weibo Manager
- (void)refreshUserWBNameShow
{
    [NFSinaWeiboHelper getScreenName:^(NSString *screen_name) {
        _lblName.text = screen_name;
    }];
}

- (IBAction)ibWeiboShare:(id)sender
{
    if ([WeiboSDK isWeiboAppInstalled])
    {
        [NFSinaWeiboHelper startShare:^(NSString *screen_name) {
            NSLog(@"%@ 完成分享!", screen_name);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"新浪微博" message:@"分享成功" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
        }];
    }
    else
    {
        NFThirdShareViewController *thirdShareViewController = [[NFThirdShareViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:thirdShareViewController];
        [self presentViewController:nav animated:YES completion:^{}];
    }
}

- (IBAction)ibWeiboLogin:(id)sender
{
    if ([WeiboSDK isWeiboAppInstalled])
    {
        [NFSinaWeiboHelper startAuthorize:^(NSString *screen_name) {
            _lblName.text = screen_name;
        }];
    }
    else
    {
        NFThirdLoginViewController *thirdLoginViewController = [[NFThirdLoginViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:thirdLoginViewController];
        [self presentViewController:nav animated:YES completion:^{}];
    }
}

- (IBAction)ibWeiboLogout:(id)sender
{
    [NFSinaWeiboHelper logOut:^(NSString *screen_name) {
        _lblName.text = screen_name;
    }];
}

#pragma mark - Facebook Manager
- (void)refreshUserFBNameShow
{
    [NFFaceBookHelper getScreenName:^(NSString *screen_name) {
        _lblFBName.text = screen_name;
    }];
}

- (IBAction)ibFBLogin:(id)sender
{
    [NFFaceBookHelper startAuthorize:^(NSString *name) {
        _lblFBName.text = name;
    }];
}

- (IBAction)ibFBShare:(id)sender
{
    [NFFaceBookHelper startShare:^(NSString *screen_name) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook" message:@"分享成功" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }];
}

- (IBAction)ibFBLogout:(id)sender
{
    [NFFaceBookHelper logOut:^(NSString *name) {
        _lblFBName.text = name;
    }];
}


@end
