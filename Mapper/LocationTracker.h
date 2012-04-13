//
//  LocationTracker.h
//  Mapper
//
//  Created by Dan Kang on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface LocationTracker : NSObject <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocation *partnerLocation;
@property (nonatomic) NSInteger user; // FIXME

- (void)sendLocationToServer;

- (void)startSelfUpdates;
- (void)stopSelfUpdates;

- (void)startPartnerUpdates;
- (void)stopPartnerUpdates;
@end
