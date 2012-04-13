//
//  LocationTracker.m
//  Mapper
//
//  Created by Dan Kang on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LocationTracker.h"
#import "AFJSONRequestOperation.h"

@interface LocationTracker()
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSTimer *partnerUpdateTimer;
@end

@implementation LocationTracker
@synthesize currentLocation = _currentLocation;
@synthesize partnerLocation = _partnerLocation;
@synthesize locationManager = _locationManager;
@synthesize partnerUpdateTimer = _partnerUpdateTimer;
@synthesize user = _user; // FIXME

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}

// Start receiving standard updates for location
- (void)startSelfUpdates
{
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // Set a movement threshold for new events.
    self.locationManager.distanceFilter = 1;
    
    [self.locationManager startUpdatingLocation];
}

// Stop receiving standard updates for location
- (void)stopSelfUpdates {
    [self.locationManager stopUpdatingLocation];
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    // Only use update if it's from the last 15 seconds
    if (abs(howRecent) < 15.0)
    {
        self.currentLocation = newLocation;
        NSLog(@"self: latitude %+.6f, longitude %+.6f\n",
              newLocation.coordinate.latitude,
              newLocation.coordinate.longitude);
        [self sendLocationToServer];
    }
}

// Send self location to server
- (void)sendLocationToServer {
    NSNumber *latitude = [NSNumber numberWithDouble:self.currentLocation.coordinate.latitude];
    NSNumber *longitude = [NSNumber numberWithDouble:self.currentLocation.coordinate.longitude];
    // Convert data to JSON
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:latitude, @"latitude", longitude, @"longitude", nil];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];        
    // Form POST request
    NSString *partnerUrl;
    if (self.user == 0) {
        partnerUrl = @"http://mapper-app.herokuapp.com/user/0";
    } else {
        partnerUrl = @"http://mapper-app.herokuapp.com/user/1";
    }
    NSURL *url = [NSURL URLWithString:partnerUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [mutableRequest setHTTPMethod:@"POST"];
    [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [mutableRequest setHTTPBody:data];
    // Push location to server
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:mutableRequest success:nil failure:nil];
    [operation start];
}

// Fetch partner location every 3 seconds
- (void)startPartnerUpdates {
    self.partnerUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(fetchPartnerLocation) userInfo:nil repeats:YES];
}

// Stop fetching partner location
- (void)stopPartnerUpdates {
    [self.partnerUpdateTimer invalidate];
}

// Fetch partner location from server
- (void)fetchPartnerLocation {
    // Fetch partner's location
    NSString *partnerUrl;
    if (self.user == 0) {
        partnerUrl = @"http://mapper-app.herokuapp.com/user/1";
    } else {
        partnerUrl = @"http://mapper-app.herokuapp.com/user/0";
    }
    NSURL *url = [NSURL URLWithString:partnerUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        id error = [JSON valueForKeyPath:@"error"];
        if (error) {
            NSLog(@"%@", error);
        } else {
            CLLocationDegrees latitude = [(NSNumber *)[JSON valueForKeyPath:@"latitude"] doubleValue];
            CLLocationDegrees longitude = [(NSNumber *)[JSON valueForKeyPath:@"longitude"] doubleValue];
            self.partnerLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        }
    } failure:nil];
    [operation start];
}

@end
