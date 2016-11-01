#import <Foundation/Foundation.h>
#import "RCTBridge.h"
#import "RCTCachedFetchResult.h"
#import "RCTCachedFetchResult.h"
@import Photos;
@interface PHChangeObserver : NSObject<PHPhotoLibraryChangeObserver>
+ (PHChangeObserver *)sharedChangeObserver;
-(NSString *) cacheFetchResultAndReturnUUID:(PHFetchResult *)fetchResult andObjectType:(Class)objectType andOrginalFetchParams:(NSDictionary *)params;
-(NSString *) cacheFetchResultWithUUID:(PHFetchResult *)fetchResult andObjectType:(Class)objectType andUUID:(NSString *)uuid andOrginalFetchParams:(NSDictionary *)params;
-(RCTCachedFetchResult *) getFetchResultFromCacheWithuuid:(NSString *)uuid;
-(void) removeFetchResultFromCacheWithUUID:(NSString *)uuid;
-(void) cleanCache;


@property (strong, nonatomic) NSMutableDictionary<NSString *, RCTCachedFetchResult *> *fetchResults;
@end
