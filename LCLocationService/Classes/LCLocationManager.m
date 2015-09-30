//
//  LocationManager.m
//  UICatalog
//
//  Created by Leo on 11/8/14.
//  Copyright (c) 2014 Perfectidea. All rights reserved.
//

#import "LCLocationManager.h"

#define regionIdentifier @"regionIdentifier"
#define wacoffeIdentifier @"wacoffeIdentifier"
#define adacompanyIdentifier @"adacompanyIdentifier"

const static NSInteger radiusNearby = 1000;
const static NSInteger radiusSmall = 2000;
const static NSInteger radiusMedium = 50000;
const static NSInteger radiusHuge = 1000000;

@implementation LCLocationManager

+ (LCLocationManager*)defaultManager
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[LCLocationManager alloc] init];
    });
    
    return instance;
}

- (id)initwithSometype:(NSInteger)type
{
//    self = [self init];
//    if (self)
//    {
//        
//    }
    return self;
}

- (id)init
{
    if (self = [super init])
    {
        [self createLocationManager];
    }
    return self;
}

- (void)createLocationManager
{
    self.locmanager = [[CLLocationManager alloc] init];
    
    //[self startUpdatingLocation];
    /*
     注意
     NSLocationAlwaysUsageDescription
     NSLocationAlwaysUsageDescription
     在Setting Info.plist裡面一定要加上這兩組Key才可以正常使用(iOS8)
     */
}

- (void)stopUpdatingLocation
{
    [_locmanager stopUpdatingLocation];
    [_locmanager stopUpdatingHeading];
    [_locmanager stopMonitoringSignificantLocationChanges];
}

- (void)startUpdatingLocation
{
    /*
     iOS8 以上
     */
    if ([self.locmanager respondsToSelector:@selector(requestAlwaysAuthorization)])
    {
        //[self.locmanager requestWhenInUseAuthorization];
        [self.locmanager requestAlwaysAuthorization];
    }
    [_locmanager setDelegate:self];
    //設定人在移動多遠時才會定位的距離
    [_locmanager setDistanceFilter:1000.0f];
    //degree -->手機在轉動時
    [_locmanager setHeadingFilter:kCLHeadingFilterNone];
    
#warning 準確度先調整為100公尺
    //精準度，愈精準愈耗電。
    [_locmanager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    //開始定位
    [_locmanager startUpdatingLocation];
    [_locmanager startMonitoringSignificantLocationChanges];
    NSLog(@"(1) lat : %f, long : %f", _locmanager.location.coordinate.latitude, _locmanager.location.coordinate.longitude);
    
    [_locmanager startUpdatingHeading];
    
    NSLog(@"(2) lat : %f, long : %f", _locmanager.location.coordinate.latitude, _locmanager.location.coordinate.longitude);

    
    //[self startMonitoringRegions];
    
}

- (void)startMonitoringRegions
{
    [_locmanager startMonitoringSignificantLocationChanges];
}

- (CLLocation*)getCurrentLocation
{
    return _locmanager.location;
}

- (BOOL)locationServicesEnabled
{
    NSLog(@"locationService is %@", [CLLocationManager locationServicesEnabled] ? @"YES" : @"NO");
    if([CLLocationManager locationServicesEnabled])
    {
        
        NSLog(@"Location Services Enabled");
        
        if([CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied)
        {
            return NO;
        }
    }
    return YES;
}

-(BOOL)CanDeviceSupportAppBackgroundRefresh
{
    // Override point for customization after application launch.
    if ([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusAvailable)
    {
        NSLog(@"Background updates are available for the app.");
        return YES;
    }
    else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied)
    {
        NSLog(@"The user explicitly disabled background behavior for this app or for the whole system.");
        return NO;
    }
    else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted)
    {
        NSLog(@"Background updates are unavailable and the user cannot enable them again. For example, this status can occur when parental controls are in effect for the current user.");
        return NO;
    }
    return NO;
}

#pragma mark - LocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    BOOL canUseLocationNotifications = (status == kCLAuthorizationStatusAuthorizedWhenInUse);
    if (canUseLocationNotifications)
    {
        //[self startMonitoringRegions];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"(old) lat : %f, long : %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude);
    NSLog(@"(new) lat : %f, long : %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    //開始註冊region
    [self removeRegionsArroundUser];
    [self registerRegionsArroundUserCoordinate:newLocation.coordinate];
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"start monitoring %@", region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    [self notifyNearbyPins];
    [self removeRegionsArroundUser];
    [self registerRegionsArroundUserCoordinate:manager.location.coordinate];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    [self notifyNearbyPins];
    [self removeRegionsArroundUser];
    [self registerRegionsArroundUserCoordinate:manager.location.coordinate];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"monitoringDidFailForRegion - error: %@", [error localizedDescription]);
}

- (void)getCurrentAddress
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?latlng=%f,%f&sensor=false",self.getCurrentLocation.coordinate.latitude, self.getCurrentLocation.coordinate.longitude]];
    
    
    [[RequestManager defaultManager] requestWith:url param:@{} httpMethod:kPostMethod usePostBody:NO completion:^(PFRequestTag tag, NSData *data) {
        if (data)
        {
            NSDictionary *dict = [data parseToAddress];
            
            self.currentAddress = dict[@"address"];
            self.currentLevel1 = dict[@"level1"];
            self.currentLevel2 = dict[@"level2"];
            self.currentLevel3 = dict[@"level3"];
            self.currentLevel4 = dict[@"level4"];
        }
    } falure:^(PFRequestTag tag, NSError *error){
        DLog(@"error");
    }];
}

