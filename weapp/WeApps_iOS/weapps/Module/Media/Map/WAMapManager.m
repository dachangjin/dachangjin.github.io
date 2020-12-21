//
//  WAMapManager.m
//  weapps
//
//  Created by tommywwang on 2020/9/29.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAMapManager.h"
#import "UIScrollView+WKChildScrollVIew.h"
#import "WACallbackModel.h"
#import "WKWebViewHelper.h"

@interface WAMapViewContainerModel: NSObject

@property (nonatomic, copy) NSString *mapId;
@property (nonatomic, weak) WAMapViewContainer *mapView;
@property (nonatomic, weak) WebView *webView;
@property (nonatomic, copy) NSString *tapCallback;
@property (nonatomic, copy) NSString *markerTapCallback;
@property (nonatomic, copy) NSString *labelTapCallback;
@property (nonatomic, copy) NSString *controlTapCallback;
@property (nonatomic, copy) NSString *callOutTapCallback;
@property (nonatomic, copy) NSString *updatedCallback;
@property (nonatomic, copy) NSString *regionChangeCallback;
@property (nonatomic, copy) NSString *poiTapCallback;
@property (nonatomic, copy) NSString *anchorPointTapCallback;

@end

@implementation WAMapViewContainerModel

@end

@interface WAMapManager ()
{
    NSLock *_lock;
    NSMutableDictionary<NSString *, WAMapViewContainerModel *> *_mapViewModels;
}

@end

@implementation WAMapManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [[NSLock alloc] init];
        _mapViewModels = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)createMapViewWithMapId:(NSString *)mapId
                      position:(NSDictionary *)position
                         state:(NSDictionary *)state
                     inWebView:(WebView *)webView
             completionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    //查找同层渲染view
    UIScrollView *container = [WKWebViewHelper findContainerInWebView:webView
                                                           withParams:position];
    if (!container) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"createMapView" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"can not find mapView container in webView"
            }]);
        }
    }
    //已存在对应mapView
    if ([self mapViewModelWithKey:mapId]) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"createMapView" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"mapView already exist with id:{%@} in webView", mapId]
            }]);
        }
        return;
    }
    
    WAMapViewContainerModel *model = [[WAMapViewContainerModel alloc] init];
    //地图style需要初始化时候设置
    int style = 1;
    if (state[@"layerStyle"]) {
        style = [state[@"layerStyle"] intValue];
    }
    WAMapViewContainer *mapView = [[WAMapViewContainer alloc] initWithMapId:mapId
                                                    style:style
                                                    frame:container.bounds];
    //自动适配camera DOM节点的大小
    container.boundsChangeBlock = ^(CGRect rect) {
        mapView.frame = rect;
    };
    [container insertSubview:mapView atIndex:0];
    //设置回调
    @weakify(model)
    @weakify(webView)
    mapView.tapBlock = ^(CGFloat longitude, CGFloat latitude){
        @strongify(model)
        @strongify(webView)
        if (model.tapCallback) {
            [WKWebViewHelper successWithResultData:@{
                @"longitude": @(longitude),
                @"latitude" : @(latitude)
            }
                                           webView:webView
                                          callback:model.tapCallback];
        }
    };
    mapView.markerTapBlock = ^(NSNumber * _Nonnull markerId) {
        @strongify(model)
        @strongify(webView)
        if (model.markerTapCallback) {
            [WKWebViewHelper successWithResultData:@{
                @"markerId": markerId
            }
                                           webView:webView
                                          callback:model.markerTapCallback];
        }
    };
    mapView.labelTapBlock = ^(NSNumber * _Nonnull markerId) {
        @strongify(model)
        @strongify(webView)
        if (model.labelTapCallback) {
            [WKWebViewHelper successWithResultData:@{
                @"markerId": markerId
            }
                                           webView:webView
                                          callback:model.labelTapCallback];
        }
    };
    mapView.controlTapBlock = ^(NSNumber * _Nonnull controlId) {
        @strongify(model)
        @strongify(webView)
        if (model.controlTapCallback) {
            [WKWebViewHelper successWithResultData:@{
                @"controlId": controlId
            }
                                           webView:webView
                                          callback:model.controlTapCallback];
        }
    };
    mapView.calloutTapBlock = ^(NSNumber * _Nonnull markerId) {
        @strongify(model)
        @strongify(webView)
        if (model.callOutTapCallback) {
            [WKWebViewHelper successWithResultData:@{
                @"markerId": markerId
            }
                                           webView:webView
                                          callback:model.callOutTapCallback];
        }
    };
    mapView.updateBlock = ^{
        @strongify(model)
        @strongify(webView)
        if (model.updatedCallback) {
            [WKWebViewHelper successWithResultData:nil
                                           webView:webView
                                          callback:model.updatedCallback];
        }
    };
    mapView.regionChangeBlock = ^{
        @strongify(model)
        @strongify(webView)
        if (model.regionChangeCallback) {
            [WKWebViewHelper successWithResultData:nil
                                           webView:webView
                                          callback:model.regionChangeCallback];
        }
    };
    mapView.poiTapBlock = ^(NSString * _Nonnull name, CGFloat longitude, CGFloat latitude) {
        @strongify(model)
        @strongify(webView)
        if (model.poiTapCallback) {
            [WKWebViewHelper successWithResultData:@{
                @"name"     : name,
                @"longitude": @(longitude),
                @"latitude" : @(latitude)
            }
                                           webView:webView
                                          callback:model.poiTapCallback];
        }
    };
    mapView.anchorPointTapBlock = ^(CGFloat longitude, CGFloat latitude) {
        @strongify(model)
        @strongify(webView)
        if (model.anchorPointTapCallback) {
            [WKWebViewHelper successWithResultData:@{
                @"longitude": @(longitude),
                @"latitude" : @(latitude)
            }
                                           webView:webView
                                          callback:model.anchorPointTapCallback];
        }
    };
    @weakify(self)
    [mapView addViewWillDeallocBlock:^(WAContainerView * _Nonnull containerView) {
        @strongify(self)
        [self removeMapViewModelWithKey:mapId];
    }];
    
    model.webView = webView;
    model.mapId = mapId;
    model.mapView = mapView;
    //设置map属性
    [mapView setState:state];
    //设置model callback
    [self setModel:model callbackWithState:state];
    //存储model
    [self addMapViewModel:model withKey:mapId];
    //webView生命周期回调
    [self addLifeCycleManager:webView mapId:mapId];
}

