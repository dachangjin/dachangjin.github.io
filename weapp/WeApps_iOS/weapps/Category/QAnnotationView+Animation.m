//
//  QAnnotationView+Animation.m
//  weapps
//
//  Created by tommywwang on 2020/10/16.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "QAnnotationView+Animation.h"

double gNormalizeDegree(double degree)
{
    double val = fmod(degree, 360.0);
    
    if (val < 0)
    {
        val = val + 360.0;
    }

    return val;
}

@implementation QAnnotationView (Animation)



- (void)moveToDestination:(CLLocationCoordinate2D)destination
           withAutoRotate:(BOOL)autoRotate
                   rotate:(CGFloat)rotate
           moveWithRotate:(BOOL)moveWithRotate
                 duration:(NSTimeInterval)animationDuration
{
    QAnnotationViewLayer *animationLayer = (QAnnotationViewLayer *)self.layer;
    
    CLLocationCoordinate2D fromCoordinate = [self.annotation coordinate];
    CLLocationCoordinate2D toCoordinate = destination;
    
    #define COORDINATE_KEY @"coordinate"

    {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:COORDINATE_KEY];
        
        animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(fromCoordinate.latitude, fromCoordinate.longitude)];
        animation.toValue   = [NSValue valueWithCGPoint:CGPointMake(toCoordinate.latitude,    toCoordinate.longitude)];
        
        animation.duration  = animationDuration;
        
        [animationLayer addAnimation:animation forKey:COORDINATE_KEY];
    }
    
    CGFloat fromRotation_degree = [(NSNumber *)[self.layer.presentationLayer valueForKeyPath:@"transform.rotation.z"] floatValue] * 180 / M_PI;
    fromRotation_degree = gNormalizeDegree(fromRotation_degree);
    CGFloat fromRotation_radian = fromRotation_degree *  M_PI / 180;
    
    CGFloat toRotation_degree = [self findCloseDestinationDegree:fromRotation_degree toDegree:gNormalizeDegree(rotate)];
    CGFloat toRotation_radian   = toRotation_degree * M_PI / 180;
    
#define ROTATION_KEY @"transform.rotation.z"
    
    {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:ROTATION_KEY];
        
        animation.fromValue = @(fromRotation_radian);
        animation.toValue   = @(toRotation_radian);
        
        animation.duration  = animationDuration;
        
        [animationLayer addAnimation:animation forKey:ROTATION_KEY];
        
        animationLayer.affineTransform = CGAffineTransformMakeRotation(toRotation_radian);
    }
}


- (double)findCloseDestinationDegree:(double)fromDegree toDegree:(double)toDegree
{
    if (fabs(toDegree - fromDegree) > 180.0)
    {
        if (toDegree > fromDegree)
        {
            toDegree -= 360.0;
        }
        else
        {
            toDegree += 360.0;
        }
    }
    
    return toDegree;
}
@end
