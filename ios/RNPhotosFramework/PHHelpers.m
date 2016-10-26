#import "PHHelpers.h"
#import <CoreLocation/CLLocation.h>
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"

@implementation PHHelpers

+(NSDateFormatter *)getISODateFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    return dateFormatter;
}

+(NSString *)NSDateToJsonString:(NSDate *)date andDateFormatter:(NSDateFormatter *)dateFormatter {
    if(date == nil) {
        return [NSNull null];
    }
    NSString *iso8601String = [dateFormatter stringFromDate:date];
    return iso8601String;
}

+(NSTimeInterval)getTimeSince1970:(NSDate *)date {
    if(date == nil) {
        return 0;
    }
    return date.timeIntervalSince1970;
}

+(NSDictionary *)CLLocationToJson:(CLLocation *)loc {
    return loc ? @{
                       @"latitude": @(loc.coordinate.latitude),
                       @"longitude": @(loc.coordinate.longitude),
                       @"altitude": @(loc.altitude),
                       @"heading": @(loc.course),
                       @"speed": @(loc.speed),
                       } : @{};
}

+(NSString *)convertEnumToStringValue:(int)type andValues:(NSDictionary *)values {
    NSString *match = [[values allKeysForObject:[NSNumber numberWithInt:type]] firstObject];
    return [[values allKeysForObject:[NSNumber numberWithInt:type]] firstObject];
}

+(NSMutableArray*) nsOptionsToArray:(int)option andBitSize:(int)bitSize andReversedEnumDict:(NSDictionary *)dict
{
    if(option == 0){
        NSString *zeroValue = [dict objectForKey:0];
        return zeroValue ? [NSArray arrayWithObject:zeroValue] : [NSNull null];
    }
    NSMutableArray * nsOptions = [[NSMutableArray alloc] init];
        for (NSUInteger i=0; i < bitSize; i++) {
        NSUInteger enumBitValueToCheck = 1UL << i;
        if (option & enumBitValueToCheck) {
            [nsOptions addObject:[dict objectForKey:@(enumBitValueToCheck)]];
            
        }
    }
    
    return nsOptions;
}

+(NSString*) nsOptionsToValue:(int)option andBitSize:(int)bitSize andReversedEnumDict:(NSDictionary *)dict
{
    if(option == 0){
        NSString *zeroValue = [dict objectForKey:0];
        return zeroValue ? zeroValue : [NSNull null];
    }
    for (NSUInteger i=0; i < bitSize; i++) {
        NSUInteger enumBitValueToCheck = 1UL << i;
        if (option & enumBitValueToCheck) {
            return [dict objectForKey:@(enumBitValueToCheck)];
            
        }
    }
    
    return [NSNull null];
}

@end
