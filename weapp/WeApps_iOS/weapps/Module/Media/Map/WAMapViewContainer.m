//
//  WAMapViewContainer.m
//  weapps
//
//  Created by tommywwang on 2020/9/29.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAMapViewContainer.h"
#import "Masonry.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <QMapKit/QPinAnnotationView.h>
#import <QMapKit/QPolygon.h>
#import <QMapKit/QPolyline.h>
#import <QMapKit/QCircle.h>
#import <QMapKit/QPolygonView.h>
#import <QMapKit/QPolylineView.h>
#import <QMapKit/QCircleView.h>
#import "WAMapView.h"

#import "UIView+QMUI.h"
#import "QMUILabel.h"
#import "WAMarker.h"
#import "WAAnnotationView.h"
#import "QMUAnnotationAnimator.h"
#import "PathUtils.h"
#import "QAnnotationView+Animation.h"

@interface QMULocation : NSObject <QMULocation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@end

@implementation QMULocation

@end



@interface WAMapViewContainer ()<QMapViewDelegate>

@property (nonatomic, strong) WAMapView *mapView;
@property (nonatomic, strong) NSArray <WAMarker *> *markers;
@property (nonatomic, strong) NSArray <WAPolyline *> *polylines;
@property (nonatomic, strong) NSArray <WAPolygon *> *polygons;
@property (nonatomic, strong) NSArray <WACircle *> *circles;
@property (nonatomic, strong) NSArray <WAControl *> *controls;

@end


@implementation WAMapViewContainer


- (id)initWithMapId:(NSString *)mapId style:(int)style frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _mapView = [[WAMapView alloc] initWithFrame:frame];
        _mapView.delegate = self;
        _mapView.scrollEnabled = YES;
        _mapView.zoomEnabled = YES;
        _mapView.shows3DBuildings = NO;
        [_mapView setMapStyle:style];
        _mapId = mapId;
        self.userInteractionEnabled = YES;
        [self addSubview:_mapView];
        [self addConstraints];
    }
    return self;
}

- (void)addConstraints
{
    [self.mapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self).insets(UIEdgeInsetsMake(0, 0, 0, 0));
    }];
}


