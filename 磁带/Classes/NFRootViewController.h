//
//  NFRootViewController.h
//  WalkMan
//
//  Created by yang on 14-8-15.
//  Copyright (c) 2014年 yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NFRootViewController : UIViewController<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UILabel *lblFBName;

@end
