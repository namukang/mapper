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
#import "ContactAnnotation.h"

@interface MapperViewController ()
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) ContactAnnotation *partnerAnnotation;
@property (nonatomic) NSInteger user; // FIXME
@end

@implementation MapperViewController
@synthesize mapView = _mapView;
@synthesize locationManager = _locationManager;
@synthesize partnerAnnotation = _partnerAnnotation;
@synthesize user = _user; // FIXME

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}

- (ContactAnnotation *)partnerAnnotation {
    if (!_partnerAnnotation) {
        _partnerAnnotation = [[ContactAnnotation alloc] init];
        // Put pin on map
        [self.mapView addAnnotation:_partnerAnnotation];
    }
    return _partnerAnnotation;
}

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
            CLLocationDegrees latitude = (int)[JSON valueForKeyPath:@"latitude"];
            NSLog(@"%f", latitude);
            CLLocationDegrees longitude = (int)[JSON valueForKeyPath:@"longitude"];
            CLLocation *loc = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
            // Show partner's location on map
            self.partnerAnnotation.coordinate = loc.coordinate;   
        }
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

- (IBAction)identityChanged:(UISegmentedControl *)sender {
    self.user = sender.selectedSegmentIndex;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self startStandardUpdates];
    // Fetch partner location every 3 seconds
    [NSTimer scheduledTimerWithTimeInterval:3 target:self
                                   selector:@selector(fetchPartnerLocation) userInfo:nil repeats:YES];
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
