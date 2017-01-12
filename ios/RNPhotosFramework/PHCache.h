#import "PHCachedFetchResult.h"
#import <Foundation/Foundation.h>
@import Photos;
@interface PHCache : NSObject

+ (PHCache *)sharedPHCache;
-(NSString *) cacheFetchResultAndReturnUUID:(PHFetchResult *)fetchResult andObjectType:(Class)objectType andOrginalFetchParams:(NSDictionary *)params;
-(NSString *) cacheFetchResultWithUUID:(PHFetchResult *)fetchResult andObjectType:(Class)objectType andUUID:(NSString *)uuid andOrginalFetchParams:(NSDictionary *)params;
-(PHCachedFetchResult *) getFetchResultFromCacheWithuuid:(NSString *)uuid;
-(void) removeFetchResultFromCacheWithUUID:(NSString *)uuid;
-(void) cleanCache;

@property (strong, nonatomic) NSMutableDictionary<NSString *, PHCachedFetchResult *> *fetchResults;
@end
