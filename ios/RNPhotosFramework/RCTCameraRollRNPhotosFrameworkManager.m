//
//  RCTCameraRollRNPhotosFrameworkManager.m
//  Gotlandskartan
//
//  Created by Olof Dahlbom on 2016-10-18.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "RCTCameraRollRNPhotosFrameworkManager.h"
#import "RCTUtils.h"
#import "PHCachingImageManagerInstance.h"

@import Photos;

@implementation RCTCameraRollRNPhotosFrameworkManager
RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

-(NSMutableArray<PHAsset *> *) getAssetsForFetchResult:(PHFetchResult *)assetsFetchResult startIndex:(NSUInteger)startIndex endIndex:(NSUInteger)endIndex {
  
  NSMutableArray<PHAsset *> *assets = [NSMutableArray new];
  [assetsFetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger index, BOOL *stop) {
    if(index >= startIndex){
      [assets addObject:asset];
    }
    if(index >= endIndex){
      *stop = YES;
    }
  }];
  return assets;
}

-(NSArray<NSDictionary *> *) assetsArrayToUriArray:(NSArray<PHAsset *> *)assetsArray {
  NSMutableArray *uriArray = [NSMutableArray arrayWithCapacity:assetsArray.count];
  for(int i = 0;i < assetsArray.count;i++) {
    PHAsset *asset =[assetsArray objectAtIndex:i];
    NSString *uri = [NSString stringWithFormat:@"pk://%@", [asset localIdentifier]];

    [uriArray addObject:@{
                          @"uri" : uri,
                          @"width" : @([asset pixelWidth]),
                          @"height" : @([asset pixelHeight])
                          }];
  }
  return uriArray;
}

RCT_EXPORT_METHOD(getPhotos:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  NSUInteger startIndex = [RCTConvert NSInteger:params[@"startIndex"]];
  NSUInteger endIndex = [RCTConvert NSInteger:params[@"endIndex"]];
  
  
  PHFetchOptions *options = [[PHFetchOptions alloc] init];
  options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", @[@(PHAssetMediaTypeImage)]];
  options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
  PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsWithOptions:options];
  NSArray *assets = [self getAssetsForFetchResult:assetsFetchResult startIndex:startIndex endIndex:endIndex];
  
  PHCachingImageManager *cacheManager = [PHCachingImageManagerInstance sharedCachingManager];
  
  [cacheManager startCachingImagesForAssets:assets targetSize:CGSizeApplyAffineTransform(CGSizeMake(91.5, 91.5), CGAffineTransformMakeScale(2, 2)) contentMode:PHImageContentModeAspectFill options:nil];
  
  resolve([self assetsArrayToUriArray:assets]);
}



@end