/// 设置mapView相关属性
/// @param state 属性字典
- (void)setState:(NSDictionary *)state
{
    if (state[@"longitude"] &&
        [state[@"longitude"] isKindOfClass:[NSNumber class]] &&
        state[@"latitude"] &&
        [state[@"latitude"] isKindOfClass:[NSNumber class]]) {
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake([state[@"latitude"] floatValue],
                                                                   [state[@"longitude"] floatValue]);
        [_mapView setCenterCoordinate:center];
    }
    if (state[@"scale"] &&
        [state[@"scale"] isKindOfClass:[NSNumber class]]) {
        [_mapView setZoomLevel:[state[@"scale"] floatValue]];
    }
    if (state[@"minScale"] &&
        [state[@"minScale"] isKindOfClass:[NSNumber class]]) {
        [_mapView setMinZoomLevel:[state[@"minScale"] floatValue]
                     maxZoomLevel:_mapView.maxZoomLevel];
    }
    if (state[@"maxScale"] &&
        [state[@"maxScale"] isKindOfClass:[NSNumber class]]) {
        [_mapView setMinZoomLevel:_mapView.minZoomLevel
                     maxZoomLevel:[state[@"maxScale"] floatValue]];
    }
    if (state[@"markers"] &&
        [state[@"markers"] isKindOfClass:[NSArray class]]) {
        [self addMarkers:state[@"markers"]];
    }
//    if (state[@"covers"] && [state[@"covers"] isKindOfClass:[NSArray class]]) {
//        [self addCovers:state[@"covers"]];
//    }
    if (state[@"polyline"] &&
        [state[@"polyline"] isKindOfClass:[NSArray class]]) {
        [self addPolylines:state[@"polyline"]];
    }
    if (state[@"circles"] &&
        [state[@"circles"] isKindOfClass:[NSArray class]]) {
        [self addCircles:state[@"circles"]];
    }
    if (state[@"controls"] && [state[@"controls"] isKindOfClass:[NSArray class]]) {
        [self addControls:state[@"controls"]];
    }
    if (state[@"includePoints"] && [state[@"includePoints"] isKindOfClass:[NSArray class]]) {
        [self includePoints:state[@"includePoints"] padding:nil];
    }
    if (state[@"showLocation"] &&
        [state[@"showLocation"] isKindOfClass:[NSNumber class]]) {
        _mapView.showsUserLocation = [state[@"showLocation"] boolValue];
    }
    if (state[@"polygons"]
        && [state[@"polygons"] isKindOfClass:[NSArray  class]]) {
        [self addPolygons:state[@"polygons"]];
    }
//    if (state[@"subkey"]) {
//        //TODO: 个性化地图使用的key
//    }
//    if (state[@"layerStyle"]) {
//        //TODO: 个性化地图的style
//    }
    if (state[@"rotate"] &&
        [state[@"rotate"] isKindOfClass:[NSNumber class]]) {
        _mapView.rotation = [state[@"rotate"] floatValue];
    }
    if (state[@"skew"] &&
        [state[@"skew"] isKindOfClass:[NSNumber class]]) {
        _mapView.overlooking = [state[@"skew"] floatValue];
    }
    if (state[@"enable3D"] &&
        [state[@"enable3D"] isKindOfClass:[NSNumber class]]) {
        _mapView.shows3DBuildings = [state[@"enable3D"] boolValue];
    }
    if (state[@"showCompass"] &&
        [state[@"showCompass"] isKindOfClass:[NSNumber class]]) {
        _mapView.showsCompass = [state[@"showCompass"] boolValue];
    }
    if (state[@"showScale"] &&
        [state[@"showScale"] isKindOfClass:[NSNumber class]]) {
        _mapView.showsScale = [state[@"showScale"] boolValue];
    }
    if (state[@"enableOverlooking"] &&
        [state[@"enableOverlooking"] isKindOfClass:[NSNumber class]]) {
        _mapView.overlookingEnabled = [state[@"enableOverlooking"] boolValue];
    }
    if (state[@"enableZoom"] &&
        [state[@"enableZoom"] isKindOfClass:[NSNumber class]]) {
        _mapView.zoomEnabled = [state[@"enableZoom"] boolValue];
    }
    if (state[@"enableScroll"] &&
        [state[@"enableScroll"] isKindOfClass:[NSNumber class]]) {
        _mapView.scrollEnabled = [state[@"enableScroll"] boolValue];
    }
    if (state[@"enableRotate"] &&
        [state[@"enableOverlooking"] isKindOfClass:[NSNumber class]]) {
        _mapView.rotateEnabled = [state[@"enableRotate"] boolValue];
    }
    if (state[@"enableSatellite"] && [state[@"enableSatellite"] boolValue]) {
        _mapView.mapType = QMapTypeSatellite;
    }
    if (state[@"enableTraffic"] && [state[@"enableTraffic"] boolValue]) {
        _mapView.mapType = QMapTypeStandard;
    }
}

- (void)addMarkers:(NSArray *)markers
{
    if (!markers) {
        return;
    }
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary * dict in markers) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            WAMarker *marker = [[WAMarker alloc] initWithDict:dict];
            [array addObject:marker];
        }
    }
    [_mapView removeAnnotations:_markers];
    _markers = [array copy];
    [_mapView addAnnotations:_markers];
}

//- (void)addCovers:(NSArray *)covers
//{
//
//}

- (void)addPolylines:(NSArray *)polylines
{
    if (!polylines) {
        return;
    }
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *dict in polylines) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            WAPolyline *polyline = [[WAPolyline alloc] initWithDict:dict];
            [array addObject:polyline];
        }
    }
    [_mapView removeOverlays:_polylines];
    _polylines = [array copy];
    [_mapView addOverlays:_polylines];
}

- (void)addCircles:(NSArray *)circles
{
    if (!circles) {
        return;
    }
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *dict in circles) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            WACircle *circle = [[WACircle alloc] initWithDict:dict];
            [array addObject:circle];
        }
    }
    [_mapView removeOverlays:_circles];
    _circles = [array copy];
    [_mapView addOverlays:_circles];
}

- (void)addControls:(NSArray *)controls
{
    if (!controls) {
        return;
    }
    for (NSDictionary *dict in controls) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            WAControl *control = [[WAControl alloc] initWithDict:dict];
            WAControlView *view = [[WAControlView alloc] initWithFrame:control.position];
            view.userInteractionEnabled = control.clickable;
            view.identifier = control.identifier;
            @weakify(self)
            view.tapBlock = ^(NSNumber * _Nonnull controlId) {
                @strongify(self)
                if (self.controlTapBlock) {
                    self.controlTapBlock(controlId);
                }
            };
            if (!control.iconPath) {
                continue;
            }
            if (kStringContainString(control.iconPath, @"http")) {
                //网络路径
                [view sd_setImageWithURL:[NSURL URLWithString:control.iconPath]];
            } else {
                //本地路径
                UIImage *image = [UIImage imageWithContentsOfFile:
                                  [PathUtils h5BundlePathForRelativePath:[NSString stringWithFormat:@"preview/%@",control.iconPath]]];
                view.image = image;
            }
            [_mapView addSubview:view];
        }
    }
}

