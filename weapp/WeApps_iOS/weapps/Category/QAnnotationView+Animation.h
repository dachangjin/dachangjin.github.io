//
//  QAnnotationView+Animation.h
//  weapps
//
//  Created by tommywwang on 2020/10/16.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <QMapKit/QMapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QAnnotationView (Animation)

- (void)moveToDestination:(CLLocationCoordinate2D)destination
           withAutoRotate:(BOOL)autoRotate
                   rotate:(CGFloat)rotate
           moveWithRotate:(BOOL)moveWithRotate
                 duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
