//
//  MunchViewController.m
//  Munch
//
//  Created by Enoch Ng on 2016-05-31.
//  Copyright © 2016 Enoch Ng. All rights reserved.
//

#import "MunchViewController.h"
#import <MapKit/MapKit.h>
#import "YelpClient.h"
#import "Restaurant.h"
#import "AppDelegate.h"
#import "MNCCategory.h"
#import "RestaurantCardFactory.h"

@interface MunchViewController () <CLLocationManagerDelegate>


@property (nonatomic) NSMutableArray *restaurants;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *lastLocation;

@property (nonatomic) float buttonShrinkRatio;

@property (weak, nonatomic) IBOutlet RestaurantCardFactory *restaurantFactory;

@end




@implementation MunchViewController


-(void)viewDidLoad{
    
    self.buttonShrinkRatio = 0.8;

    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    //Taylors stuff//
    self.restaurants = [[NSMutableArray alloc] init];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    
}

#pragma mark - Button Action & Animation -

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    CLLocation *currentLocation = [locations firstObject];
    
    if (self.lastLocation == nil) {
        
        CLGeocoder *coder = [[CLGeocoder alloc] init];
        
        [coder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            //get current coordinates. eventually in seperate function to change search results based on filter
            CLPlacemark *place = [placemarks firstObject];

            NSMutableSet *testCategories = [[NSMutableSet alloc] init];
            [testCategories addObject:@"mexican"];
            [testCategories addObject:@"vegetarian"];
            [testCategories addObject:@"vegan"];
            
            NSDictionary *paramDictionary = [self getParamDictionaryWithPlace:place includeFilterCategories:YES withCategoryList:testCategories];
            
            YelpClient *client = [YelpClient new];
            
            //get the data!
            [client getPath:@"search" parameters:paramDictionary
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        NSDictionary *objects = responseObject[@"businesses"];
                        for (NSDictionary *restaurant in objects) {
                            
                            //create restaurant objects
                            Restaurant *res = [[Restaurant alloc] initWithEntity:[NSEntityDescription entityForName:@"Restaurant" inManagedObjectContext:self.managedObjectContext] insertIntoManagedObjectContext:self.managedObjectContext andDictionary:restaurant] ;
                            
                            [self.restaurants addObject:res];
                            
                            NSLog(@"----------------------");
                            NSLog(@"%@", res.name);
                            for (MNCCategory *cat in res.categories) {
                                NSLog(@"%@", cat.name);
                            }
                            
                            
                        }
                        [self.restaurantFactory loadRestaurantCardsWithData:self.restaurants];
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"Restaurants didn't load! :(");
                    }];
        }];
    }
    
    self.lastLocation = currentLocation;
    
}

-(NSDictionary *) getParamDictionaryWithPlace:(CLPlacemark *)place includeFilterCategories:(BOOL)state withCategoryList:(NSSet *)categories {
    
    //Get Current Lat & Long//
    NSString *lat = [NSString stringWithFormat:@"%f",place.location.coordinate.latitude];
    NSString *lon = [NSString stringWithFormat:@"%f",place.location.coordinate.longitude];
    NSString *coord = [NSString stringWithFormat:@"%@,%@", lat, lon ];
    
    //Set up basic parameters
    NSMutableDictionary *paramDictionary = [[NSMutableDictionary alloc] init];
    paramDictionary[@"term"] = @"food,restaurant";
    paramDictionary[@"ll"] = coord;
    
    //If the filter includes categories to search for
    if (state) {
        NSArray *catArray = [categories allObjects];
        NSString *catString = [catArray componentsJoinedByString:@","];
        paramDictionary[@"category_filter"] = catString;
    }
    
    return paramDictionary;
}



@end
