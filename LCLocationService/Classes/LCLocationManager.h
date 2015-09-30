//
//  LocationManager.h
//  UICatalog
//
//  Created by Leo on 11/8/14.
//  Copyright (c) 2014 Perfectidea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import <UIKit/UIKit.h>

typedef void (^GeocodeBlock) (CLLocation *location, BOOL success);

@interface LCLocationManager : NSObject <CLLocationManagerDelegate>

/*
 此裝置的Location
 */
@property (strong, nonatomic) CLLocationManager *locmanager;
@property (strong, nonatomic) NSString *currentAddress;
@property (strong, nonatomic) NSString *currentLevel1;
@property (strong, nonatomic) NSString *currentLevel2;
@property (strong, nonatomic) NSString *currentLevel3;
@property (strong, nonatomic) NSString *currentLevel4;

+ (LCLocationManager*)defaultManager;

- (id)initwithSometype:(NSInteger)type;

- (void)stopUpdatingLocation;
- (void)startUpdatingLocation;

- (BOOL)locationServicesEnabled;
- (BOOL)CanDeviceSupportAppBackgroundRefresh;

//取得經緯度
- (CLLocation*)getCurrentLocation;
- (void)getCurrentAddress;
- (CLLocationDistance)distanceOfLocation:(CLLocation*)location;

+ (void)getGeolocation:(NSString*)address completion:(GeocodeBlock)competion;

- (void)addSomeTestDataToNotifyList;

@end
