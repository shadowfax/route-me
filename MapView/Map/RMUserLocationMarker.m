//
//  RMUserLocationMarker.m
//  MapView
//
//  Created by Juan Pedro Gonzalez Gutierrez on 15/12/11.
//  Copyright (c) 2011 JPG-Consulting. All rights reserved.
//

#import "RMUserLocationMarker.h"
#import <QuartzCore/QuartzCore.h>

#import "RMProjection.h"
#import "RMMercatorToScreenProjection.h"
#import "RMPixel.h"     // RMScaleCGPointAboutPoint
#import "RMLayerCollection.h"



@interface RMUserLocationMarker () {
@private
    CALayer *bulbLayer;
    CAShapeLayer *accuracyLayer;
    CAShapeLayer *blinkLayer;
    
    CLLocationCoordinate2D userLocation;
    CLLocationAccuracy horizontalAccuracy;
    CGFloat minimumRadiusInPixels;
}

- (void)updateAccuracyLayer;
- (void)updateBlink;

@end






@implementation RMUserLocationMarker

@synthesize projectedLocation;
@synthesize enableDragging;
@synthesize enableRotation;
@synthesize mapContents;

- (id)init
{
    self = [super init];
    if (self) {
        enableDragging = YES;
        enableRotation = YES;
        [self setMasksToBounds:NO];
        
        // Accuracy Layer
        accuracyLayer = [CAShapeLayer layer];
        [accuracyLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
        accuracyLayer.strokeColor = [[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.7] CGColor];
        accuracyLayer.fillColor = [[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.05]  CGColor];
        accuracyLayer.lineWidth = 0.6;
        
        // Animation for Accuracy layer
        CABasicAnimation *theAnimationForScalling2;
        theAnimationForScalling2=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
        theAnimationForScalling2.duration = 1;
        theAnimationForScalling2.repeatCount= 1;
        theAnimationForScalling2.removedOnCompletion = YES;
        theAnimationForScalling2.toValue=[NSNumber numberWithFloat:0.5];
        theAnimationForScalling2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [accuracyLayer addAnimation:theAnimationForScalling2 forKey:@"transform"];
        
        // Blink layer
        blinkLayer = [CAShapeLayer layer];
        [blinkLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
        blinkLayer.strokeColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] CGColor];
        blinkLayer.fillColor = [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]  CGColor];
        blinkLayer.lineWidth = 4.0;
        blinkLayer.opacity = 0.0; // Important! ...or it bounces back to view when annimation ends.
        
        // Add animation for the blink layer
        CABasicAnimation *theAnimationForScalling;
        theAnimationForScalling=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
        theAnimationForScalling.duration = 2.5;
        theAnimationForScalling.repeatCount = 1;
        theAnimationForScalling.removedOnCompletion = YES;
        theAnimationForScalling.fromValue=[NSNumber numberWithBool:NO];
        theAnimationForScalling.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [blinkLayer addAnimation:theAnimationForScalling forKey:@"transform.scale"];
        
        CABasicAnimation *theAnimationForOpaque;
        theAnimationForOpaque=[CABasicAnimation animationWithKeyPath:@"opacity"];
        theAnimationForOpaque.duration = 2.5;
        theAnimationForOpaque.repeatCount= 1;
        theAnimationForOpaque.removedOnCompletion = YES;
        theAnimationForOpaque.fromValue=[NSNumber numberWithFloat:1];
        theAnimationForOpaque.toValue = [NSNumber numberWithFloat:0];
        theAnimationForOpaque.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        [blinkLayer addAnimation:theAnimationForOpaque forKey:@"opacityanim"];
        
        // Add Layers
        [self addSublayer:accuracyLayer];
        [self addSublayer:blinkLayer];
        
        // Bulb
        bulbLayer = [[CALayer alloc] init];
        UIImage* img = [[UIImage imageNamed:@"location_center.png"] retain];
        if (img == nil) {
            minimumRadiusInPixels = 44.0;
        } else {
            minimumRadiusInPixels = ([img size].width * 2.0) + 1.0;
            if (minimumRadiusInPixels < 44.0) {
                minimumRadiusInPixels = 44.0;
            }
        }
        bulbLayer.contents = (id)[img CGImage];
        self.bounds = CGRectMake(0,0,(int)img.size.width, (int)img.size.height);
        [bulbLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
        [bulbLayer setBounds:CGRectMake(-1 * img.size.width * bulbLayer.anchorPoint.x, -1 * img.size.height * bulbLayer.anchorPoint.y, (int)img.size.width, (int)img.size.height)];
        self.bounds = bulbLayer.bounds;
        [self addSublayer:bulbLayer];
        [self setAnchorPoint:CGPointMake(0.5, 0.5)];
    }
    return self;
}

