//
//  NFFaceBookHelper.m
//  WalkMan
//
//  Created by yang on 14-8-21.
//  Copyright (c) 2014年 yang. All rights reserved.
//

#import "NFFaceBookHelper.h"

// Facebook
#define kFB_AppKey          @"1452360495039747"
#define kFB_AppSecret       @"9351c372dac32739915f44d7ee15c762"

void (^refreshShow)(NSString *);

@interface MyTokenCachingStrategy : FBSessionTokenCachingStrategy
@property (nonatomic, strong) NSString *tokenFilePath;
- (NSString *) filePath;
@end

@implementation MyTokenCachingStrategy
// Local cache - unique file info
static NSString* kFilename = @"TokenInfo.plist";

- (id) init
{
    self = [super init];
    if (self) {
        _tokenFilePath = [self filePath];
    }
    return self;
}

- (NSString *)filePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths lastObject];
    return [documentsDirectory stringByAppendingPathComponent:kFilename];
}

- (void)writeData:(NSDictionary *)data
{
    NSLog(@"File = %@ and Data = %@", self.tokenFilePath, data);
    BOOL success = [data writeToFile:self.tokenFilePath atomically:YES];
    if (!success) {
        NSLog(@"Error writing to file");
    }
}

- (NSDictionary *)readData
{
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:self.tokenFilePath];
    NSLog(@"File = %@ and data = %@", self.tokenFilePath, data);
    return data;
}

- (void)cacheFBAccessTokenData:(FBAccessTokenData *)accessToken {
    NSDictionary *tokenInformation = [accessToken dictionary];
    [self writeData:tokenInformation];
}

- (FBAccessTokenData *)fetchFBAccessTokenData
{
    NSDictionary *tokenInformation = [self readData];
    if (nil == tokenInformation) {
        return nil;
    } else {
        return [FBAccessTokenData createTokenFromDictionary:tokenInformation];
    }
}

- (void)clearToken
{
    [self writeData:[NSDictionary dictionaryWithObjectsAndKeys:nil]];
}


@end

@interface NFFaceBookHelper ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    id instance;
}
@end

@implementation NFFaceBookHelper

MyTokenCachingStrategy *tokenCaching = nil;

FBSession *gSession = nil;

+ (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    BOOL openSessionResult = NO;
    // Set up token strategy, if needed
    if (nil == tokenCaching) {
        tokenCaching = [[MyTokenCachingStrategy alloc] init];
    }
    // Initialize a session object with the tokenCacheStrategy
    FBSession *session = [[FBSession alloc] initWithAppID:nil
                                              permissions:@[@"public_profile", @"email", @"user_friends"]
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:tokenCaching];
    // If showing the login UI, or if a cached token is available,
    // then open the session.
    if (allowLoginUI || session.state == FBSessionStateCreatedTokenLoaded) {
        // For debugging purposes log if cached token was found
        if (session.state == FBSessionStateCreatedTokenLoaded) {
            NSLog(@"Cached token found.");
        }
        // Set the active session
        [FBSession setActiveSession:session];
        // Open the session.
        [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                completionHandler:^(FBSession *session,
                                    FBSessionState state,
                                    NSError *error) {
                    [self sessionStateChanged:session
                                        state:state
                                        error:error];
                }];
        // Return the result - will be set to open immediately from the session
        // open call if a cached token was previously found.
        openSessionResult = session.isOpen;
    }
    return openSessionResult;
}

+ (void)registerApp
{
    [self registerUserDefaults];
    [self openSessionWithAllowLoginUI:NO];
    /*
    // Whenever a person open the app, check for a cached session.
    FBSession *session = [FBSession activeSession];//[self getActiveSession];
    FBSessionState state = session.state;
    if (state == FBSessionStateCreatedTokenLoaded)
    {
        NSLog(@"Found a cached session");
        // If there's one, just open the session silently, without showing the user the login UI.
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"email", @"user_friends"] allowLoginUI:NO completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            // Handler for session state changes
            // This method will be called EACH time the session state changes,
            // also for intermediate states and NOT just when the session open
            [self sessionStateChanged:session state:state error:error];
        }];
    }
    else
    {
        [self refreshUserDefaultsWithWBToken:@"" WBUid:@"" WBUName:@"facebook"];
    }
     */
}

