#import <Foundation/Foundation.h>
@import Photos;
@interface PHFetchOptionsService : NSObject
+(PHFetchOptions *)getFetchOptionsFromParams:(NSDictionary *)params;
@end
