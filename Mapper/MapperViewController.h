//
//  MapperViewController.h
//  Mapper
//
//  Created by Dan Kang on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapperViewController : UIViewController 
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (void)startUpdating;
- (void)stopUpdating;
@end
