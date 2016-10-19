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

#import "RCTConvert.h"
#import "RCTImageLoader.h"
#import "RCTLog.h"
#import "RCTUtils.h"
@import Photos;

@implementation RCTConvert (PHAssetMediaType)

RCT_ENUM_CONVERTER(PHAssetMediaType, (@{
                                         
                                         // New values
                                         @"photo": @(PHAssetMediaTypeImage),
                                         @"video": @(PHAssetMediaTypeVideo),
                                         @"audio": @(PHAssetMediaTypeAudio),
                                         @"unknown": @(PHAssetMediaTypeUnknown)
                                         
                                         }), PHAssetMediaTypeImage, integerValue)
RCT_ENUM_CONVERTER(PHAssetMediaSubtype, (@{
                                        @"none": @(PHAssetMediaSubtypeNone),
                                        @"photoPanorama": @(PHAssetMediaSubtypePhotoPanorama),
                                        @"photoHDR": @(PHAssetMediaSubtypePhotoHDR),
                                        @"photoScreenshot": @(PHAssetMediaSubtypePhotoScreenshot),
                                        @"photoLive": @(PHAssetMediaSubtypePhotoLive),
                                        @"videoStreamed": @(PHAssetMediaSubtypeVideoStreamed),
                                        @"videoHighFrameRate": @(PHAssetMediaSubtypeVideoHighFrameRate),
                                        @"videoTimeLapse": @(PHAssetMediaSubtypeVideoTimelapse),
                                        
                                        }), PHAssetMediaSubtypeNone, integerValue)

+ (NSArray<NSNumber *> *)PHAssetMediaTypes:(NSArray<NSString *> *)arrayWithMediaTypeStrings
{
    if(arrayWithMediaTypeStrings.count == 0){
        return nil;
    }
    NSMutableArray *arrayWithMediaTypeEnums = [NSMutableArray arrayWithCapacity:arrayWithMediaTypeStrings.count];
    for(int i = 0; i < arrayWithMediaTypeStrings.count;i++) {
       PHAssetMediaType mediaType = [RCTConvert PHAssetMediaType:[arrayWithMediaTypeStrings objectAtIndex:i]];
        [arrayWithMediaTypeEnums addObject:@(mediaType)];
    }
    return arrayWithMediaTypeEnums;
}

+(NSMutableArray * ) PHAssetMediaSubtypes:(NSArray<NSString *> *)arrayWithSubMediaTypeStrings {
    if(arrayWithSubMediaTypeStrings.count == 0){
        return nil;
    }
    NSMutableArray *arrayWithSubMediaTypes = [NSMutableArray array];
    for(int i = 0; i < arrayWithSubMediaTypeStrings.count;i++) {
        PHAssetMediaSubtype mediaSubTyp = [RCTConvert PHAssetMediaSubtype:[arrayWithSubMediaTypeStrings objectAtIndex:i]];
        [arrayWithSubMediaTypes addObject:[NSNumber numberWithInt:mediaSubTyp]];
    }
    return arrayWithSubMediaTypes;
}
@end




@implementation RCTCameraRollRNPhotosFrameworkManager
RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;


RCT_EXPORT_METHOD(getPhotos:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSUInteger startIndex = [RCTConvert NSInteger:params[@"startIndex"]];
    NSUInteger endIndex = [RCTConvert NSInteger:params[@"endIndex"]];
    CGSize prepareForSizeDisplay = [RCTConvert CGSize:params[@"prepareForSizeDisplay"]];
    CGFloat prepareScale = [RCTConvert CGFloat:params[@"prepareScale"]];
    BOOL sortAscending = [RCTConvert BOOL:params[@"sortAscending"]];
    NSString *sortDescriptorKey = [RCTConvert NSString:params[@"sortDescriptorKey"]];
    if(sortDescriptorKey == nil) {
        sortDescriptorKey = @"creationDate";
    }
    

    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.predicate = [self getPredicate:params];

    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsWithOptions:options];
    
    NSArray *assets = [self getAssetsForFetchResult:assetsFetchResult startIndex:startIndex endIndex:endIndex];
    
    PHCachingImageManager *cacheManager = [PHCachingImageManagerInstance sharedCachingManager];
    
    if(prepareForSizeDisplay.width != 0 && prepareForSizeDisplay.height != 0) {
        if(prepareScale < 0.1) {
            prepareScale = 2;
        }
        [cacheManager startCachingImagesForAssets:assets targetSize:CGSizeApplyAffineTransform(prepareForSizeDisplay, CGAffineTransformMakeScale(prepareScale, prepareScale)) contentMode:PHImageContentModeAspectFill options:nil];
    }
    
    resolve([self assetsArrayToUriArray:assets]);
}

-(NSPredicate *) getPredicate:(NSDictionary *)params  {
    NSPredicate *mediaTypePredicate = [self getMediaTypePredicate:params];
    
    NSPredicate *subTypePredicate = [self getMediaSubTypePredicate:params];
    if(mediaTypePredicate && subTypePredicate) {
        return [NSCompoundPredicate andPredicateWithSubpredicates:@[mediaTypePredicate, subTypePredicate]];
    }
    return mediaTypePredicate != nil ? mediaTypePredicate : subTypePredicate;
}

-(NSPredicate *) getMediaTypePredicate:(NSDictionary *)params {
    NSMutableArray * mediaTypes = [RCTConvert PHAssetMediaTypes:params[@"mediaTypes"]];
    if(mediaTypes == nil) {
        return nil;
    }
    return [NSPredicate predicateWithFormat:@"mediaType in %@", mediaTypes];
}

-(NSPredicate *) getMediaSubTypePredicate:(NSDictionary *)params {
    NSMutableArray * mediaSubTypes = [RCTConvert PHAssetMediaSubtypes:params[@"mediaSubTypes"]];
    if(mediaSubTypes == nil) {
        return nil;
    }
    NSMutableArray *arrayWithPredicates = [NSMutableArray arrayWithCapacity:mediaSubTypes.count];

    for(int i = 0; i < mediaSubTypes.count;i++) {
        PHAssetMediaSubtype mediaSubType = [[mediaSubTypes objectAtIndex:i] intValue];
        [arrayWithPredicates addObject:[NSPredicate predicateWithFormat:@"((mediaSubtype & %d) == %d)", mediaSubType, mediaSubType]];
    }
    
    return [NSCompoundPredicate orPredicateWithSubpredicates:arrayWithPredicates];
}

+(NSDictionary<NSString *, NSMutableArray<PHFetchResult *> *> *) previousFetches {
    static NSDictionary<NSString *, NSMutableArray<PHFetchResult *> *> *fetchResults;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fetchResults = [[NSMutableArray alloc] init];
    });
    return fetchResults;
}

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
    [uriArray addObject:@{
                          @"uri" : [asset localIdentifier],
                          @"width" : @([asset pixelWidth]),
                          @"height" : @([asset pixelHeight])
                          }];
  }
  return uriArray;
}

@end
