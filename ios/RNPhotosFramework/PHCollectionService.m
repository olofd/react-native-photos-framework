#import "PHCollectionService.h"
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
#import "PHFetchOptionsService.h"
#import "PHChangeObserver.h"
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
#import "PHHelpers.h"
#import "RCTImageLoader.h"
#import "PHAssetsService.h"

@import Photos;
@implementation PHCollectionService

static id ObjectOrNull(id object)
{
    return object ?: [NSNull null];
}

+(PHAssetCollection *) getAssetCollectionForParams:(NSDictionary *)params {
    NSString * cacheKey = [RCTConvert NSString:params[@"_cacheKey"]];
    NSString * albumLocalIdentifier = [RCTConvert NSString:params[@"albumLocalIdentifier"]];
    if(albumLocalIdentifier) {
        return [self getAssetForLocalIdentifer:albumLocalIdentifier];
    }
    return [[[PHChangeObserver sharedChangeObserver] getFetchResultFromCacheWithuuid:cacheKey] fetchResult];
}

+(PHAssetCollection *) getAssetForLocalIdentifer:(NSString *)localIdentifier {
    if(localIdentifier == nil) {
        return nil;
    }
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[localIdentifier] options:nil];
    return collections.firstObject;
}

+(PHFetchResult<PHAssetCollection *> *)getAlbumsWithLocalIdentifiers:(NSArray<NSString *> *)localIdentifiers andParams:(NSDictionary *)params{
    PHFetchOptions *fetchOptions = [PHFetchOptionsService getCollectionFetchOptionsFromParams:params];
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:localIdentifiers options:fetchOptions];
}

+(NSMutableDictionary *) getAlbums:(NSDictionary *)params {
    PHFetchResult<PHAssetCollection *> *albums = [PHCollectionService getAlbumsWithParams:params];
    return [PHCollectionService generateCollectionResponseWithCollections:albums andParams:params];
}

+(PHFetchResult<PHAssetCollection *> *)getAlbumsWithParams:(NSDictionary *)params {
    NSString * typeString = params[@"type"];
    NSString * subTypeString = params[@"subType"];
    if(typeString == nil && subTypeString == nil) {
        return [PHCollectionService getTopUserAlbums:params];
    }
    PHAssetCollectionType type = [RCTConvert PHAssetCollectionType:typeString];
    PHAssetCollectionSubtype subType = [RCTConvert PHAssetCollectionSubtype:subTypeString];
    PHFetchOptions *options = [PHFetchOptionsService getCollectionFetchOptionsFromParams:params];
    PHFetchResult<PHAssetCollection *> *albums = [PHAssetCollection fetchAssetCollectionsWithType:type subtype:subType options:options];
    return albums;
}

+(PHFetchResult<PHAssetCollection *> *)getTopUserAlbums:(NSDictionary *)params
{
    PHFetchOptions *options = [PHFetchOptionsService getCollectionFetchOptionsFromParams:params];
    PHFetchResult<PHAssetCollection *> *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:options];
    return topLevelUserCollections;
}

+(PHFetchResult<PHAssetCollection *> *)getUserAlbumsByTitles:(NSArray *)titles withParams:(NSDictionary *)params {
    PHFetchOptions *fetchOptions = [PHFetchOptionsService getCollectionFetchOptionsFromParams:params];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"title in %@", titles];
    NSString * typeString = params[@"type"];
    NSString * subTypeString = params[@"subType"];
    PHAssetCollectionType type = [RCTConvert PHAssetCollectionType:typeString];
    PHAssetCollectionSubtype subType = [RCTConvert PHAssetCollectionSubtype:subTypeString];
    PHAssetCollection *collections = [PHAssetCollection fetchAssetCollectionsWithType:type
                                                                              subtype:subType
                                                                              options:fetchOptions];
    return collections;
}


+(NSMutableDictionary *) generateCollectionResponseWithCollections:(PHFetchResult<PHAssetCollection *> *)collections andParams:(NSDictionary *)params {
    NSString *noCacheFlag = params[@"noCache"];
    BOOL preCacheAssets = [RCTConvert BOOL:params[@"preCacheAssets"]];
    BOOL shouldCache = noCacheFlag == nil || ![RCTConvert BOOL:noCacheFlag];
    
    NSMutableDictionary *multipleAlbumsResponse = [PHCollectionService generateAlbumsResponseFromParams:params andAlbums:collections andCacheAssets:preCacheAssets];
    if(shouldCache) {
        NSString *uuid = [[PHChangeObserver sharedChangeObserver] cacheFetchResultAndReturnUUID:collections andObjectType:[PHAssetCollection class] andOrginalFetchParams:params];
        [multipleAlbumsResponse setObject:uuid forKey:@"_cacheKey"];
    }
    return multipleAlbumsResponse;
}

