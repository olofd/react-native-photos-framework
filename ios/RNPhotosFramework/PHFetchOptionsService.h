#import <Foundation/Foundation.h>
@import Photos;
@interface PHFetchOptionsService : NSObject
+(PHFetchOptions *)getAssetFetchOptionsFromParams:(NSDictionary *)params;
+(PHFetchOptions *)getCollectionFetchOptionsFromParams:(NSDictionary *)params;

@end
