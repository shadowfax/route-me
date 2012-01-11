//
//  RMUserLocationMarker.h
//  MapView
//
//  Created by Juan Pedro Gonzalez Gutierrez on 15/12/11.
//  Copyright (c) 2011 JPG-Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMMapContents.h"
#import "RMMapLayer.h"
#import "RMFoundation.h"

@interface RMUserLocationMarker : RMMapLayer <RMMovingMapLayer> {
    // RMMapLayer
    RMProjectedPoint projectedLocation;
    BOOL enableDragging;
	BOOL enableRotation;
    
    // RMMapContents Reference
    RMMapContents *mapContents;
}

// RMMapLayer
@property (assign, nonatomic) RMProjectedPoint projectedLocation;
@property (assign) BOOL enableDragging;
@property (assign) BOOL enableRotation;

@property (nonatomic, retain) RMMapContents *mapContents;

- (id)initWithContents:(RMMapContents *)aContents;

- (void)removeFromMap;

- (void)updatePosition:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;

@end