+(NSMutableDictionary *)generateAlbumsResponseFromParams:(NSDictionary *)params andAlbums:(PHFetchResult<PHAssetCollection *> *)albums andCacheAssets:(BOOL)cacheAssets {
    
    RNPFAssetCountType countType = [RCTConvert RNPFAssetCountType:params[@"assetCount"]];
    int numberOfPreviewAssets = [RCTConvert int:params[@"previewAssets"]];
    BOOL includeMetaData = [RCTConvert BOOL:params[@"includeMetaData"]];
    
    NSMutableDictionary *collectionDictionary = [NSMutableDictionary new];
    NSMutableArray *albumsArray = [NSMutableArray arrayWithCapacity:albums.count];
    
    NSDictionary *paramsToUse = params;
    if(!cacheAssets && countType == RNPFAssetCountTypeEstimated && numberOfPreviewAssets > 0) {
        //We are going to fetch only for preview items.
        //Let's set a fetchLimit.
        NSMutableDictionary *mutableParams = [params mutableCopy];
        NSDictionary *fetchOptions = [RCTConvert NSDictionary:mutableParams[@"fetchOptions"]];
        NSMutableDictionary *mutFetchOptions;
        if(fetchOptions) {
            mutFetchOptions = [fetchOptions mutableCopy];
            [mutFetchOptions setObject:@(numberOfPreviewAssets) forKey:@"fetchLimit"];
        }else {
            mutFetchOptions = [NSMutableDictionary dictionaryWithObject:@(numberOfPreviewAssets) forKey:@"fetchLimit"];
        }
        [mutableParams setObject:mutFetchOptions forKey:@"fetchOptions"];
        paramsToUse = mutableParams;
    }
    
    for(PHCollection *collection in albums)
    {
        if ([collection isKindOfClass:[PHAssetCollection class]])
        {
            NSMutableDictionary *albumDictionary = [self generateAlbumResponseFromCollection:collection numberOfPreviewAssets:numberOfPreviewAssets countType:countType includeMetaData:includeMetaData cacheAssets:cacheAssets assetFetchParams:paramsToUse];
            
            [albumsArray addObject:albumDictionary];
        }
    }
    [collectionDictionary setObject:albumsArray forKey:@"albums"];
    return collectionDictionary;
}

+ (NSMutableDictionary *)generateAlbumResponseFromCollection:(PHCollection *)collection numberOfPreviewAssets:(int)numberOfPreviewAssets countType:(RNPFAssetCountType)countType includeMetaData:(BOOL)includeMetaData cacheAssets:(BOOL)cacheAssets assetFetchParams:(NSDictionary *)assetFetchParams {
    
            PHAssetCollection *phAssetCollection = (PHAssetCollection *)collection;
            NSMutableDictionary *albumDictionary = [NSMutableDictionary new];
            PHAssetCollectionType albumType = [phAssetCollection assetCollectionType];
            PHAssetCollectionSubtype subType = [phAssetCollection assetCollectionSubtype];
            [albumDictionary setObject:[[RCTConvert PHAssetCollectionTypeValuesReversed] objectForKey:@(albumType)] forKey:@"type"];
            if(subType == 1000000201) {
                //Some kind of undocumented value here for recentlyDeleted
                //Found references to this when i Googled.
              [albumDictionary setObject:@"recentlyDeleted" forKey:@"subType"];
            }else {
               [albumDictionary setObject:[[RCTConvert PHAssetCollectionSubtypeValuesReversed] objectForKey:@(subType)] forKey:@"subType"];
            }

            [albumDictionary setObject:phAssetCollection.localizedTitle forKey:@"title"];
            [albumDictionary setObject:phAssetCollection.localIdentifier forKey:@"localIdentifier"];
            
            if(includeMetaData) {
                [albumDictionary setObject:@([PHHelpers getTimeSince1970:phAssetCollection.startDate])forKey:@"startDate"];
                [albumDictionary setObject:@([PHHelpers getTimeSince1970:phAssetCollection.endDate]) forKey:@"endDate"];
                [albumDictionary setObject:[PHHelpers CLLocationToJson:phAssetCollection.approximateLocation] forKey:@"approximateLocation"];
                [albumDictionary setObject:ObjectOrNull(phAssetCollection.localizedLocationNames) forKey:@"localizedLocationNames"];
            }

            if(cacheAssets || numberOfPreviewAssets > 0 || countType == RNPFAssetCountTypeExact) {

                PHFetchResult<PHAsset *> * assets = [PHCollectionService getAssetForCollection:collection andFetchParams:assetFetchParams];

                if(cacheAssets) {
                    NSString *uuid = [[PHChangeObserver sharedChangeObserver] cacheFetchResultAndReturnUUID:assets andObjectType:[PHAsset class] andOrginalFetchParams:assetFetchParams];
                    [albumDictionary setObject:uuid forKey:@"_cacheKey"];
                }
                
                if(countType == RNPFAssetCountTypeExact) {
                    [albumDictionary setObject:@(assets.count) forKey:@"assetCount"];
                }
                
                if(numberOfPreviewAssets > 0) {
                   NSArray<NSDictionary *> *previewAssets = [PHAssetsService assetsArrayToUriArray:[PHAssetsService getAssetsForFetchResult:assets startIndex:0 endIndex:numberOfPreviewAssets] andIncludeMetaData:NO];
                    [albumDictionary setObject:previewAssets forKey:@"previewAssets"];
                }
                
            }
            if(countType == RNPFAssetCountTypeEstimated) {
                NSUInteger estimatedAssetCount = [phAssetCollection estimatedAssetCount];
                if(NSNotFound == estimatedAssetCount) {
                    [albumDictionary setObject:@(-1) forKey:@"assetCount"];
                }else {
                    [albumDictionary setObject:@(estimatedAssetCount) forKey:@"assetCount"];
                }
            }
    NSMutableArray *permittedOperations = [NSMutableArray arrayWithCapacity:7];
    for(int i = 1; i <= 7; i++) {
        [permittedOperations addObject:@([collection canPerformEditOperation:i])];
    }
    [albumDictionary setObject:permittedOperations forKey:@"permittedOperations"];
  return albumDictionary;
}