- (CLLocationDistance)distanceOfLocation:(CLLocation *)location
{
    CLLocation *distanceLocation = [[CLLocation alloc] initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    CLLocationDistance distance = [self.getCurrentLocation distanceFromLocation:distanceLocation];
    return distance;
}

+ (void)getGeolocation:(NSString *)address completion:(GeocodeBlock)competion
{
    //@"http://maps.google.com/maps/api/geocode/json?address=%E5%8F%B0%E5%8C%97%E5%B8%82%E7%91%9E%E5%85%89%E8%B7%AF480%E8%99%9F&sensor=true"
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?address=%@&sensor=false", address]];
    [[RequestManager defaultManager] requestWith:url param:@{} httpMethod:kPostMethod usePostBody:NO completion:^(PFRequestTag tag, NSData *data){
    
        
    } falure:^(PFRequestTag tag, NSError *error){
    
        
    }];
}

/*
 假資料
 */
- (void)addSomeTestDataToNotifyList
{
    [PinItem getUserPinsNearByCurrentLocationWithUserId:[UserPreferences userPreferences].userId isPush:YES completion:^(BOOL success, NSArray *items){
        if (items.count > 0)
        {
            PinItem *item = [items firstObject];
            NSArray *pinIds = [items valueForKeyPath:@"pinId"];
            NSString *message = [NSString stringWithFormat:NotifyMessageFormat, item.name, @(items.count)];
            
            
            
            //5B15C70D-0F7F-4EA1-AB88-48579CD90548
            //D86045DC-3204-41A5-9A8C-A8071B1620C2 --> 阿達
            
            NSDictionary *data = @{
                                   @"alert" : message,
                                   @"badge" : [NSString stringWithFormat:@"%li", items.count],
                                   @"type" : @"1"
                                   };
            
            PFQuery *query = [PFInstallation query];
            
            [query whereKey:@"device_id" equalTo:[UIDevice currentDevice].identifierForVendor.UUIDString];
            
            PFPush *push = [PFPush new];
            [push setQuery:query];
            [push setData:data];
            [push sendPushInBackground];
            
            
            [self saveEventToParseWithMessage:message];
            
            //儲存至通知清單
            if (![item saveToNotifyListWithDate:[NSDate date] message:message pins:[self convertPinsToString:pinIds]])
            {
                DLog(@"儲存通知清單失敗");
            }
        }
    }];
}

#pragma mark - PrivteMethods
- (NSString*)convertPinsToString:(NSArray*)pins
{
    NSMutableString *string = [NSMutableString string];
    for (NSString *pin in pins)
    {
        [string appendFormat:@"%@,",pin];
    }
    return string;
}

- (void) registerRegionsArroundUserCoordinate:(CLLocationCoordinate2D)coordinate
{
    CLCircularRegion* regionNearby = [[CLCircularRegion alloc] initWithCenter:coordinate radius:radiusNearby identifier:kRegionNearby];
    CLCircularRegion* regionSmall = [[CLCircularRegion alloc] initWithCenter:coordinate radius:radiusSmall identifier:kRegionSmall];
    CLCircularRegion* regionMedium = [[CLCircularRegion alloc] initWithCenter:coordinate radius:radiusMedium identifier:kRegionMedium];
    CLCircularRegion* regionHuge = [[CLCircularRegion alloc] initWithCenter:coordinate radius:radiusHuge identifier:kRegionHuge];
    
    [self.locmanager startMonitoringForRegion:regionNearby];
    [self.locmanager startMonitoringForRegion:regionSmall];
    [self.locmanager startMonitoringForRegion:regionMedium];
    [self.locmanager startMonitoringForRegion:regionHuge];
    [[UserPreferences userPreferences] setRegionNearby:regionNearby];
    [[UserPreferences userPreferences] setRegionSmall:regionSmall];
    [[UserPreferences userPreferences] setRegionMedium:regionMedium];
    [[UserPreferences userPreferences] setRegionHuge:regionMedium];
}

-(void) removeRegionsArroundUser
{
    CLCircularRegion* regionNearby = [UserPreferences userPreferences].getRegionNearby;
    if(regionNearby)
    {
        [self.locmanager stopMonitoringForRegion:regionNearby];
    }
    CLCircularRegion* regionSmall = [UserPreferences userPreferences].getRegionSmall;
    if(regionSmall)
    {
        [self.locmanager stopMonitoringForRegion:regionSmall];
    }
    CLCircularRegion* regionMedium = [UserPreferences userPreferences].getRegionMedium;
    if(regionMedium)
    {
        [self.locmanager stopMonitoringForRegion:regionMedium];
    }
    CLCircularRegion* regionHuge = [UserPreferences userPreferences].getRegionHuge;
    if(regionHuge)
    {
        [self.locmanager stopMonitoringForRegion:regionHuge];
    }
}

-(void) notifyNearbyPins
{
    if (![UserPreferences userPreferences].isLogin)
    {
        return;
    }
    [[UpdateManager defaultManager] startUpdateUserDataWithBlock:^(BOOL success){
        [PinItem getUserPinsNearByCurrentLocationWithUserId:[UserPreferences userPreferences].userId isPush:YES completion:^(BOOL success, NSArray *items){
            if (items.count > 0)
            {
                PinItem *item = [items firstObject];
                NSArray *pinIds = [items valueForKeyPath:@"pinId"];
                NSString *message = [NSString stringWithFormat:NotifyMessageFormat, item.name, @(items.count)];
                
                NSDictionary *data = @{
                                       @"alert" : message,
                                       @"badge" : [NSString stringWithFormat:@"%li", items.count],
                                       @"type" : @"1"
                                       };
                
                PFQuery *query = [PFInstallation query];
                
                [query whereKey:@"device_id" equalTo:[UIDevice currentDevice].identifierForVendor.UUIDString];
                
                PFPush *push = [PFPush new];
                [push setQuery:query];
                [push setData:data];
                [push sendPushInBackground];
                
                
                [self saveEventToParseWithMessage:message];
                
                //儲存至通知清單
                if ([item saveToNotifyListWithDate:[NSDate date] message:message pins:[self convertPinsToString:pinIds]])
                {
                    DLog(@"儲存通知清單失敗");
                }
            }
            /*
             真正要發通知時，才會去更新資料庫中的值s
             */
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                for (PinItem *item in items)
                {
                    [item updateLastNotifiedTime:[NSDate date]];
                }
                
            });
        }];
    }];
}

@end