/// 设置对应mapView属性
/// @param mapId mapViewId
/// @param state 属性字典
- (void)mapView:(NSString *)mapId setState:(NSDictionary *)state
{
    WAMapViewContainer *mapView = [self findMapViewWithMapId:mapId
                                             domain:@"getCenterLocation"
                                  completionHandler:nil];
    
    if (mapView) {
        [mapView setState:state];
    }
    [self setModel:[self mapViewModelWithKey:mapId] callbackWithState:state];
}

/// 获取当前地图中心的经纬度。返回的是 gcj02 坐标系
/// @param mapId 指定 mapView
/// @param completionHandler 完成回调
- (void)mapView:(NSString *)mapId getCenterLocationWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMapViewContainer *mapView = [self findMapViewWithMapId:mapId
                                             domain:@"getCenterLocation"
                                  completionHandler:completionHandler];
    if (mapView) {
        [mapView getCenterLocationWithCompletionHandler:completionHandler];
    }
}

/// 获取当前地图的视野范围
/// @param mapId 指定 mapView
/// @param completionHandler 完成回调
- (void)mapView:(NSString *)mapId getRegionWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMapViewContainer *mapView = [self findMapViewWithMapId:mapId
                                             domain:@"getRegion"
                                  completionHandler:completionHandler];
    if (mapView) {
        [mapView getRegionWithCompletionHandler:completionHandler];
    }
}

/// 获取当前地图的旋转角
/// @param mapId 指定 mapView
/// @param completionHandler 完成回调
- (void)mapView:(NSString *)mapId getRotateWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMapViewContainer *mapView = [self findMapViewWithMapId:mapId
                                             domain:@"getRotate"
                                  completionHandler:completionHandler];
    if (mapView) {
        [mapView getRotateWithCompletionHandler:completionHandler];
    }
}

