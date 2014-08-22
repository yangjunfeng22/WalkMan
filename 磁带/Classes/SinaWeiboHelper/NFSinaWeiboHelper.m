//
//  NFSinaWeiboHelper.m
//  WalkMan
//
//  Created by yang on 14-8-18.
//  Copyright (c) 2014年 yang. All rights reserved.
//

#import "NFSinaWeiboHelper.h"

#import "WeiboSDK.h"

//新浪微博
#define kWB_AppKey          @"4150420908"
#define kWB_AppSecret       @"dc6ead894b8f0b6d491165a2ffe44331"
#define kWB_OAuth_URL       @"https://api.weibo.com/oauth2/authorize"
#define kWB_AccessToken_URL @"https://api.weibo.com/oauth2/access_token"
#define kWB_RedirectURL     @"https://api.weibo.com/oauth2/default.html"
#define kWB_UserInfoURL     @"https://api.weibo.com/2/users/show.json"

void (^refreshShow)(NSString *);

@interface NFSinaWeiboHelper ()<WBHttpRequestDelegate>
{
    id instance;
}

@end

@implementation NFSinaWeiboHelper

+ (void)registerApp
{
    [WeiboSDK enableDebugMode:YES];
    [WeiboSDK registerApp:kWB_AppKey];
    
    [self registerUserDefaults];
}

+ (void)registerUserDefaults
{
    NSDictionary *dicWbToken = [NSDictionary dictionaryWithObject:@"" forKey:@"WBToken"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dicWbToken];
    
    NSDictionary *dicWbUid   = [NSDictionary dictionaryWithObject:@"" forKey:@"WBUid"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dicWbUid];
    
    NSDictionary *dicWbName   = [NSDictionary dictionaryWithObject:@"新浪微博" forKey:@"WBName"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dicWbName];
}

+ (void)refreshUserDefaultsWithWBToken:(NSString *)token WBUid:(NSString *)uid WBUName:(NSString *)name
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:name forKey:@"WBName"];
    [userDefaults setObject:uid forKey:@"WBUid"];
    [userDefaults setObject:token forKey:@"WBToken"];
    [userDefaults synchronize];
}

// 客户端请求的方式登陆
+ (void)startAuthorize:(void (^)(NSString *))refresh
{
    refreshShow = refresh;
    
    WBAuthorizeRequest *request = [WBAuthorizeRequest request];
    request.redirectURI = kWB_RedirectURL;
    request.scope = @"all";
    request.userInfo = @{@"SSO_From":@"User",
                         @"Other_Info_1":[NSNumber numberWithInt:1],
                         @"Other_Info_2":@[@"obj1", @"obj2"],
                         @"Other_Info_3":@{@"key1":@"obj1", @"key2":@"obj2"}};
    
    [WeiboSDK sendRequest:request];
    
}

+ (void)authorizeWithResponse:(WBAuthorizeResponse *)response
{
    @autoreleasepool
    {
        if (response.statusCode == 0)
        {
            NSString *accessToken = [(WBAuthorizeResponse *)response accessToken];
            NSString *uid = [(WBAuthorizeResponse *)response userID];
            
            NSString * oathString = [NSString stringWithFormat:@"%@?uid=%@&access_token=%@", kWB_UserInfoURL, uid, accessToken];
            
            dispatch_queue_t queue = dispatch_queue_create("com.yjf.walkman", nil);
            dispatch_async(queue, ^{
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:oathString]];
                NSDictionary *dicUser = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                NSString *uname = [dicUser objectForKey:@"screen_name"];
                [self refreshUserDefaultsWithWBToken:accessToken WBUid:uid WBUName:uname];
                dispatch_async(dispatch_get_main_queue(), ^{
                    refreshShow(uname);
                });
            });
        }
        else
        {
            // 具体的错误信息。
            /*
            WeiboSDKResponseStatusCodeSuccess               = 0,//成功
            WeiboSDKResponseStatusCodeUserCancel            = -1,//用户取消发送
            WeiboSDKResponseStatusCodeSentFail              = -2,//发送失败
            WeiboSDKResponseStatusCodeAuthDeny              = -3,//授权失败
            WeiboSDKResponseStatusCodeUserCancelInstall     = -4,//用户取消安装微博客户端
            WeiboSDKResponseStatusCodeUnsupport             = -99,//不支持的请求
            WeiboSDKResponseStatusCodeUnknown               = -100,
             */
        }
    }
}

+ (void)startShare:(void (^)(NSString *))refresh
{
    refreshShow = refresh;
    
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:[self messageToShare]];
    request.userInfo = @{@"ShareMessageFrom":@"User",
                         @"Other_Info_1":[NSNumber numberWithInt:123],
                         @"Other_Info_2":@[@"obj1", @"obj2"],
                         @"Other_Info_3":@{@"key1":@"obj1", @"key2":@"obj2"}};
    [WeiboSDK sendRequest:request];
}

+ (WBMessageObject *)messageToShare
{
    WBMessageObject *message = [WBMessageObject message];
    
    message.text = @"已经发黄的磁带，还孜孜不倦地记录着童年的故事。曾经的时光，还好吗？";
    
    WBImageObject *image = [WBImageObject object];
    image.imageData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"wlbackground24" ofType:@"jpg"]];
    message.imageObject = image;
    
    return message;
}

