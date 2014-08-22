//
//  NFThirdShareViewController.m
//  WalkMan
//
//  Created by yang on 14-8-19.
//  Copyright (c) 2014年 yang. All rights reserved.
//

#import "NFThirdShareViewController.h"
#import "NFSinaWeiboHelper.h"

@interface NFThirdShareViewController ()

@end

@implementation NFThirdShareViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *leftBar = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(back:)];
    [self.navigationItem setLeftBarButtonItem:leftBar animated:YES];
    
    NSString *oauthUrlString = [NFSinaWeiboHelper oauthUrlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:oauthUrlString]];
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [webView setDelegate:self];
    [webView loadRequest:request];
    [self.view addSubview:webView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)back:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - WebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *backURL = [request URL];  //接受重定向的URL
    return [NFSinaWeiboHelper startAuthorizeWithURL:backURL finished:^(NSString *screen_name) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
    }];
}

@end
