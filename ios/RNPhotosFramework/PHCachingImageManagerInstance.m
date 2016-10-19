#import "PHCachingImageManagerInstance.h"

@implementation PHCachingImageManagerInstance

#pragma mark Singleton Methods

+ (PHCachingImageManager *)sharedCachingManager {
  static PHCachingImageManager *sharedMyManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedMyManager = [[PHCachingImageManager alloc] init];
  });
  return sharedMyManager;
}

@end
