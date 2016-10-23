#import <Foundation/Foundation.h>
#import "RCTBridge.h"
@import Photos;
@interface PHChangeObserver : NSObject<PHPhotoLibraryChangeObserver>
+ (PHChangeObserver *)sharedChangeObserver;
-(NSString *) cacheFetchResultAndReturnUUID:(PHFetchResult *)fetchResult;
-(PHFetchResult *) getFetchResultFromCacheWithuuid:(NSString *)uuid;
-(void) cleanCache;

@property (strong, nonatomic) NSMutableDictionary<NSString *, PHFetchResult *> *fetchResults;
@end
