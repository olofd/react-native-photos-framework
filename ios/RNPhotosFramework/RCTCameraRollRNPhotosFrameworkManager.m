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
        PHFetchResult<PHAssetCollection *> *albums = [self getAlbums:albumsQuery];
        responseArray = [self generateAlbumsResponseFromParams:albumsQuery andAlbums:albums andResponseArray:responseArray];
    }
    resolve(responseArray);
}

-(void)generateResponseFromListWithAlbums:(NSArray<PHFetchResult<PHAssetCollection *> *> *)listWithAlbums {
    
}


-(NSMutableArray *)generateAlbumsResponseFromParams:(NSDictionary *)params andAlbums:(PHFetchResult<PHAssetCollection *> *)albums andResponseArray:(NSMutableArray *)responseArray {
    
    RNPFAssetCountType countType = [RCTConvert RNPFAssetCountType:params[@"assetCount"]];

    for(PHCollection *collection in albums)
    {
        if ([collection isKindOfClass:[PHAssetCollection class]])
        {
            NSMutableDictionary *albumDictionary = [NSMutableDictionary new];
            [albumDictionary setValue:collection.localizedTitle forKey:@"title"];
            if(countType != RNPFAssetCountTypeNone) {
               int assetCount = [self getAssetCountForCollection:collection andCountType:countType andFetchParams:params];
               [albumDictionary setValue:@(assetCount) forKey:@"assetCount"];
            }
            [responseArray addObject:albumDictionary];
        }
    }
    return responseArray;
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

-(PHFetchResult<PHAssetCollection *> *)getAlbums:(NSDictionary *)params {
    PHAssetCollectionType type = [RCTConvert PHAssetCollectionType:params[@"type"]];
    PHAssetCollectionSubtype subType = [RCTConvert PHAssetCollectionSubtype:params[@"subType"]];
    NSDictionary *fetchOptions = [RCTConvert NSDictionary:params[@"fetchOptions"]];
    PHFetchOptions *options = [self getFetchOptionsFromParams:params];
    PHFetchResult<PHAssetCollection *> *albums = [PHAssetCollection fetchAssetCollectionsWithType:type subtype:subType options:options];
    return albums;
}

-(NSArray *)getUserAlbums
{
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];

    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    NSArray *collectionsFetchResults = @[topLevelUserCollections, smartAlbums];
    //What I do here is fetch both the albums list and the assets of each album.
    //This way I have acces to the number of items in each album, I can load the 3
    //thumbnails directly and I can pass the fetched result to the gridViewController.
    NSArray *collectionsFetchResultsAssets;
    NSArray *collectionsFetchResultsTitles;
    
    //Fetch PHAssetCollections:
    
    //All album: Sorted by descending creation date.
    NSMutableArray *allFetchResultArray = [[NSMutableArray alloc] init];
    NSMutableArray *allFetchResultLabel = [[NSMutableArray alloc] init];
    {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
     //   options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", self.picker.mediaTypes];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsWithOptions:options];
        [allFetchResultArray addObject:assetsFetchResult];
       // [allFetchResultLabel addObject:NSLocalizedStringFromTableInBundle(@"picker.table.all-photos-label",  @"GMImagePicker", [NSBundle bundleForClass:GMImagePickerController.class], @"All photos")];
    }
    
    //User albums:
    NSMutableArray *userFetchResultArray = [[NSMutableArray alloc] init];
    NSMutableArray *userFetchResultLabel = [[NSMutableArray alloc] init];
    for(PHCollection *collection in topLevelUserCollections)
    {
        if ([collection isKindOfClass:[PHAssetCollection class]])
        {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
           // options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", self.picker.mediaTypes];
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            
            //Albums collections are allways PHAssetCollectionType=1 & PHAssetCollectionSubtype=2
            
            PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
            [userFetchResultArray addObject:assetsFetchResult];
            [userFetchResultLabel addObject:collection.localizedTitle];
        }
    }
    
    
    //Smart albums: Sorted by descending creation date.
 /*   NSMutableArray *smartFetchResultArray = [[NSMutableArray alloc] init];
    NSMutableArray *smartFetchResultLabel = [[NSMutableArray alloc] init];
    for(PHCollection *collection in smartAlbums)
    {
        if ([collection isKindOfClass:[PHAssetCollection class]])
        {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            
            //Smart collections are PHAssetCollectionType=2;
            if(self.picker.customSmartCollections && [self.picker.customSmartCollections containsObject:@(assetCollection.assetCollectionSubtype)])
            {
                PHFetchOptions *options = [[PHFetchOptions alloc] init];
             //   options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", self.picker.mediaTypes];
                options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
                
                PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
                if(assetsFetchResult.count>0)
                {
                    [smartFetchResultArray addObject:assetsFetchResult];
                    [smartFetchResultLabel addObject:collection.localizedTitle];
                }
            }
        }
    }*/
    
    return @[allFetchResultArray,userFetchResultArray];
}

-(NSDictionary *)getUserOpLevelAlbums:(NSDictionary *)params {
    PHFetchOptions *options = [self getFetchOptionsFromParams:params];

    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:options];
    NSMutableArray *userFetchResultArray = [[NSMutableArray alloc] init];
    NSMutableArray *userFetchResultLabel = [[NSMutableArray alloc] init];
    for(PHCollection *collection in topLevelUserCollections)
    {
        if ([collection isKindOfClass:[PHAssetCollection class]])
        {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            // options.predicate = [NSPredicate predicateWithFormat:@"mediaType in %@", self.picker.mediaTypes];
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            
            //Albums collections are allways PHAssetCollectionType=1 & PHAssetCollectionSubtype=2
            
            PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
            [userFetchResultArray addObject:assetsFetchResult];
            [userFetchResultLabel addObject:collection.localizedTitle];
        }
    }
    
    return nil;
}



@end