+ (void)sendMessageWithResponse:(WBSendMessageToWeiboResponse *)response
{
    @autoreleasepool
    {
        if (response.statusCode == 0)
        {
            NSLog(@"response userInfo: %@ requestUserInfo: %@", response.userInfo, response.requestUserInfo);
            refreshShow(@"");
        }
        else
        {
            // 具体的错误信息。
            /*
             WeiboSDKResponseStatusCodeSuccess               = 0,//成功
             WeiboSDKResponseStatusCodeUserCancel            = -1,//用户取消发送
             WeiboSDKResponseStatusCodeSentFail              = -2,//发送失败
             WeiboSDKResponseStatusCodeAuthDeny              = -3,//授权失败
             WeiboSDKResponseStatusCodeUserCancelInstall     = -4,//用户取消安装微博客户端
             WeiboSDKResponseStatusCodeUnsupport             = -99,//不支持的请求
             WeiboSDKResponseStatusCodeUnknown               = -100,
             */
        }
    }
}


+ (BOOL)startAuthorizeWithURL:(NSURL *)url finished:(void (^)(NSString *))refresh
{
    refreshShow = refresh;
    
    NSString *backURLString = [url absoluteString];
    
    //判断是否是授权调用返回的url
    
    if ([backURLString hasPrefix:kWB_RedirectURL])
    {
        NSLog(@"回调地址");
        // 找到”code＝“的range。
        NSRange range = [backURLString rangeOfString:@"code="];
        
        // 根据”code＝“的range确定code的参数值的range。
        NSRange codeRange = NSMakeRange(range.location+range.length, backURLString.length-(range.location+range.length));
        // 获取 code的值
        NSString *strCode = [backURLString substringWithRange:codeRange];
        [self getWidboAccessTokenWithCode:strCode];
        
        return NO;
    }
    return YES;
}

+ (void)getWidboAccessTokenWithCode:(NSString *)code
{
    //access token调用URL的string
    NSMutableString *accessTokenUrlString = [[NSMutableString alloc] initWithFormat:@"%@?client_id=%@&client_secret=%@&grant_type=authorization_code&redirect_uri=%@&code=%@", kWB_AccessToken_URL, kWB_AppKey, kWB_AppSecret, kWB_RedirectURL, code];
    //[accessTokenUrlString appendString:code];
    
    //同步POST请求
    NSURL *urlstring = [NSURL URLWithString:accessTokenUrlString];
    //第二步，创建请求
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:urlstring cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [request setHTTPMethod:@"POST"];//设置请求方式为POST，默认为GET
    
    //第三步，连接服务器
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    //NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
         
         NSString *accesstoken = [dictionary objectForKey:@"access_token"];
         NSString *uid = [dictionary objectForKey:@"uid"];
         
         NSString * oathString = [NSString stringWithFormat:@"%@?uid=%@&access_token=%@", kWB_UserInfoURL, uid, accesstoken];
         
         dispatch_queue_t queue = dispatch_queue_create("com.yjf.walkman", nil);
         dispatch_async(queue, ^{
             NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:oathString]];
             
             NSDictionary *dicUser = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
             
             NSString *screenName = [dicUser objectForKey:@"screen_name"];
             
             dispatch_async(dispatch_get_main_queue(), ^{
                
                 [self refreshUserDefaultsWithWBToken:accesstoken WBUid:uid WBUName:screenName];
                 refreshShow(screenName);
             });
         });
     }];
    
}

#pragma mark -
+ (NSString *)oauthUrlString
{
    NSString *oauthUrlString = [[NSString alloc] initWithFormat:@"%@?client_id=%@&redirect_uri=%@&response_type=code&display=mobile&state=authorize", kWB_OAuth_URL, kWB_AppKey, kWB_RedirectURL];
    return oauthUrlString;
}

+ (NSString *)accessToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"WBToken"];
}

+ (void)getScreenName:(void (^)(NSString *))refresh
{
    NSString *screenName = [[NSUserDefaults standardUserDefaults] objectForKey:@"WBName"];
    refresh(screenName);
}

+ (void)logOut:(void (^)(NSString *))refresh
{
    refreshShow = refresh;
    
    NFSinaWeiboHelper *weiboHelper = [[NFSinaWeiboHelper alloc] init];
    [weiboHelper logOutCurrentUser];
}

- (void)logOutCurrentUser
{
    if (!instance)
    {
        instance = self;
        NSString *wbToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"WBToken"];
        NSLog(@"token: %@", wbToken);
        [WeiboSDK logOutWithToken:wbToken delegate:self withTag:@"User"];
    }
}

#pragma mark - WBHttpRequest Delegate
- (void)request:(WBHttpRequest *)request didFinishLoadingWithDataResult:(NSData *)data
{
    //instance = nil;
    NSString *strInfo = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@: %@; strInfo: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), strInfo);
}

- (void)request:(WBHttpRequest *)request didFinishLoadingWithResult:(NSString *)result
{
    NSLog(@"%@: %@; result: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), result);
    
    [NFSinaWeiboHelper refreshUserDefaultsWithWBToken:@"" WBUid:@"" WBUName:@"新浪微博"];
    
    // block回调
    refreshShow(@"新浪微博");
    
    instance = nil;
}

- (void)request:(WBHttpRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    //instance = nil;
    NSLog(@"%@: %@; response: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), response);
}

- (void)request:(WBHttpRequest *)request didFailWithError:(NSError *)error
{
    instance = nil;
    NSLog(@"%@: %@; error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
}

#pragma mark - Handle OpenURL
+ (BOOL)handleWBOpenURL:(NSURL *)url delegate:(id)delegate
{
    return [WeiboSDK handleOpenURL:url delegate:delegate];
}

#pragma mark -
- (void)dealloc
{
    instance = nil;
}

@end
