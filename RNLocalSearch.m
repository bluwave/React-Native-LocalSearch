// RNLocalSearch.m

#import "RNLocalSearch.h"
#import "RCTUtils.h"

@implementation RNLocalSearch
{
    MKLocalSearch *localSearch;
}

RCT_EXPORT_MODULE()

#pragma mark -
#pragma mark format RCT callback response

- (NSArray *)formatLocalSearchCallback:(MKLocalSearchResponse *)localSearchResponse
{
    NSMutableArray *RCTResponse = [[NSMutableArray alloc] init];
    
    for (MKMapItem *mapItem in localSearchResponse.mapItems) {
        NSMutableDictionary *formedLocation = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *pm = [[NSMutableDictionary alloc] init];
        [pm setValue:mapItem.placemark.thoroughfare forKey:@"thoroughfare"];
        [pm setValue:mapItem.placemark.subThoroughfare forKey:@"subThoroughfare"];
        [pm setValue:mapItem.placemark.locality forKey:@"locality"];
        [pm setValue:mapItem.placemark.administrativeArea forKey:@"administrativeArea"];
        [pm setValue:mapItem.placemark.postalCode forKey:@"postalCode"];
        [pm setValue:mapItem.placemark.ISOcountryCode forKey:@"ISOcountryCode"];
        [formedLocation setValue:pm forKey:@"placemark"];
        [formedLocation setValue:mapItem.name forKey:@"name"];
        [formedLocation setValue:mapItem.placemark.title forKey:@"title"];
        [formedLocation setValue:mapItem.phoneNumber forKey:@"phoneNumber"];
        [formedLocation setValue:@{@"latitude": @(mapItem.placemark.coordinate.latitude),
                                   @"longitude": @(mapItem.placemark.coordinate.longitude)} forKey:@"location"];
        
        [RCTResponse addObject:formedLocation];
    }
    
    return [RCTResponse copy];
}

#pragma mark -
#pragma mark RCT Exports

RCT_EXPORT_METHOD(searchForLocations:(NSString *)searchText near:(MKCoordinateRegion)region callback:(RCTResponseSenderBlock)callback)
{
    [localSearch cancel];
    
    MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc] init];
    searchRequest.naturalLanguageQuery = searchText;
    searchRequest.region = region;

    localSearch = [[MKLocalSearch alloc] initWithRequest:searchRequest];
    
    __weak RNLocalSearch *weakSelf = self;
    [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        
        if (error) {
            callback(@[RCTMakeError(@"Failed to make local search. ", error, @{@"key": searchText}), [NSNull null]]);
        } else {
            NSArray *RCTResponse = [weakSelf formatLocalSearchCallback:response];
            callback(@[[NSNull null], RCTResponse]);
        }
    }];
}

@end
