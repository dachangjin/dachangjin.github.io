//
//  WAMapViewContainer.h
//  weapps
//
//  Created by tommywwang on 2020/9/29.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAContainerView.h"
#import <CoreLocation/CoreLocation.h>


NS_ASSUME_NONNULL_BEGIN

typedef void(^WAMapViewContainerCompletionHandler)(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error);

typedef void(^WAMapViewContainerTapBlock)(CGFloat longitude,
                                 CGFloat latitude);
typedef void(^WAMapViewContainerMarkerTapBlock)(NSNumber *markerId);
typedef void(^WAMapViewContainerLabelTapBlock)(NSNumber *markerId);
typedef void(^WAMapViewContainerControlTapBlock)(NSNumber *controlId);
typedef void(^WAMapViewContainerCalloutTapBlock)(NSNumber *markerId);
typedef void(^WAMapViewContainerUpdatedBlock)(void);
typedef void(^WAMapViewContainerRegionChangeBlock)(void);
typedef void(^WAMapViewContainerPoiTapBlock)(NSString *name,
                                    CGFloat longitude,
                                    CGFloat latitude);
typedef void(^WAMapViewContainerAnchorPoiontTapBlock)(CGFloat longitude,
                                           CGFloat latitude);

@interface WAMapViewContainer : WAContainerView



@property (nonatomic, copy, readonly) NSString *mapId;

@property (nonatomic, copy) WAMapViewContainerTapBlock tapBlock;

@property (nonatomic, copy) WAMapViewContainerMarkerTapBlock markerTapBlock;

@property (nonatomic, copy) WAMapViewContainerLabelTapBlock labelTapBlock;

@property (nonatomic, copy) WAMapViewContainerControlTapBlock controlTapBlock;

@property (nonatomic, copy) WAMapViewContainerCalloutTapBlock calloutTapBlock;

@property (nonatomic, copy) WAMapViewContainerUpdatedBlock updateBlock;

@property (nonatomic, copy) WAMapViewContainerRegionChangeBlock regionChangeBlock;

@property (nonatomic, copy) WAMapViewContainerPoiTapBlock poiTapBlock;

@property (nonatomic, copy) WAMapViewContainerAnchorPoiontTapBlock anchorPointTapBlock;


- (id)initWithMapId:(NSString *)mapId style:(int)style frame:(CGRect)frame;

/// 设置mapView相关属性
/// @param state 属性字典
- (void)setState:(NSDictionary *)state;

/// 获取当前地图中心的经纬度。返回的是 gcj02 坐标系
/// @param completionHandler 完成回调
- (void)getCenterLocationWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler;

/// 获取当前地图的视野范围
/// @param completionHandler 完成回调
- (void)getRegionWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler;

/// 获取当前地图的旋转角
/// @param completionHandler 完成回调
- (void)getRotateWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler;

/// 获取当前地图的缩放级别
/// @param completionHandler 完成回调
- (void)getScaleWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler;

/// 获取当前地图的倾斜角
/// @param completionHandler 完成回调
- (void)getSkewWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler;

/// 缩放视野展示所有经纬度
/// @param points 要显示在可视区域内的坐标点列表
/// @param padding 坐标点形成的矩形边缘到地图边缘的距离，单位像素。格式为[上,右,下,左]
/// @param completionHandler 完成回调
- (void)includePoints:(NSArray *)points
              padding:(NSArray *)padding
withCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler;

/// 沿指定路径移动 marker，用于轨迹回放等场景。动画完成时触发回调事件，若动画进行中，对同一 marker 再次调用 moveAlong 方法，前一次的动画将被打断
/// @param markerId 指定 marker
/// @param path 移动路径的坐标串，坐标点格式 {longitude, latitude}
/// @param autoRotate 根据路径方向自动改变 marker 的旋转角度
/// @param duration 平滑移动的时间
/// @param completionHandler 完成回调
- (void)moveMarkerAlong:(NSNumber *)markerId
               withPath:(NSArray *)path
             autoRotate:(BOOL)autoRotate
               duration:(CFTimeInterval)duration
      completionHandler:(WAMapViewContainerCompletionHandler)completionHandler;

/// 将地图中心移置当前定位点，此时需设置地图组件 show-location 为true
/// @param location 目标位置
/// @param completionHandler 完成回调
- (void)moveToLocation:(CLLocationCoordinate2D)location
 withCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler;

/// 设置地图中心点偏移，向后向下为增长，屏幕比例范围(0.25~0.75)，默认偏移为[0.5, 0.5]
/// @param offset 偏移量
/// @param completionHandler 完成回调
- (void)setCenterOffset:(CGPoint)offset
  withCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler;

/// 平移marker，带动画
/// @param markerId 指定 marker
/// @param destination 指定 marker 移动到的目标点
/// @param autoRotate 移动过程中是否自动旋转 marker
/// @param rotate marker 的旋转角度
/// @param moveWithRotate 平移和旋转同时进行
/// @param duration 动画持续时长，平移与旋转分别计算
/// @param animationEnd 动画结束回调函数
/// @param completionHandler 完成回调
- (void)translateMarker:(NSNumber *)markerId
          toDestination:(CLLocationCoordinate2D)destination
         withAutoRotate:(BOOL)autoRotate
                 rotate:(CGFloat)rotate
         moveWithRotate:(BOOL)moveWithRotate
               duration:(NSTimeInterval)duration
        animationEnd:(NSString *)animationEnd
        completionHandler:(WAMapViewContainerCompletionHandler)completionHandler;
@end

NS_ASSUME_NONNULL_END
