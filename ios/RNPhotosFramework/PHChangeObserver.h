#import <Foundation/Foundation.h>
#import <React/RCTBridge.h>
#import "PHCachedFetchResult.h"
#import "PHCachedFetchResult.h"
#import <React/RCTEventEmitter.h>

@import Photos;
@interface PHChangeObserver : NSObject<PHPhotoLibraryChangeObserver>
- (instancetype)initWithEventEmitter:(RCTEventEmitter *)eventEmitter;
- (void)removeChangeObserver;

@property (weak, nonatomic) RCTEventEmitter * eventEmitter;
@end