+ (void)registerUserDefaults
{
    NSDictionary *dicWbToken = [NSDictionary dictionaryWithObject:@"" forKey:@"FBToken"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dicWbToken];
    
    NSDictionary *dicWbUid   = [NSDictionary dictionaryWithObject:@"" forKey:@"FBUid"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dicWbUid];
    
    NSDictionary *dicWbName   = [NSDictionary dictionaryWithObject:@"Facebook" forKey:@"FBName"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dicWbName];
}

+ (void)refreshUserDefaultsWithWBToken:(NSString *)token WBUid:(NSString *)uid WBUName:(NSString *)name
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:name forKey:@"FBName"];
    [userDefaults setObject:uid forKey:@"FBUid"];
    [userDefaults setObject:token forKey:@"FBToken"];
    [userDefaults synchronize];
}

+ (void)getFacebookProfile:(FBAccessTokenData *)accessTokenData
{
    dispatch_queue_t queue = dispatch_queue_create("com.OpenShare", nil);
    dispatch_async(queue, ^{
        
        NSString *accessToken = accessTokenData.accessToken;
        NSString *fbUserID = accessTokenData.userID;
        NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@",
                               [accessToken stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURL *url = [NSURL URLWithString:urlString];
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:nil];
        
        NSDictionary *dicProfile = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];

        NSString *name = [dicProfile objectForKey:@"last_name"];
        NSLog(@"dicProfile: %@; email: %@; name: %@", dicProfile, [dicProfile objectForKey:@"email"], name);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshUserDefaultsWithWBToken:accessToken WBUid:fbUserID WBUName:name];
            if (refreshShow)
            {
                refreshShow(name);
            }
            
        });
    });
}

+ (FBSession *)getActiveSession
{
    //@synchronized(self)
    {
        if (!gSession)
        {
            MyTokenCachingStrategy *tokenCache = [[MyTokenCachingStrategy alloc] init];
            gSession = [[FBSession alloc] initWithAppID:kFB_AppKey permissions:@[@"public_profile", @"email", @"user_friends"] urlSchemeSuffix:nil tokenCacheStrategy:tokenCache];
            [FBSession setActiveSession:gSession];
        }
        return gSession;
    }
}

+ (void)getScreenName:(void (^)(NSString *))refresh
{
    NSString *screenName = [[NSUserDefaults standardUserDefaults] objectForKey:@"FBName"];
    refresh(screenName);
}

// This method will handle ALL the session state changes in the app
+ (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error
{
    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen)
    {
        NSLog(@"session opened");
        NSLog(@"token: %@", session.accessTokenData.accessToken);
        
        [self getFacebookProfile:session.accessTokenData];
        
        // Show the user the logged-in UI
        // 例如返回ui界面，通知登陆成功的信息。
        
        return;
    }
    
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
        // If the session is closed
        NSLog(@"Session closed");
        [self refreshUserDefaultsWithWBToken:@"" WBUid:@"" WBUName:@"Facebook"];
        // Show the user the logged-out UI
        
        if (refreshShow)
        {
            refreshShow(@"FaceBooK");
        }
    }

    // Handle errors
    if (error)
    {
        NSLog(@"error");
        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES)
        {
            NSLog(@"error message: %@", [FBErrorUtility userMessageForError:error]);
            
        }
        else
        {
            // If the user cancelled login, do nothing;
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled)
            {
                NSLog(@"User canceled login");
            }
            // Handle session closures that happen outside of the app
            else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession)
            {
                NSLog(@"Session error. Your current session is no longer valid. Please log in again.");
            }
            // Here we will handle all other errors with a generic error message.
            // We recommend you check our Handling Errors guide for more information
            // https://developers.facebook.com/docs/ios/errors/
            else
            {
                //Get more error information from the error
                //[[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                
                NSString *alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
                NSLog(@"%@", alertText);
            }
        }
        
        // Clear this token
        //FBSession *session = [self getActiveSession];
        [[FBSession activeSession] closeAndClearTokenInformation];
        // Show the user the logged-out UI
    }
}

// 客户端请求的方式登陆
+ (void)startAuthorize:(void (^)(NSString *))refresh
{
    refreshShow = refresh;

    FBSession *session = [FBSession activeSession];//[self getActiveSession];
    // If the session state is any of the two "open" states when the button is clicked.
    if (session.state == FBSessionStateOpen || session.state == FBSessionStateOpenTokenExtended)
    {
        // Close the session and remove the access token from the cache
        // The session state handler (in the app delegate) will be called automatically
        [session closeAndClearTokenInformation];
    }
    // If the session state is not any of the two "open" states the button is clicked.
    else
    {
        // Open a session showing the user the login UI
        // You must always ask for public_profile permissions when opening a session.
        [self openSessionWithAllowLoginUI:YES];
        /*
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"email", @"user_friends"] allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            
            NSLog(@"token: %@", session.accessTokenData.accessToken);
            
            NSLog(@"facebook---> openActiveSessionWithPublishPermissions()");
            [self sessionStateChanged:session state:status error:error];
        }];
         */
        
        //[self openSessionWithAllowLoginUI:YES];
    }
}

