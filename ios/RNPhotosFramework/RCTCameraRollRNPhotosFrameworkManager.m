#import "RCTCameraRollRNPhotosFrameworkManager.h"
#import "RCTUtils.h"
#import "PHCachingImageManagerInstance.h"
#import "RCTConvert.h"
#import "RCTImageLoader.h"
#import "RCTLog.h"
#import "RCTUtils.h"
#import "RCTConvert+RNPhotosFramework.h"
@import Photos;

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

    PHFetchOptions *options = [self getFetchOptionsFromParams:[RCTConvert NSDictionary:params[@"fetchOptions"]]];
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

RCT_EXPORT_METHOD(getAlbums:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    
    NSMutableArray *responseArray = [NSMutableArray new];
    NSArray *multipleAlbumsQuery = [RCTConvert NSArray:params[@"albums"]];
    for(int i = 0; i < multipleAlbumsQuery.count;i++) {
        NSDictionary *albumsQuery = [multipleAlbumsQuery objectAtIndex:i];
        PHFetchResult<PHAssetCollection *> *albums = [self getAlbumsWithParams:albumsQuery];
        NSDictionary *multipleAlbumsResponse = [self generateAlbumsResponseFromParams:albumsQuery andAlbums:albums];
        [responseArray addObject:multipleAlbumsResponse];
    }
    resolve(responseArray);
}

-(void)generateResponseFromListWithAlbums:(NSArray<PHFetchResult<PHAssetCollection *> *> *)listWithAlbums {
    
}



-(NSMutableDictionary *)generateAlbumsResponseFromParams:(NSDictionary *)params andAlbums:(PHFetchResult<PHAssetCollection *> *)albums {
    
    NSMutableDictionary *collectionDictionary = [NSMutableDictionary new];
    NSString * typeString = params[@"type"];
    NSString * subTypeString = params[@"subType"];
    
    if(typeString != nil && subTypeString != nil) {
        if(typeString == nil) {
            typeString = @"album";
        }
        if(subTypeString == nil) {
            subTypeString = @"any";
        }
        [collectionDictionary setObject:typeString forKey:@"type"];
        [collectionDictionary setObject:subTypeString forKey:@"subType"];
    }

    RNPFAssetCountType countType = [RCTConvert RNPFAssetCountType:params[@"assetCount"]];
    NSMutableArray *albumsArray = [NSMutableArray arrayWithCapacity:albums.count];

    for(PHCollection *collection in albums)
    {
        if ([collection isKindOfClass:[PHAssetCollection class]])
        {
            NSMutableDictionary *albumDictionary = [NSMutableDictionary new];
            NSString * typeString = params[@"type"];
            NSString * subTypeString = params[@"subType"];
            
            [albumDictionary setObject:collection.localizedTitle forKey:@"title"];
            
            if(countType != RNPFAssetCountTypeNone) {
               int assetCount = [self getAssetCountForCollection:collection andCountType:countType andFetchParams:params];
               [albumDictionary setObject:@(assetCount) forKey:@"assetCount"];
            }
            [albumsArray addObject:albumDictionary];
        }
    }
    [collectionDictionary setObject:albumsArray forKey:@"albums"];
    return collectionDictionary;
}

-(int) getAssetCountForCollection:(PHAssetCollection *)collection andCountType:(RNPFAssetCountType)countType andFetchParams:(NSDictionary *)params {
    if(countType == RNPFAssetCountTypeEstimated){
        return [collection estimatedAssetCount];
    }
    NSDictionary *fetchOptions = [RCTConvert NSDictionary:params[@"fetchOptions"]];
    PHFetchOptions *options = [self getFetchOptionsFromParams:fetchOptions];
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    return assetsFetchResult.count;
}


-(PHFetchOptions *)getFetchOptionsFromParams:(NSDictionary *)params {
    if(params == nil) {
        return nil;
    }
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.includeAssetSourceTypes = [RCTConvert PHAssetSourceTypes:params[@"sourceTypes"]];
    options.includeHiddenAssets = [RCTConvert BOOL:params[@"includeHiddenAssets"]];
    options.includeAllBurstAssets = [RCTConvert BOOL:params[@"includeAllBurstAssets"]];
    options.fetchLimit = [RCTConvert int:params[@"fetchLimit"]];
    options.wantsIncrementalChangeDetails = [RCTConvert BOOL:params[@"wantsIncrementalChangeDetails"]];
    options.predicate = [self getPredicate:params];
    
    BOOL sortAscending = [RCTConvert BOOL:params[@"sortAscending"]];
    NSString *sortDescriptorKey = [RCTConvert NSString:params[@"sortDescriptorKey"]];
    if(sortDescriptorKey != nil) {
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:sortDescriptorKey ascending:sortAscending]];
    }
    return options;
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

-(PHFetchResult<PHAssetCollection *> *)getAlbumsWithParams:(NSDictionary *)params {
    NSString * typeString = params[@"type"];
    NSString * subTypeString = params[@"subType"];
    if(typeString == nil && subTypeString == nil) {
        return [self getTopUserAlbums:params];
    }
    PHAssetCollectionType type = [RCTConvert PHAssetCollectionType:typeString];
    PHAssetCollectionSubtype subType = [RCTConvert PHAssetCollectionSubtype:subTypeString];
    NSDictionary *fetchOptions = [RCTConvert NSDictionary:params[@"fetchOptions"]];
    PHFetchOptions *options = [self getFetchOptionsFromParams:params];
    PHFetchResult<PHAssetCollection *> *albums = [PHAssetCollection fetchAssetCollectionsWithType:type subtype:subType options:options];
    return albums;
}

-(PHFetchResult<PHAssetCollection *> *)getTopUserAlbums:(NSDictionary *)params
{
    PHFetchOptions *options = [self getFetchOptionsFromParams:params];
    PHFetchResult<PHAssetCollection *> *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:options];
    return topLevelUserCollections;
   
}


+(void) cacheFetchResult:(PHFetchResult *)fetchResult withuuid:(NSString *)uuid {
    NSMutableDictionary<NSString *, PHFetchResult *> *previousFetchResults = [RCTCameraRollRNPhotosFrameworkManager previousFetches];
    [previousFetchResults setObject:fetchResult forKey:uuid];
}

+(PHFetchResult *) getFetchResultFromCacheWithuuid:(NSString *)uuid {
    NSMutableDictionary<NSString *, PHFetchResult *> *previousFetchResults = [RCTCameraRollRNPhotosFrameworkManager previousFetches];
    return [previousFetchResults objectForKey:uuid];
}

+(NSMutableDictionary<NSString *, PHFetchResult *> *) previousFetches {
    static NSMutableDictionary<NSString *, PHFetchResult *> *fetchResults;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fetchResults = [[NSMutableDictionary alloc] init];
    });
    return fetchResults;
}

@end