+(PHFetchResult<PHAsset *> *) getAssetForCollection:(PHAssetCollection *)collection andFetchParams:(NSDictionary *)params {
    PHFetchOptions *options = [PHFetchOptionsService getAssetFetchOptionsFromParams:params];
    return  [PHAsset fetchAssetsInAssetCollection:collection options:options];
}


+(void) createAlbumsWithTitles:(NSArray *)titles andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSArray<NSString *> * localIdentifiers))completeBlock {
    __block NSMutableArray<PHObjectPlaceholder *> *placeholders = [NSMutableArray arrayWithCapacity:titles.count];
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        
        for(int i = 0; i < titles.count; i++) {
            NSString *title = [titles objectAtIndex:i];
            PHAssetCollectionChangeRequest *createAlbum = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
            [placeholders addObject:[createAlbum placeholderForCreatedAssetCollection]];
        }
    } completionHandler:^(BOOL success, NSError *error) {
        NSMutableArray *arrayWithLocalIdentifiers = [NSMutableArray arrayWithCapacity:placeholders.count];
        for(int i = 0; i < placeholders.count; i++) {
            PHObjectPlaceholder *placeHolder = [placeholders objectAtIndex:i];
            [arrayWithLocalIdentifiers addObject:placeHolder.localIdentifier];
        }
        completeBlock(success, error, arrayWithLocalIdentifiers);
    }];
}

+(void) deleteAlbumsWithLocalIdentifers:(NSMutableArray *)localIdentifiers andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock {
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:localIdentifiers options:nil];
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest deleteAssetCollections:collections];
    } completionHandler:^(BOOL success, NSError *error) {
        completeBlock(success, error);
    }];
}

+(void) addAssets:(NSArray<PHAsset *> *)assets toAssetCollection:(PHAssetCollection *)assetCollection andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
        [albumChangeRequest addAssets:assets];
        
    } completionHandler:^(BOOL success, NSError *error) {
        completeBlock(success, error);
    }];
}

+(void) removeAssets:(NSArray<PHAsset *> *)assets fromAssetCollection:(PHAssetCollection *)assetCollection andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
        [albumChangeRequest removeAssets:assets];
        
    } completionHandler:^(BOOL success, NSError *error) {
        completeBlock(success, error);
    }];
}

+(void) saveImage:(UIImage *)image toAlbum:(PHCollection *)album andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSString *__nullable localIdentifier))completeBlock {
    __block PHObjectPlaceholder *placeholder;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        placeholder = [assetRequest placeholderForCreatedAsset];
        
        if(album != nil) {
            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:album];
            [albumChangeRequest addAssets:@[placeholder]];
            
        }
    } completionHandler:^(BOOL success, NSError *error) {
        completeBlock(success, error, placeholder.localIdentifier);
    }];
}



@end
