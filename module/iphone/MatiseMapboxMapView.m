/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2016 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUtils.h"
#import "MatiseMapboxMapView.h"

@interface MatiseMapboxMapView () <MGLMapViewDelegate>
@end

@implementation MatiseMapboxMapView

-(void)dealloc
{
    RELEASE_TO_NIL(mapView);
    [super dealloc];
}

-(void)configurationSet
{
    // Initialize with or without style
    if([self proxyValueForKey:@"styleUrl"]) {
        NSString *styleUrl = [self proxyValueForKey:@"styleUrl"];
        
        ENSURE_STRING(styleUrl);
        
        mapView = [[MGLMapView alloc] initWithFrame:self.frame styleURL:[NSURL URLWithString:styleUrl]];
    }
    else {
        mapView = [[MGLMapView alloc] initWithFrame:self.frame];
    }
    
    // Set lat/lng and zoom
    if([self proxyValueForKey:@"lat"] && [self proxyValueForKey:@"lng"]) {
        double lat = [TiUtils  doubleValue:[self proxyValueForKey:@"lat"]];
        double lng = [TiUtils  doubleValue:[self proxyValueForKey:@"lng"]];
        double zoom = 12;
        
        if([self proxyValueForKey:@"zoom"]) {
            zoom = [TiUtils  doubleValue:[self proxyValueForKey:@"zoom"]];
        }
        
        
        // set the map's center coordinates and zoom level
        [mapView setCenterCoordinate:CLLocationCoordinate2DMake(lat, lng)
                       zoomLevel:zoom
                        animated:NO];
    }
    
    
    mapView.delegate = self;
    mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self addSubview:mapView];
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    if (mapView != nil)
    {
        [TiUtils setView:mapView positionRect:bounds];
    }
    
    [super frameSizeChanged:frame bounds:bounds];
}

#pragma mark Custom functions
-(void)addAnnotation:(id)args
{
    MatiseMapboxPointAnnotationProxy *annotation = [args objectAtIndex:0];
    
    [mapView addAnnotation:annotation.marker];
}

-(void)removeAnnotation:(id)args
{
    MatiseMapboxPointAnnotationProxy *annotation = [args objectAtIndex:0];
    
    [mapView removeAnnotation:annotation.marker];
}

- (void)drawPolyline:(id)jsonPath
{
    ENSURE_SINGLE_ARG(jsonPath, NSString);
    
   // Load and serialize the GeoJSON into a dictionary filled with properly-typed objects
   NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[jsonPath dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
   
   // Load the `features` dictionary for iteration
   for (NSDictionary *feature in jsonDict[@"features"])
   {
       // Our GeoJSON only has one feature: a line string
       if ([feature[@"geometry"][@"type"] isEqualToString:@"LineString"])
       {
           // Get the raw array of coordinates for our line
           NSArray *rawCoordinates = feature[@"geometry"][@"coordinates"];
           NSUInteger coordinatesCount = rawCoordinates.count;
           
           // Create a coordinates array, sized to fit all of the coordinates in the line.
           // This array will hold the properly formatted coordinates for our MGLPolyline.
           CLLocationCoordinate2D coordinates[coordinatesCount];
           
           // Iterate over `rawCoordinates` once for each coordinate on the line
           for (NSUInteger index = 0; index < coordinatesCount; index++)
           {
               // Get the individual coordinate for this index
               NSArray *point = [rawCoordinates objectAtIndex:index];
               
               // GeoJSON is "longitude, latitude" order, but we need the opposite
               CLLocationDegrees lat = [[point objectAtIndex:1] doubleValue];
               CLLocationDegrees lng = [[point objectAtIndex:0] doubleValue];
               CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lng);
               
               // Add this formatted coordinate to the final coordinates array at the same index
               coordinates[index] = coordinate;
           }
           
           // Create our polyline with the formatted coordinates array
           MGLPolyline *polyline = [MGLPolyline polylineWithCoordinates:coordinates count:coordinatesCount];
           
           // Optionally set the title of the polyline, which can be used for:
           //  - Callout view
           //  - Object identification
           // In this case, set it to the name included in the GeoJSON
           polyline.title = feature[@"properties"][@"name"]; // "Crema to Council Crest"
           
           // Add the polyline to the map, back on the main thread
           TiThreadPerformOnMainThread(^{
               [mapView addAnnotation:polyline];
           }, NO);
       }
   }
}

#pragma mark Delegate functions
- (CGFloat)mapView:(MGLMapView *)mapView alphaForShapeAnnotation:(MGLShape *)annotation
{
    // Set the alpha for all shape annotations to 1 (full opacity)
    return 1.0f;
}

- (CGFloat)mapView:(MGLMapView *)mapView lineWidthForPolylineAnnotation:(MGLPolyline *)annotation
{
    // Set the line width for polyline annotations
    return 2.0f;
}

- (UIColor *)mapView:(MGLMapView *)mapView strokeColorForShapeAnnotation:(MGLShape *)annotation
{
    return [UIColor redColor];
}

- (BOOL)mapView:(MGLMapView *)mapView annotationCanShowCallout:(id<MGLAnnotation>)annotation
{
    return true;
}

- (UIView *)mapView:(MGLMapView *)mapView leftCalloutAccessoryViewForAnnotation:(id<MGLAnnotation>)annotation
{
    if ([annotation.title isEqualToString:@"Kinkaku-ji"])
    {
        // callout height is fixed; width expands to fit
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60.f, 50.f)];
        label.textAlignment = NSTextAlignmentRight;
        label.textColor = [UIColor colorWithRed:0.81f green:0.71f blue:0.23f alpha:1.f];
        label.text = @"金閣寺";
        
        return label;
    }
    
    return nil;
}

- (UIView *)mapView:(MGLMapView *)mapView rightCalloutAccessoryViewForAnnotation:(id<MGLAnnotation>)annotation
{
    return [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
}

- (void)mapView:(MGLMapView *)mapView annotation:(id<MGLAnnotation>)annotation calloutAccessoryControlTapped:(UIControl *)control
{
    // hide the callout view
    [mapView deselectAnnotation:annotation animated:NO];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:annotation.title
                                                    message:@"A lovely (if touristy) place."
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
}


@end