- (void)addPolygons:(NSArray *)polygons
{
    if (!polygons) {
        return;
    }
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *dict in polygons) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            WAPolygon *polygon = [[WAPolygon alloc] initWithDict:dict];
            [array addObject:polygon];
        }
    }
    [_mapView removeOverlays:_polygons];
    _polygons = [array copy];
    [_mapView addOverlays:_polygons];
}

- (void)includePoints:(NSArray *)points padding:(NSArray *)padding
{
    NSUInteger count = points.count;
    CLLocationCoordinate2D coordinates[count];
    NSUInteger index = 0;
    for (NSDictionary *coorDict in points) {
        if (coorDict[@"longitude"] && coorDict[@"latitude"]) {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([coorDict[@"latitude"] floatValue],
                                                                           [coorDict[@"longitude"] floatValue]);
            coordinates[index] = coordinate;
            index ++;
        }
    }
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 0, 0);
    if (padding.count == 4) {
        insets.top = [padding[0] floatValue];
        insets.right = [padding[1] floatValue];
        insets.bottom = [padding[2] floatValue];
        insets.left = [padding[3] floatValue];
    }
    QCoordinateRegion region = QBoundingCoordinateRegionWithCoordinates(coordinates, index);
    [_mapView setRegion:region edgePadding:insets animated:YES];
}

/// 获取当前地图中心的经纬度。返回的是 gcj02 坐标系
/// @param completionHandler 完成回调
- (void)getCenterLocationWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    CLLocationCoordinate2D coodinate = _mapView.centerCoordinate;
    if (completionHandler) {
        completionHandler(YES,
                          @{
                              @"longitude"  : @(coodinate.longitude),
                              @"latitude"   : @(coodinate.latitude)
                          },
                          nil);
    }
}

/// 获取当前地图的视野范围
/// @param completionHandler 完成回调
- (void)getRegionWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    //地图可视范围
    QMapRect mapRect = _mapView.visibleMapRect;
    //转化为坐标
    QMapPoint southWest = QMapPointMake(mapRect.origin.x, mapRect.origin.y + mapRect.size.height);
    QMapPoint northEast = QMapPointMake(mapRect.origin.x + mapRect.size.width, mapRect.origin.y);
    CLLocationCoordinate2D southWestCoordinate = QCoordinateForMapPoint(southWest);
    CLLocationCoordinate2D northEastCoordinate = QCoordinateForMapPoint(northEast);
    if (completionHandler) {
        completionHandler(YES,
                          @{
                              @"southwest": @{
                                      @"longitude"  : @(southWestCoordinate.longitude),
                                      @"latitude"   : @(southWestCoordinate.latitude)
                              },
                              @"northeast": @{
                                      @"longitude"  : @(northEastCoordinate.longitude),
                                      @"latitude"   : @(northEastCoordinate.latitude)
                              }
                          },
                          nil);
    }
}

/// 获取当前地图的旋转角
/// @param completionHandler 完成回调
- (void)getRotateWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    CGFloat rotate = _mapView.rotation;
    if (completionHandler) {
        completionHandler(YES, @{@"rotate": @(rotate)}, nil);
    }
}

/// 获取当前地图的缩放级别
/// @param completionHandler 完成回调
- (void)getScaleWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    CGFloat scale = _mapView.zoomLevel;
    if (completionHandler) {
        completionHandler(YES, @{@"scale": @(scale)}, nil);
    }
}

/// 获取当前地图的倾斜角
/// @param completionHandler 完成回调
- (void)getSkewWithCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    CGFloat skew = _mapView.overlooking;
    if (completionHandler) {
        completionHandler(YES, @{@"skew": @(skew)}, nil);
    }
}

/// 缩放视野展示所有经纬度
/// @param points 要显示在可视区域内的坐标点列表
/// @param padding 坐标点形成的矩形边缘到地图边缘的距离，单位像素。格式为[上,右,下,左]
/// @param completionHandler 完成回调
- (void)includePoints:(NSArray *)points
              padding:(NSArray *)padding
withCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    [self includePoints:points
                padding:padding];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

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
      completionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMarker *marker = nil;
    for (WAMarker *m in _markers) {
        if ([m.identifier isEqualToNumber:markerId]) {
            marker = m;
            break;
        }
    }
    if (!marker) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"moveMarkerAlong"
                                                           code:-1
                                                       userInfo:@{
                                                           NSLocalizedDescriptionKey:
                                                               [NSString stringWithFormat:@"marker with id {%@} not exist", markerId]
                                                       }]);
        }
        return;
    }
    QAnnotationView *annotationView = [_mapView viewForAnnotation:marker];
    NSMutableArray *locations = [NSMutableArray array];
    for (NSDictionary *dict in path) {
        if (dict[@"longitude"] && dict[@"latitude"]) {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([dict[@"latitude"] floatValue],
                                                                           [dict[@"longitude"] floatValue]);
            QMULocation *location = [[QMULocation alloc] init];
            location.coordinate = coordinate;
            [locations addObject:location];
        }
    }
    [QMUAnnotationAnimator translateWithAnnotationView:annotationView
                                             locations:locations
                                              duration:duration
                                         rotateEnabled:autoRotate];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 将地图中心移置当前定位点，此时需设置地图组件 show-location 为true
/// @param location 目标位置
/// @param completionHandler 完成回调
- (void)moveToLocation:(CLLocationCoordinate2D)location
 withCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    [_mapView setCenterCoordinate:location animated:YES];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 设置地图中心点偏移，向后向下为增长，屏幕比例范围(0.25~0.75)，默认偏移为[0.5, 0.5]
/// @param offset 偏移量
/// @param completionHandler 完成回调
- (void)setCenterOffset:(CGPoint)offset
  withCompletionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    [_mapView setCenterOffset:offset animated:YES];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

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
        completionHandler:(WAMapViewContainerCompletionHandler)completionHandler
{
    WAMarker *marker = nil;
    for (WAMarker *m in _markers) {
        if ([m.identifier isEqualToNumber:markerId]) {
            marker = m;
            break;
        }
    }
    if (!marker) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"translateMarker"
                                                           code:-1
                                                       userInfo:@{
                                                           NSLocalizedDescriptionKey:
                                                               [NSString stringWithFormat:@"marker with id {%@} not exist", markerId]
                                                       }]);
        }
        return;
    }
    QAnnotationView *annotationView = [_mapView viewForAnnotation:marker];
    [annotationView moveToDestination:destination
                       withAutoRotate:autoRotate
                               rotate:rotate
                       moveWithRotate:moveWithRotate
                             duration:duration];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}


#pragma mark - ******************************QMapViewDelegate**********************************
/**
*  @brief  地图初始化完成并且配置文件加载完成后会调用此接口
*
*  @param mapView  地图view
*/
- (void)mapViewInitComplete:(QMapView *)mapView
{
    UIView *mapContentView = [mapView.subviews firstObject];
    if ([mapContentView isKindOfClass:NSClassFromString(@"QMapContentView")]) {
        WALOG(@"mapViewGestures:%@",mapContentView.gestureRecognizers);
        for (UIGestureRecognizer *gesture in mapContentView.gestureRecognizers) {
            WALOG(@"gesture :%@",gesture);
            WALOG(@"gesture delegate:%@",gesture.delegate);
        }
    }
    if (self.updateBlock) {
        self.updateBlock();
    }
}

/**
 * @brief  地图区域改变完成后会调用此接口,如果是由手势触发，当触摸结束且地图region改变的动画结束后才会触发此回调
 * @param mapView 地图View
 * @param animated 是否动画
 * @param bGesture region变化是否由手势触发
 */
- (void)mapView:(QMapView *)mapView regionDidChangeAnimated:(BOOL)animated gesture:(BOOL)bGesture
{
    if (self.regionChangeBlock) {
        self.regionChangeBlock();
    }
}

/**
 * @brief  点击地图空白处会调用此接口.
 * @param mapView 地图View
 * @param coordinate 坐标
 */
- (void)mapView:(QMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (self.tapBlock) {
        self.tapBlock(coordinate.longitude, coordinate.latitude);
    }
}

/**
 * @brief  点击地图poi图标处会调用此接口.
 * @param mapView 地图View
 * @param poi poi数据
 */
- (void)mapView:(QMapView *)mapView didTapPoi:(QPoiInfo *)poi
{
    if (self.poiTapBlock) {
        self.poiTapBlock(poi.name, poi.coordinate.longitude, poi.coordinate.latitude);
    }
}

/**
 * @brief 点击地图上的定位标会调用次接口
 * @param mapView 地图View
 * @param location 返回定位标的经纬度
 */
- (void)mapView:(QMapView *)mapView didTapMyLocation:(CLLocationCoordinate2D)location
{
    if (self.anchorPointTapBlock) {
        self.anchorPointTapBlock(location.longitude, location.latitude);
    }
}

