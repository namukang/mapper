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
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic) NSInteger user; // FIXME
@end

@implementation MapperViewController
@synthesize mapView = _mapView;
@synthesize locationManager = _locationManager;
@synthesize partnerAnnotation = _partnerAnnotation;
@synthesize currentLocation = _currentLocation;
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
            CLLocationDegrees latitude = [(NSNumber *)[JSON valueForKeyPath:@"latitude"] doubleValue];
            CLLocationDegrees longitude = [(NSNumber *)[JSON valueForKeyPath:@"longitude"] doubleValue];
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
        self.currentLocation = newLocation;
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
              newLocation.coordinate.latitude,
              newLocation.coordinate.longitude);
        NSNumber *latitude = [NSNumber numberWithDouble:newLocation.coordinate.latitude];
        NSNumber *longitude = [NSNumber numberWithDouble:newLocation.coordinate.longitude];
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
}

- (IBAction)identityChanged:(UISegmentedControl *)sender {
    self.user = sender.selectedSegmentIndex;
}

// Zoom region to fit both self and partner
-(IBAction)zoomIn {
    CLLocationCoordinate2D southWest;
    CLLocationCoordinate2D northEast;
    
    southWest.latitude = MIN(self.currentLocation.coordinate.latitude, self.partnerAnnotation.coordinate.latitude);
    southWest.longitude = MIN(self.currentLocation.coordinate.longitude, self.partnerAnnotation.coordinate.longitude);
    
    northEast.latitude = MAX(self.currentLocation.coordinate.latitude, self.partnerAnnotation.coordinate.latitude);
    northEast.longitude = MAX(self.currentLocation.coordinate.longitude, self.partnerAnnotation.coordinate.longitude);
    
    CLLocation *locSouthWest = [[CLLocation alloc] initWithLatitude:southWest.latitude longitude:southWest.longitude];
    CLLocation *locNorthEast = [[CLLocation alloc] initWithLatitude:northEast.latitude longitude:northEast.longitude];
    
    // This is a diag distance (if you wanted tighter you could do NE-NW or NE-SE)
    CLLocationDistance meters = [locSouthWest distanceFromLocation:locNorthEast];
    
    MKCoordinateRegion region;
    region.center.latitude = (southWest.latitude + northEast.latitude) / 2.0;
    region.center.longitude = (southWest.longitude + northEast.longitude) / 2.0;
    region.span.latitudeDelta = meters / 111319.5;
    region.span.longitudeDelta = 0.0;
    
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:region];
    [self.mapView setRegion:adjustedRegion animated:YES];
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