- (id)initWithContents:(RMMapContents *)aContents
{
    self = [self init];
    if (self) {
        mapContents = aContents;
        
        //self.delegate = self;
        [[mapContents overlay] addSublayer:self];
    }
    return self;
}

-(void)secondStepRingTransition
{
    CABasicAnimation *theAnimationForScalling3;
    theAnimationForScalling3=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    theAnimationForScalling3.duration = 0.5;
    theAnimationForScalling3.repeatCount= 1;
    theAnimationForScalling3.removedOnCompletion = YES;
    theAnimationForScalling3.fromValue=[NSNumber numberWithFloat:0.5];
    
    theAnimationForScalling3.toValue=[NSNumber numberWithFloat:0];
    theAnimationForScalling3.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [accuracyLayer addAnimation:theAnimationForScalling3 forKey:@"transform2"];
}

- (void)removeFromMap
{
    [super removeFromSuperlayer];
    //[[contents overlay] removeSublayer:self];
    //[[_contents overlay] removeSublayer:_bulb];
}

- (void)updateBlink
{
    // Add animation for the blink layer
    CABasicAnimation *theAnimationForScalling;
    theAnimationForScalling=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    theAnimationForScalling.duration = 2.5;
    theAnimationForScalling.repeatCount = 1;
    theAnimationForScalling.removedOnCompletion = YES;
    theAnimationForScalling.fromValue=[NSNumber numberWithBool:NO];
    theAnimationForScalling.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [blinkLayer addAnimation:theAnimationForScalling forKey:@"transform.scale"];
    
    CABasicAnimation *theAnimationForOpaque;
    theAnimationForOpaque=[CABasicAnimation animationWithKeyPath:@"opacity"];
    theAnimationForOpaque.duration = 2.5;
    theAnimationForOpaque.repeatCount= 1;
    theAnimationForOpaque.removedOnCompletion = YES;
    theAnimationForOpaque.fromValue=[NSNumber numberWithFloat:1];
    theAnimationForOpaque.toValue = [NSNumber numberWithFloat:0];
    theAnimationForOpaque.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [blinkLayer addAnimation:theAnimationForOpaque forKey:@"opacityanim"];
    
    // --
    CGMutablePathRef path = CGPathCreateMutable();
    
    // Circle
    CGFloat radius = self->horizontalAccuracy / [mapContents metersPerPixel];
    
    // Set a minimum radius. If the precision is high we don't know if it is updating
    radius = radius - 1.0;
    if (radius < minimumRadiusInPixels) {
        radius = minimumRadiusInPixels;
    }
    
    float ix = -radius + self.frame.size.width  / 2;
    float iy = -radius + self.frame.size.height / 2;
    
    [blinkLayer setBounds:CGRectMake(ix, iy, radius*2, radius*2)];
    [blinkLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
    
    CGRect ellipseRect = CGRectMake(ix, iy, radius * 2 , radius * 2 );
    CGPathAddEllipseInRect(path, NULL, ellipseRect);
    
    // draw circle
    blinkLayer.path = path;
    CGPathRelease(path);
}

- (void)updatePosition:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // Save some values
    userLocation = newLocation.coordinate;
    if (self->horizontalAccuracy != newLocation.horizontalAccuracy) {
        self->horizontalAccuracy = newLocation.horizontalAccuracy;
        // Blink to tell the user an update has occurred
        [self updateBlink];
        
        // Animation for Accuracy layer
        CABasicAnimation *theAnimationForScalling2;
        theAnimationForScalling2=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
        theAnimationForScalling2.duration = 1;
        theAnimationForScalling2.repeatCount= 1;
        theAnimationForScalling2.removedOnCompletion = YES;
        theAnimationForScalling2.toValue=[NSNumber numberWithFloat:0.5];
        theAnimationForScalling2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [accuracyLayer addAnimation:theAnimationForScalling2 forKey:@"transform"];

        // We separate this method since it is needed on zoom
        [self updateAccuracyLayer];
    } else {
        // Blink to tell the user an update has occurred
        [self updateBlink];
    }
    

    
    
    // Set the new projection
    [self setProjectedLocation:[[mapContents projection] latLongToPoint:newLocation.coordinate]];
    
    // ToDo: map must not move or if moved the animation shall be canceller
    // --- Animation Start ---
    CGPoint current_point = [self position];
    CGPoint end_point = [[mapContents mercatorToScreenProjection] projectXYPoint:projectedLocation];
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    [anim setFromValue:[NSValue valueWithCGPoint:current_point]];
    [anim setToValue:[NSValue valueWithCGPoint:end_point]];
    [anim setDelegate:self];
    [anim setDuration:0.5];
    
    [anim setRemovedOnCompletion:YES];
    
    [self setPosition:end_point];
    [self addAnimation:anim forKey:@"position"];
    // --- Animation End ---
    
    // Make sure the point is set correctly
    [self setPosition:[[mapContents mercatorToScreenProjection] projectXYPoint:projectedLocation]];
    
    
    
    
    //[self setNeedsDisplay];
    [self setNeedsLayout];
}

