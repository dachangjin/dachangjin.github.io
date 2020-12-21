//
//  MediaPickerAndPreviewHelper.h
//  weapps
//
//  Created by tommywwang on 2020/8/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MediaPickerAndPreviewHelper : NSObject

@property (nonatomic, weak) UIViewController *viewController;

- (void)previewImages:(NSArray<NSString *> *)urls withCurrentIndex:(NSUInteger)index;

- (void)takeMediaFromCameraWithParams:(NSDictionary *)params
                    completionHandler:(void(^)(NSDictionary *_Nullable result, NSError *_Nullable error))completionHandler;

- (void)openPickerControllerWithParams:(NSDictionary *)params
                     completionHandler:(void(^)(NSDictionary *_Nullable result, NSError *_Nullable error))completionHandler;

- (void)openDocument:(NSString *)path
            showMenu:(BOOL)showMenu
            fileType:(NSString *)fileType
             success:(void(^)(NSDictionary *_Nullable))successBlock
                fail:(void(^)(NSError *_Nullable))failBlock;
@end

NS_ASSUME_NONNULL_END