/**
 * @brief 根据anntation生成对应的View
 * @param mapView 地图View
 * @param annotation 指定的标注
 * @return 生成的标注View
 */
- (QAnnotationView *)mapView:(QMapView *)mapView viewForAnnotation:(id <QAnnotation>)annotation
{
    static NSString *idenfiter = @"QAnnotationView";
    WAAnnotationView *view = (WAAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:idenfiter];
    WAMarker *marker = (WAMarker *)annotation;
    @weakify(self)
    if (!view) {
        view = [[WAAnnotationView alloc] initWithAnnotation:marker
                                            reuseIdentifier:idenfiter];
        view.labelTapBlock = ^(NSNumber * _Nonnull markerId) {
            @strongify(self)
            if (self.labelTapBlock) {
                self.labelTapBlock(markerId);
            }
        };
        view.calloutTapBlock = ^(NSNumber * _Nonnull markerId) {
            @strongify(self)
            if (self.calloutTapBlock) {
                self.calloutTapBlock(markerId);
            };
        };
    }
    [view configWithMarker:marker];
    return view;
}

/**
 * @brief  当选中一个annotation view时，调用此接口
 * @param mapView 地图View
 * @param view 选中的annotation view
 */
- (void)mapView:(QMapView *)mapView didSelectAnnotationView:(QAnnotationView *)view
{
    if (self.markerTapBlock) {
        WAMarker *marker = view.annotation;
        self.markerTapBlock(marker.identifier);
    }
}


/**
 * @brief  根据overlay生成对应的View
 * @param mapView 地图View
 * @param overlay 指定的overlay
 * @return 生成的覆盖物View
 */
- (QOverlayView *)mapView:(QMapView *)mapView viewForOverlay:(id <QOverlay>)overlay
{
    if ([overlay isKindOfClass:[WAPolyline class]]) {
        return [self createPolyline:overlay];
    } else if ([overlay isKindOfClass:[WAPolygon class]]) {
        return [self createPolygon:overlay];
    } else if ([overlay isKindOfClass:[WACircle class]]) {
        return [self createCircle:overlay];
    }
    return nil;
}

#pragma mark - 生成覆盖物
- (QTexturePolylineView *)createPolyline:(WAPolyline *)polyline
{
    QTexturePolylineView *polylineView = [[QTexturePolylineView alloc] initWithPolyline:polyline];
    polylineView.drawType = QTextureLineDrawType_ColorLine;
    polylineView.strokeColor = polyline.color;
    polylineView.lineWidth = polyline.width;
    polylineView.borderColor = polyline.borderColor;
    polylineView.borderWidth = polyline.borderWidth;
    polylineView.drawSymbol = polyline.arrowLine;
    UIImage *image = [UIImage imageWithContentsOfFile:[PathUtils h5BundlePathForRelativePath:[NSString stringWithFormat:@"preview/%@",polyline.arrowIconPath]]];
    if (image) {
        polylineView.symbolImage = image;
    }
    if (polyline.dottedLine) {
        polylineView.lineDashPattern = @[@10, @10, @10, @10];
    } else {
        polylineView.lineDashPattern = nil;
    }
    if (polyline.colorList) {
        NSMutableArray *colors = [NSMutableArray array];
        for (int i = 0; i < polyline.colorList.count; i ++) {
            UIColor *color = polyline.colorList[i];
            QSegmentColor *segmentColor = [[QSegmentColor alloc] init];
            segmentColor.startIndex = i;
            segmentColor.endIndex = i + 1;
            segmentColor.color = color;
            [colors addObject:segmentColor];
        }
        if (polyline.colorList.count < polyline.pointCount - 1) {
            QSegmentColor *segmentColor = [colors lastObject];
            if (segmentColor) {
                segmentColor.endIndex = (int)polyline.pointCount - 1;
            }
        }
        polylineView.segmentColor = [colors copy];
    }
    return polylineView;
}

- (QPolygonView *)createPolygon:(WAPolygon *)polygon
{
    QPolygonView *polygonView = [[QPolygonView alloc] initWithPolygon:polygon];
    polygonView.lineWidth = polygon.strokeWidth;
    polygonView.strokeColor = polygon.strokeColor;
    polygonView.fillColor = polygon.fillColor;
    polygonView.zIndex = polygon.zIndex;
    return polygonView;
}

- (QCircleView *)createCircle:(WACircle *)circle
{
    QCircleView *circleView = [[QCircleView alloc] initWithCircle:circle];
    circleView.lineWidth = circle.strokeWidth;
    circleView.strokeColor = circle.color;
    circleView.fillColor = circle.fillColor;
    return circleView;
}
@end