- (void)updateAccuracyLayer
{
    // --- Circle ---
    CGMutablePathRef path = CGPathCreateMutable();
    
    // Circle
    CGFloat radius = self->horizontalAccuracy / [mapContents metersPerPixel];
    float ix = -radius + self.frame.size.width  / 2;
    float iy = -radius + self.frame.size.height / 2;
    
    [accuracyLayer setBounds:CGRectMake(ix, iy, radius*2, radius*2)];
    [accuracyLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
    
    CGRect ellipseRect = CGRectMake(ix, iy, radius * 2 , radius * 2 );
    CGPathAddEllipseInRect(path, NULL, ellipseRect);
    
    // draw circle
    accuracyLayer.path = path;
    CGPathRelease(path);
}

- (void)setMapContents:(RMMapContents *)aContents
{
    [self removeFromMap];
    
    self.mapContents = aContents;
    
    // Set the new projection
    [self setProjectedLocation:[[mapContents projection] latLongToPoint:userLocation]];
    [self setPosition:[[mapContents mercatorToScreenProjection] projectXYPoint:projectedLocation]];
    
    // Add to map
    [[mapContents overlay] addSublayer:self];
}

- (void)dealloc
{
    [self removeAllAnimations];
    [bulbLayer release];
    [blinkLayer release];
    [accuracyLayer release];
    mapContents = nil;
    [super dealloc];
}

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)center
{
    [self removeAllAnimations];
    
    if (enableDragging) {
        self.position = RMScaleCGPointAboutPoint(self.position, zoomFactor, center);
    }
    
    [self updateAccuracyLayer];
}

- (void)moveBy:(CGSize)delta
{
    [self removeAllAnimations];
    
    if (enableDragging) {
        [super moveBy:delta];
        //self.position = RMTranslateCGPointBy(self.position, delta);
    }
}


@end