/// 获取当前地图的缩放级别
/// @param mapId 指定 mapView
/// @param completionHandler 完成回调
- (void)mapView:(NSString *)mapId getScaleWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMapViewContainer *mapView = [self findMapViewWithMapId:mapId
                                             domain:@"getScale"
                                  completionHandler:completionHandler];
    if (mapView) {
        [mapView getScaleWithCompletionHandler:completionHandler];
    }
}

/// 获取当前地图的倾斜角
/// @param mapId 指定 mapView
/// @param completionHandler 完成回调
- (void)mapView:(NSString *)mapId getSkewWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMapViewContainer *mapView = [self findMapViewWithMapId:mapId
                                             domain:@"getSkew"
                                  completionHandler:completionHandler];
    if (mapView) {
        [mapView getSkewWithCompletionHandler:completionHandler];
    }
}

/// 缩放视野展示所有经纬度
/// @param mapId 指定 mapView
/// @param points 要显示在可视区域内的坐标点列表
/// @param padding 坐标点形成的矩形边缘到地图边缘的距离，单位像素。格式为[上,右,下,左]
/// @param completionHandler 完成回调
- (void)mapView:(NSString *)mapId includePoints:(NSArray *)points
        padding:(NSArray *)padding
withCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMapViewContainer *mapView = [self findMapViewWithMapId:mapId
                                             domain:@"includePoints"
                                  completionHandler:completionHandler];
    if (mapView) {
        [mapView includePoints:points
                       padding:padding
         withCompletionHandler:completionHandler];
    }
}

/// 沿指定路径移动 marker，用于轨迹回放等场景。动画完成时触发回调事件，若动画进行中，对同一 marker 再次调用 moveAlong 方法，前一次的动画将被打断
/// @param mapId 指定 mapView
/// @param markerId 指定 marker
/// @param path 移动路径的坐标串，坐标点格式 {longitude, latitude}
/// @param autoRotate 根据路径方向自动改变 marker 的旋转角度
/// @param duration 平滑移动的时间
/// @param completionHandler 完成回调
- (void)mapView:(NSString *)mapId
 moveMarkerAlong:(NSNumber *)markerId
       withPath:(NSArray *)path
     autoRotate:(BOOL)autoRotate
       duration:(CGFloat)duration
completionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMapViewContainer *mapView = [self findMapViewWithMapId:mapId
                                             domain:@"moveAlong"
                                  completionHandler:completionHandler];
    if (mapView) {
        [mapView moveMarkerAlong:markerId
                       withPath:path
                     autoRotate:autoRotate
                       duration:duration
              completionHandler:completionHandler];
    }
}

/// 将地图中心移置当前定位点，此时需设置地图组件 show-location 为true
/// @param mapId 指定 mapView
/// @param location 目标位置
/// @param completionHandler 完成回调
- (void)mapView:(NSString *)mapId
 moveToLocation:(CLLocationCoordinate2D)location
withCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMapViewContainer *mapView = [self findMapViewWithMapId:mapId
                                             domain:@"moveToLocation"
                                  completionHandler:completionHandler];
    if (mapView) {
        [mapView moveToLocation:location
          withCompletionHandler:completionHandler];
    }
}

/// 设置地图中心点偏移，向后向下为增长，屏幕比例范围(0.25~0.75)，默认偏移为[0.5, 0.5]
/// @param mapId 指定 mapView
/// @param offset 偏移量，两位数组
/// @param completionHandler 完成回调
- (void)mapView:(NSString *)mapId
setCenterOffset:(CGPoint)offset
withCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMapViewContainer *mapView = [self findMapViewWithMapId:mapId
                                             domain:@"setCenterOffset"
                                  completionHandler:completionHandler];
    if (mapView) {
        [mapView setCenterOffset:offset
           withCompletionHandler:completionHandler];
    }
}

/// 平移marker，带动画
/// @param mapId 指定 mapView
/// @param markerId 指定 marker
/// @param destination 指定 marker 移动到的目标点
/// @param autoRotate 移动过程中是否自动旋转 marker
/// @param rotate marker 的旋转角度
/// @param moveWithRotate 平移和旋转同时进行
/// @param duration 动画持续时长，平移与旋转分别计算
/// @param animationEnd 动画结束回调函数
/// @param completionHandler 完成回调
- (void)mapView:(NSString *)mapId
 translateMarker:(NSNumber *)markerId
  toDestination:(CLLocationCoordinate2D)destination
 withAutoRotate:(BOOL)autoRotate
         rotate:(CGFloat)rotate
 moveWithRotate:(BOOL)moveWithRotate
       duration:(NSTimeInterval)duration
   animationEnd:(NSString *)animationEnd
completionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMapViewContainer *mapView = [self findMapViewWithMapId:mapId
                                             domain:@"translateMarker"
                                  completionHandler:completionHandler];
    if (mapView) {
        [mapView translateMarker:markerId
                   toDestination:destination
                  withAutoRotate:autoRotate
                          rotate:rotate
                  moveWithRotate:moveWithRotate
                        duration:duration
                    animationEnd:animationEnd
               completionHandler:completionHandler];
    }
}


#pragma mark - private

- (WAMapViewContainer *)findMapViewWithMapId:(NSString *)mapId
                                      domain:(NSString *)domain
                           completionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMapViewContainerModel *model = [self mapViewModelWithKey:mapId];
    if (!model) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:domain
                                                           code:-1
                                                       userInfo:@
            {
            NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find mapView with mapId:%@", mapId]
            }]);
        }
    }
    return model.mapView;
}

- (void)setModel:(WAMapViewContainerModel *)model callbackWithState:(NSDictionary *)state
{
    if (!model) {
        return;
    }
    if (state[@"bindtap"]
        && [state[@"bindtap"] isKindOfClass:[NSString class]]) {
        model.tapCallback = state[@"bindtap"];
    }
    if (state[@"bindmarkertap"] &&
         [state[@"bindmarkertap"] isKindOfClass:[NSString class]]) {
        model.markerTapCallback = state[@"bindmarkertap"];
    }
    if (state[@"bindlabeltap"] &&
        [state[@"bindlabeltap"] isKindOfClass:[NSString class]]) {
        model.labelTapCallback = state[@"bindlabeltap"];
    }
    if (state[@"bindcontroltap"] &&
        [state[@"bindcontroltap"] isKindOfClass:[NSString class]]) {
        model.controlTapCallback = state[@"bindcontroltap"];
    }
    if (state[@"bindcallouttap"] &&
        [state[@"bindcallouttap"] isKindOfClass:[NSString class]]) {
        model.callOutTapCallback = state[@"bindcallouttap"];
    }
    if (state[@"bindupdated"] &&
        [state[@"bindupdated"] isKindOfClass:[NSString class]]) {
        model.updatedCallback = state[@"bindupdated"];
    }
    if (state[@"bindregionchange"] &&
        [state[@"bindregionchange"] isKindOfClass:[NSString class]]) {
        model.regionChangeCallback = state[@"bindregionchange"];
    }
    if (state[@"bindpoitap"] &&
        [state[@"bindpoitap"] isKindOfClass:[NSString class]]) {
        model.poiTapCallback = state[@"bindpoitap"];
    }
    if (state[@"bindanchorpointtap"] &&
        [state[@"bindanchorpointtap"] isKindOfClass:[NSString class]]) {
        model.anchorPointTapCallback = state[@"bindanchorpointtap"];
    }
}

- (void)addLifeCycleManager:(WebView *)webView mapId:(NSString *)mapId{
    @weakify(self)
    [webView addViewWillDeallocBlock:^(WebView * webView) {
        @strongify(self);
        WAMapViewContainerModel *model = [self mapViewModelWithKey:mapId];
        if (model) {
//            [model.mapView clean];
        }
        [self removeMapViewModelWithKey:mapId];
    }];
}


- (void)addMapViewModel:(WAMapViewContainerModel *)model withKey:(NSString *)key
{
    NSParameterAssert(model);
    NSParameterAssert(key);
    [_lock lock];
    _mapViewModels[key] = model;
    [_lock unlock];
}

- (void)removeMapViewModelWithKey:(NSString *)key
{
    NSParameterAssert(key);
    [_lock lock];
    [_mapViewModels removeObjectForKey:key];
    [_lock unlock];
}

- (WAMapViewContainerModel *)mapViewModelWithKey:(NSString *)key
{
    NSParameterAssert(key);
    WAMapViewContainerModel *model = nil;
    [_lock lock];
    model = _mapViewModels[key];
    [_lock unlock];
    return  model;
}

@end
