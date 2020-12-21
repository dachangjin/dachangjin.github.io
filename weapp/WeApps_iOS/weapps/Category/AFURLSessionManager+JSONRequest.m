//
//  AFURLSessionManager+JSONRequest.m
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "AFURLSessionManager+JSONRequest.h"

#import "WXNetworkConfigManager.h"
#import "WXNetworkConfigItem.h"


@implementation AFURLSessionManager (JSONRequest)

- (NSURLSessionTask *)JSONTaskForHost:(NSString *)host
                               params:(NSDictionary *)params
                        configKeyPath:(NSString *)configKeyPath
                       withCompletion:(JSONCallBack)handler {
    WXNetworkConfigItem *config = [[WXNetworkConfigManager sharedManager] getConfigForKeyPath:configKeyPath];
    if (config == nil) {
        WALOG(@"Configure Item Not Exist For This Request: %@", configKeyPath);
        return nil;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *urlString = [host stringByAppendingString:config.requestPath];
    
    NSMutableArray *paramsArray = [[NSMutableArray alloc] init];
    for (NSString *key in [params allKeys]) {
        NSString *s = [NSString stringWithFormat:@"%@=%@",
                       key,
                       [params[key]
                        isKindOfClass:[NSString class]]? [params[key]
                                                          stringByAddingPercentEncodingWithAllowedCharacters:
                                                          [NSCharacterSet URLQueryAllowedCharacterSet]]:params[key]];
       [paramsArray addObject:s];
    }
    NSString *query = [paramsArray componentsJoinedByString:@"&"];
    if (kStringEqualToString([config.httpMethod uppercaseString], @"GET")) {
        urlString = [urlString stringByAppendingString:query];
    } else {
        NSData *bodydata = [NSJSONSerialization dataWithJSONObject:params options:NSJSONReadingMutableLeaves|NSJSONReadingAllowFragments error:nil];
        [request setHTTPBody:bodydata];
        [request setValue:[NSString stringWithFormat:@"%ld",(long)bodydata.length] forHTTPHeaderField:@"Content-length"];
    }
    
    /* Setup Request */
    NSURL *url = [NSURL URLWithString:urlString];
    [request setURL:url];
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:config.httpMethod];
    return [self _JSONTaskForRequest:request withCompletion:handler];
}


- (NSURLSessionTask *)JSONTaskForURL:(NSString *)URLString
                              method:(NSString *)method
                              params:(NSDictionary *)params
                      withCompletion:(JSONCallBack)handler
{
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSMutableArray *paramsArray = [[NSMutableArray alloc] init];
    for (NSString *key in [params allKeys]) {
        NSString *s = [NSString stringWithFormat:@"%@=%@",
                       key,
                       [params[key]
                        isKindOfClass:[NSString class]]? [params[key]
                                                          stringByAddingPercentEncodingWithAllowedCharacters:
                                                          [NSCharacterSet URLQueryAllowedCharacterSet]]:params[key]];
       [paramsArray addObject:s];
    }
    NSString *query = [paramsArray componentsJoinedByString:@"&"];
    if (kStringEqualToString(method, @"GET")) {
        URLString = [NSString stringWithFormat:@"%@?%@",URLString,query];
    } else {
        NSData *bodydata = [NSJSONSerialization dataWithJSONObject:params options:NSJSONReadingMutableLeaves|NSJSONReadingAllowFragments error:nil];
        [request setHTTPBody:bodydata];
        [request setValue:[NSString stringWithFormat:@"%ld",(long)bodydata.length] forHTTPHeaderField:@"Content-length"];
    }
    
    /* Setup Request */
    NSURL *url = [NSURL URLWithString:URLString];
    [request setURL:url];
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:method];
    return [self _JSONTaskForRequest:request withCompletion:handler];
}


- (NSURLSessionTask *)_JSONTaskForRequest:(NSURLRequest *)request
                           withCompletion:(JSONCallBack)handler
{
    return [self dataTaskWithRequest:request
                      uploadProgress:nil
                    downloadProgress:nil
                   completionHandler:^(NSURLResponse * response, id responseObject, NSError* error)
    {
        NSDictionary *dict = (NSDictionary *)responseObject;
        /* Process Network Error */
        if (error) {
            WALOG(@"NetWork Error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                handler (nil, error);
            });
            return;
        }
        /* Process Response Error */
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *httpError = [NSError errorWithDomain:@"Http Response Error"
                                                         code:httpResponse.statusCode
                                                     userInfo:nil];
                handler (nil, httpError);
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            handler (dict, nil);
        });
    }];
}

@end
