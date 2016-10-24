#import <Foundation/Foundation.h>
#import "RCTBridge.h"
#import "RCTCachedFetchResult.h"
#import "RCTCachedFetchResult.h"
@import Photos;
@interface PHChangeObserver : NSObject<PHPhotoLibraryChangeObserver>
+ (PHChangeObserver *)sharedChangeObserver;
-(NSString *) cacheFetchResultAndReturnUUID:(PHFetchResult *)fetchResult andObjectType:(Class)objectType;
-(RCTCachedFetchResult *) getFetchResultFromCacheWithuuid:(NSString *)uuid;
-(void) cleanCache;

@property (strong, nonatomic) NSMutableDictionary<NSString *, RCTCachedFetchResult *> *fetchResults;
@end
