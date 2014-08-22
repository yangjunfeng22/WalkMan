//
//  NFAppDelegate.h
//  磁带
//
//  Created by yang on 14-8-15.
//  Copyright (c) 2014年 yang. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WeiboSDK.h"

@interface NFAppDelegate : UIResponder <UIApplicationDelegate, WeiboSDKDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NSString *wbtoken;


@end
