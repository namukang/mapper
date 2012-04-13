//
//  MapperViewController.m
//  Mapper
//
//  Created by Dan Kang on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "MapperViewController.h"
#import "AFJSONRequestOperation.h"

@interface MapperViewController ()
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation MapperViewController
@synthesize mapView = _mapView;

@synthesize locationManager = _locationManager;

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}

- (void)fetchPartnerLocation {
    // FIXME: Fetch partner's location
    NSURL *url = [NSURL URLWithString:@"http://graph.facebook.com/dk"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"Name: %@ %@", [JSON valueForKeyPath:@"first_name"], [JSON valueForKeyPath:@"last_name"]);
    } failure:nil];
    
    [operation start];
}

// Start receiving standard updates for location
- (void)startStandardUpdates
{
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // Set a movement threshold for new events.
    self.locationManager.distanceFilter = 5;
    
    [self.locationManager startUpdatingLocation];
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
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
              newLocation.coordinate.latitude,
              newLocation.coordinate.longitude);
        // TODO: Push location to server
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self fetchPartnerLocation];
    [self startStandardUpdates];
}

- (void)viewDidUnload
{
    [self setMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
