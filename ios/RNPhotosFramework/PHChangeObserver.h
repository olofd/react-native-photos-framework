#import <Foundation/Foundation.h>
#import <React/RCTBridge.h>
#import "PHCachedFetchResult.h"
#import "PHCachedFetchResult.h"
@import Photos;
@interface PHChangeObserver : NSObject<PHPhotoLibraryChangeObserver>
+ (PHChangeObserver *)sharedChangeObserver;
-(NSString *) cacheFetchResultAndReturnUUID:(PHFetchResult *)fetchResult andObjectType:(Class)objectType andOrginalFetchParams:(NSDictionary *)params;
-(NSString *) cacheFetchResultWithUUID:(PHFetchResult *)fetchResult andObjectType:(Class)objectType andUUID:(NSString *)uuid andOrginalFetchParams:(NSDictionary *)params;
-(PHCachedFetchResult *) getFetchResultFromCacheWithuuid:(NSString *)uuid;
-(void) removeFetchResultFromCacheWithUUID:(NSString *)uuid;
-(void) cleanCache;


@property (strong, nonatomic) NSMutableDictionary<NSString *, PHCachedFetchResult *> *fetchResults;
@end
