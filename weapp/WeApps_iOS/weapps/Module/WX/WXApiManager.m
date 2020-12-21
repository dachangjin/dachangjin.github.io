//Tencent is pleased to support the open source community by making WeDemo available.
//Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
//Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
//http://opensource.org/licenses/MIT
//Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

#import "WXApiManager.h"
#import "RandomKey.h"

static NSString* const kWXNotInstallErrorTitle = @"您还没有安装微信，不能使用微信分享功能";
static NSString* const kCancleWordingText = @"知道了";
@interface WXApiManager ()

@property (nonatomic, strong) NSString *authState;

@end

@implementation WXApiManager

#pragma mark - Life Cycle
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static WXApiManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initInPrivate];
    });
    return instance;
}

- (instancetype)initInPrivate {
    self = [super init];
    if (self) {
        _delegate = nil;
    }
    return self;
}

- (instancetype)init {
    return nil;
}

- (instancetype)copy {
    return nil;
}

#pragma mark - Public Methods
- (void)sendAuthRequestWithController:(UIViewController*)viewController
                             delegate:(id<WXAuthDelegate>)delegate {
    SendAuthReq* req = [[SendAuthReq alloc] init];
    req.scope = @"snsapi_userinfo";
    self.authState = req.state = [NSString randomKey];
    self.delegate = delegate;
    [WXApi sendAuthReq:req viewController:viewController delegate:self completion:^(BOOL success) {
        
    }];
}



- (void)sendLinkContent:(NSString *)urlString
                  title:(NSString *)title
            description:(NSString *)desc
              thumbData:(NSData *)data
                atScene:(enum WXScene)scene
          completeBlock:(ReqCompleteBlock)complete{
    
    if (![WXApi isWXAppInstalled]) {
        WXShowErrorAlert(kWXNotInstallErrorTitle,nil);
        if (complete) {
            complete(NO);
        }
    }
    
    
    
    WXWebpageObject *webpageObject = [WXWebpageObject object];
    webpageObject.webpageUrl = urlString;
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = title;
    message.description = desc;
    [message setThumbImage:[UIImage imageWithData:data]];
    message.mediaObject = webpageObject;
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneSession;

    [WXApi sendReq:req completion:complete];
}


- (void)sendImage:(NSData *)imageData
      atScene:(enum WXScene)scene
completeBlock:(ReqCompleteBlock)complete
{
    if (![WXApi isWXAppInstalled]) {
        WXShowErrorAlert(kWXNotInstallErrorTitle,nil);
        if (complete) {
            complete(NO);
        }
    }
    WXImageObject *ext = [WXImageObject object];
    ext.imageData = imageData;
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.mediaObject = ext;

    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.message = message;
    req.bText = NO;
    req.scene = scene;
    [WXApi sendReq:req completion:complete];
}


- (void)sendText:(NSString *)text
     atScene:(enum WXScene)scene
completeBlock:(ReqCompleteBlock)complete
{
    if (![WXApi isWXAppInstalled]) {
        WXShowErrorAlert(kWXNotInstallErrorTitle,nil);
        if (complete) {
           complete(NO);
        }
    }

    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.text = text;
    req.bText = YES;
    req.scene = scene;
    [WXApi sendReq:req completion:complete];
}

- (void)sendFileData:(NSData *)fileData
       fileExtension:(NSString *)extension
               title:(NSString *)title
         description:(NSString *)description
          thumbImage:(UIImage *)thumbImage
             atScene:(enum WXScene)scene
       completeBlock:(ReqCompleteBlock)complete
{
    if (![WXApi isWXAppInstalled]) {
        WXShowErrorAlert(kWXNotInstallErrorTitle,nil);
        if (complete) {
            complete(NO);
        }
    }

    WXFileObject *ext = [WXFileObject object];
    ext.fileExtension = extension;
    ext.fileData = fileData;

    WXMediaMessage *message = [WXMediaMessage message];
    message.mediaObject = ext;
    message.title = title;
    message.description = description;
    [message setThumbImage:thumbImage];
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.message = message;
    req.bText = NO;
    req.scene = scene;

    [WXApi sendReq:req completion:complete];
}

#pragma mark - WXApiDelegate
-(void)onReq:(BaseReq*)req {
    // just leave it here, WeChat will not call our app
}

-(void)onResp:(BaseResp*)resp {    
    if([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp* authResp = (SendAuthResp*)resp;
        /* Prevent Cross Site Request Forgery */
        if (![authResp.state isEqualToString:self.authState]) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(wxAuthDenied)])
                [self.delegate wxAuthDenied];
            return;
        }
        
        switch (resp.errCode) {
            case WXSuccess:
                WALOG(@"RESP:code:%@,state:%@\n", authResp.code, authResp.state);
                if (self.delegate && [self.delegate respondsToSelector:@selector(wxAuthSucceed:)])
                    [self.delegate wxAuthSucceed:authResp.code];
                break;
            case WXErrCodeAuthDeny:
                if (self.delegate && [self.delegate respondsToSelector:@selector(wxAuthDenied)])
                    [self.delegate wxAuthDenied];
                break;
            case WXErrCodeUserCancel:
                if (self.delegate && [self.delegate respondsToSelector:@selector(wxAuthCancel)])
                    [self.delegate wxAuthCancel];
            default:
                break;
        }
    }
}

@end
