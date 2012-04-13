//
//  MapperViewController.m
//  Mapper
//
//  Created by Dan Kang on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MapperViewController.h"
#import "ContactAnnotation.h"
#import "LocationTracker.h"

@interface MapperViewController ()
@property (nonatomic, strong) ContactAnnotation *partnerAnnotation;
@property (nonatomic, strong) LocationTracker *locationTracker;
@property (nonatomic, strong) NSTimer *partnerMapUpdateTimer;
@end

@implementation MapperViewController
@synthesize mapView = _mapView;
@synthesize partnerAnnotation = _partnerAnnotation;
@synthesize locationTracker = _locationTracker;
@synthesize partnerMapUpdateTimer = _partnerMapUpdateTimer;

- (ContactAnnotation *)partnerAnnotation {
    if (!_partnerAnnotation) {
        _partnerAnnotation = [[ContactAnnotation alloc] init];
        // Put pin on map
        [self.mapView addAnnotation:_partnerAnnotation];
    }
    return _partnerAnnotation;
}

- (LocationTracker *)locationTracker {
    if (!_locationTracker) {
        _locationTracker = [[LocationTracker alloc] init];
    }
    return _locationTracker;
}

- (IBAction)identityChanged:(UISegmentedControl *)sender {
    self.locationTracker.user = sender.selectedSegmentIndex;
    [self.locationTracker sendLocationToServer];
}

// Zoom region to fit both self and partner
-(IBAction)centerPinsOnMap {
    CLLocation *currentLocation = self.locationTracker.currentLocation;
    CLLocationCoordinate2D southWest;
    CLLocationCoordinate2D northEast;
    
    southWest.latitude = MIN(currentLocation.coordinate.latitude, self.partnerAnnotation.coordinate.latitude);
    southWest.longitude = MIN(currentLocation.coordinate.longitude, self.partnerAnnotation.coordinate.longitude);
    
    northEast.latitude = MAX(currentLocation.coordinate.latitude, self.partnerAnnotation.coordinate.latitude);
    northEast.longitude = MAX(currentLocation.coordinate.longitude, self.partnerAnnotation.coordinate.longitude);
    
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

- (void)updatePartnerLocationOnMap {
    // Show partner's location on map
    self.partnerAnnotation.coordinate = self.locationTracker.partnerLocation.coordinate;
    NSLog(@"partner: latitude %+.6f, longitude %+.6f\n",
          self.partnerAnnotation.coordinate.latitude,
          self.partnerAnnotation.coordinate.longitude);
}

- (void)startPartnerUpdatesOnMap {
    self.partnerMapUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updatePartnerLocationOnMap) userInfo:nil repeats:YES]; 
}

- (void)stopPartnerUpdatesOnMap {
    [self.partnerMapUpdateTimer invalidate];
}

- (void)startUpdating {
    NSLog(@"Start updating.");
    [self.locationTracker startSelfUpdates];
    [self.locationTracker startPartnerUpdates];
    [self startPartnerUpdatesOnMap];
}

- (void)stopUpdating {
    NSLog(@"Stop updating.");
    // [self.locationTracker stopSelfUpdates];
    [self.locationTracker stopPartnerUpdates];
    [self stopPartnerUpdatesOnMap];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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