+ (void)startShare:(void (^)(NSString *))refresh
{
    refreshShow = refresh;
    
    /*
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"hello", @"message",
                                   @"http://www.yourweb.com", @"link",
                                   @"http://static.ak.fbcdn.net/rsrc.php/v2/y2/r/lpa-16iu9uw.gif", @"picture",
                                   @"China star", @"name",
                                   @"I love China", @"description",
                                   nil];
    [FBRequestConnection startWithGraphPath:@"me/feed" parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if( error )
        {
            NSLog( @"facebook---> message( \"%@\" ) posted failed!!!!!!!!!", @"hello" );
        }
        else
        {
            refreshShow(@"");
            NSLog( @"facebook---> message( \"%@\" ) posted successfully.", @"hello" );
        }
    }];
     */
    NFFaceBookHelper *facebookHelper = [[NFFaceBookHelper alloc] init];
    [facebookHelper startToShare];
}

+ (void)logOut:(void (^)(NSString * name))refresh
{
    
    [[FBSession activeSession] closeAndClearTokenInformation];
}

+ (void)checkPublishPermissions
{
    // Check for publish permissions
    [FBRequestConnection startWithGraphPath:@"/me/permissions"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              //__block NSString *alertText;
                              //__block NSString *alertTitle;
                              if (!error){
                                  NSDictionary *permissions= [(NSArray *)[result data] objectAtIndex:0];
                                  if (![permissions objectForKey:@"publish_actions"]){
                                      // Publish permissions not found, ask for publish_actions
                                      [self requestPublishPermissions];
                                      
                                  } else {
                                      // Publish permissions found, publish the OG story
                                      //[self publishStory];
                                  }
                                  
                              } else {
                                  // There was an error, handle it
                                  // See https://developers.facebook.com/docs/ios/errors/
                              }
                          }];
}

+ (void)requestPublishPermissions
{
    FBSession *session = [FBSession activeSession];//[self getActiveSession];
    [session requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                          defaultAudience:FBSessionDefaultAudienceFriends
                                        completionHandler:^(FBSession *session, NSError *error) {
                                            __block NSString *alertText;
                                            __block NSString *alertTitle;
                                            if (!error) {
                                                if ([FBSession.activeSession.permissions
                                                     indexOfObject:@"publish_actions"] == NSNotFound){
                                                    // Permission not granted, tell the user we will not publish
                                                    alertTitle = @"Permission not granted";
                                                    alertText = @"Your action will not be published to Facebook.";
                                                    NSLog(@"%@, %@", alertTitle, alertText);
                                                } else {
                                                    // Permission granted, publish the OG story
                                                    //[self publishStory];
                                                }
                                                
                                            } else {
                                                // There was an error, handle it
                                                // See https://developers.facebook.com/docs/ios/errors/
                                            }
                                        }];
}

- (void)startToShare
{
    if (!instance)
    {
        instance = self;
        
        [self postObject:nil];
    }
}

- (void)postObject:(id)sender
{
    
    // We will post an object on behalf of the user
    // These are the permissions we need:
    NSArray *permissionsNeeded = @[@"publish_actions"];
    
    // Request the permissions the user currently has
    [FBRequestConnection startWithGraphPath:@"/me/permissions"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error){
                                  NSDictionary *currentPermissions= [(NSArray *)[result data] objectAtIndex:0];
                                  NSLog(@"current permissions %@", currentPermissions);
                                  NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
                                  
                                  // Check if all the permissions we need are present in the user's current permissions
                                  // If they are not present add them to the permissions to be requested
                                  for (NSString *permission in permissionsNeeded){
                                      if (![currentPermissions objectForKey:permission]){
                                          [requestPermissions addObject:permission];
                                      }
                                  }
                                  
                                  // If we have permissions to request
                                  if ([requestPermissions count] > 0){
                                      // Ask for the missing permissions
                                      [FBSession.activeSession requestNewPublishPermissions:requestPermissions
                                                                            defaultAudience:FBSessionDefaultAudienceFriends
                                                                          completionHandler:^(FBSession *session, NSError *error) {
                                                                              if (!error) {
                                                                                  // Permission granted
                                                                                  NSLog(@"new permissions %@", [FBSession.activeSession permissions]);
                                                                                  // We can request the user information
                                                                                  [self makeRequestToPostObject];
                                                                              } else {
                                                                                  // An error occurred, we need to handle the error
                                                                                  // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                                                                  NSLog(@"error %@", error.description);
                                                                              }
                                                                          }];
                                  } else {
                                      // Permissions are present
                                      // We can request the user information
                                      [self makeRequestToPostObject];
                                  }
                                  
                              } else {
                                  // An error occurred, we need to handle the error
                                  // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                  NSLog(@"error %@", error.description);
                              }
                          }];
}

