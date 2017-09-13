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
        //        NSLog(@"address Dict: %@", mapItem.placemark.addressDictionary);
        
        [pm setValue:[NSString stringWithFormat:@"%@ %@",mapItem.placemark.subThoroughfare, mapItem.placemark.thoroughfare]  forKey:@"street"];
        NSString * street2 = [self parseStreet2:mapItem.placemark];
        if([street2 length] > 0) {
            [pm setValue:street2 forKey:@"street2"];
        }
        [pm setValue:mapItem.placemark.locality forKey:@"city"];
        [pm setValue:mapItem.placemark.administrativeArea forKey:@"state"];
        [pm setValue:mapItem.placemark.postalCode forKey:@"zip"];
        [pm setValue:mapItem.placemark.ISOcountryCode forKey:@"country"];

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

- (NSString*) parseStreet2: (MKPlacemark*) placemark {
    NSArray * lines = placemark.addressDictionary[@"FormattedAddressLines"];
    if(lines.count > 3 && placemark.thoroughfare) {
        BOOL hasLocationName = ![lines.firstObject containsString:placemark.thoroughfare];
        NSUInteger count = lines.count;
        if(count == 5 && hasLocationName) {
            return [lines objectAtIndex:2];
        }
        else if(count == 4) {
            return [lines objectAtIndex:1];
        }
    }
    return nil;
    //    0) apple
    //    1) 232 madison
    //    2) #123
    //    3) NYC NY 10016
    //    4) US
    //
    //    0) apple
    //    1) 232 madison
    //    2) NYC NY 10016
    //    3) US
    //
    //    0) 232 madison
    //    1) #123
    //    2) NYC NY 10016
    //    3) US
    //
    //    0) 232 madison
    //    1) NYC NY 10016
    //    2) US
    //
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