- (void)makeRequestToPostObject
{
    // Retrieve a picture from the device's photo library
    /*
     NOTE: SDK Image size limits are 480x480px minimum resolution to 12MB maximum file size.
     In this app we're not making sure that our image is within those limits but you should.
     Error code for images that go below or above the size limits is 102.
     */
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [imagePicker setDelegate:self];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:imagePicker animated:YES completion:nil];
}

// When the user is done picking the image
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Get the UIImage
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    // Dismiss the image picker off the screen
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
    
    // stage the image
    [FBRequestConnection startForUploadStagingResourceWithImage:image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        __block NSString *alertText;
        __block NSString *alertTitle;
        if(!error) {
            NSLog(@"Successfuly staged image with staged URI: %@", [result objectForKey:@"uri"]);
            
            // Package image inside a dictionary, inside an array like we'll need it for the object
            NSArray *image = @[@{@"url": [result objectForKey:@"uri"], @"user_generated" : @"true" }];
            
            // Create an object
            NSMutableDictionary<FBOpenGraphObject> *restaurant = [FBGraphObject openGraphObjectForPost];
            
            // specify that this Open Graph object will be posted to Facebook
            restaurant.provisionedForPost = YES;
            
            // Add the standard object properties
            restaurant[@"og"] = @{ @"title":@"mytitle", @"type":@"restaurant.restaurant", @"description":@"my description", @"image":image };
            
            // Add the properties restaurant inherits from place
            restaurant[@"place"] = @{ @"location" : @{ @"longitude": @"-58.381667", @"latitude":@"-34.603333"} };
            
            // Add the properties particular to the type restaurant.restaurant
            restaurant[@"restaurant"] = @{@"category": @[@"Mexican"],
                                          @"contact_info": @{@"street_address": @"123 Some st",
                                                             @"locality": @"Menlo Park",
                                                             @"region": @"CA",
                                                             @"phone_number": @"555-555-555",
                                                             @"website": @"http://www.example.com"}};
            
            // Make the Graph API request to post the object
            FBRequest *request = [FBRequest requestForPostWithGraphPath:@"me/objects/restaurant.restaurant"
                                                            graphObject:@{@"object":restaurant}];
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    // Success! Include your code to handle the results here
                    NSLog(@"result: %@", result);
                    NSString *_objectID = [result objectForKey:@"id"];
                    alertTitle = @"Object successfully created";
                    alertText = [NSString stringWithFormat:@"An object with id %@ has been created", _objectID];
                    [[[UIAlertView alloc] initWithTitle:alertTitle
                                                message:alertText
                                               delegate:self
                                      cancelButtonTitle:@"OK!"
                                      otherButtonTitles:nil] show];
                } else {
                    // An error occurred, we need to handle the error
                    // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                    NSLog(@"error %@", error.description);
                }
            }];
        } else {
            // An error occurred, we need to handle the error
            // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
            NSLog(@"error %@", error.description);
        }
    }];
}

#pragma mark -
+ (void)handleStateChange
{
    FBSession *session = [FBSession activeSession];//[self getActiveSession];
    [session setStateChangeHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        [NFFaceBookHelper sessionStateChanged:session state:status error:error];
    }];
}

+ (void)handleBecomeActive
{
    [FBAppCall handleDidBecomeActive];
}

+ (BOOL)handleFBOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication
{
    return [[FBSession activeSession] handleOpenURL:url];//[FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}

+ (void)close
{
    FBSession *session = [FBSession activeSession];//[self getActiveSession];
    [session close];
    //session = nil;
}

@end
