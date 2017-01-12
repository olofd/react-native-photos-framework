#import "PHCollectionService.h"
#import <React/RCTConvert.h>
#import "RCTConvert+RNPhotosFramework.h"
#import "PHFetchOptionsService.h"
#import "PHCache.h"
#import <React/RCTConvert.h>
#import "RCTConvert+RNPhotosFramework.h"
#import "RNPFHelpers.h"
#import <React/RCTImageLoader.h>
#import "PHAssetsService.h"

@import Photos;
@implementation PHCollectionService

static id ObjectOrNull(id object)
{
    return object ?: [NSNull null];
}

+(PHAssetCollection *) getAssetCollectionForParams:(NSDictionary *)params {
    NSString * albumLocalIdentifier = [RCTConvert NSString:params[@"albumLocalIdentifier"]];
    if(albumLocalIdentifier) {
        return [self getAssetForLocalIdentifer:albumLocalIdentifier];
    }
    [NSException raise:@"RNPhotosFramework invalid argument" format:@"You need to pass albumLocalIdentifier to retrive a specific album for this operation"];
    return nil;
}

+(PHAssetCollection *) getAssetForLocalIdentifer:(NSString *)localIdentifier {
    if(localIdentifier == nil) {
        return nil;
    }
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[localIdentifier] options:nil];
    return collections.firstObject;
}

+(PHFetchResult<PHAssetCollection *> *)getAlbumsWithLocalIdentifiers:(NSArray<NSString *> *)localIdentifiers andParams:(NSDictionary * __nullable)params{
    PHFetchOptions *fetchOptions = [PHFetchOptionsService getCollectionFetchOptionsFromParams:params];
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:localIdentifiers options:fetchOptions];
}

+(NSMutableDictionary *) getAlbums:(NSDictionary *)params {
    PHFetchResult<PHCollection *> *albums = [PHCollectionService getAlbumsWithParams:params];
    return [PHCollectionService generateCollectionResponseWithCollections:albums andParams:params];
}

+(PHFetchResult<PHCollection *> *)getAlbumsWithParams:(NSDictionary *)params {
    NSString * typeString = params[@"type"];
    NSString * subTypeString = params[@"subType"];
    if(typeString == nil && subTypeString == nil) {
        return [PHCollectionService getTopUserAlbums:params];
    }
    PHAssetCollectionType type = [RCTConvert PHAssetCollectionType:typeString];
    PHAssetCollectionSubtype subType = [RCTConvert PHAssetCollectionSubtype:subTypeString];
    PHFetchOptions *options = [PHFetchOptionsService getCollectionFetchOptionsFromParams:params];
    PHFetchResult<PHCollection *> *albums = (PHFetchResult<PHCollection *> *)[PHAssetCollection fetchAssetCollectionsWithType:type subtype:subType options:options];
    return albums;
}

+(PHFetchResult<PHCollection *> *)getTopUserAlbums:(NSDictionary *)params
{
    PHFetchOptions *options = [PHFetchOptionsService getCollectionFetchOptionsFromParams:params];
    PHFetchResult<PHCollection *> *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:options];
    return topLevelUserCollections;
}

+(PHFetchResult<PHAssetCollection *> *)getUserAlbumsByTitles:(NSArray *)titles withParams:(NSDictionary *)params {
    PHFetchOptions *fetchOptions = [PHFetchOptionsService getCollectionFetchOptionsFromParams:params];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"title in %@", titles];
    NSString * typeString = params[@"type"];
    NSString * subTypeString = params[@"subType"];
    PHAssetCollectionType type = [RCTConvert PHAssetCollectionType:typeString];
    PHAssetCollectionSubtype subType = [RCTConvert PHAssetCollectionSubtype:subTypeString];
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:type
                                                                              subtype:subType
                                                                              options:fetchOptions];
    return collections;
}


+(NSMutableDictionary *) generateCollectionResponseWithCollections:(PHFetchResult<PHCollection *> *)collections andParams:(NSDictionary *)params {
    BOOL trackInsertsAndDeletes = [RCTConvert BOOL:params[@"trackInsertsAndDeletes"]];
    BOOL trackChanges = [RCTConvert BOOL:params[@"trackChanges"]];
    BOOL preCacheAssets = [RCTConvert BOOL:params[@"preCacheAssets"]];
    BOOL shouldCache = trackInsertsAndDeletes || trackChanges;
    
    NSMutableDictionary *multipleAlbumsResponse = [PHCollectionService generateAlbumsResponseFromParams:params andAlbums:collections andCacheAssets:preCacheAssets];
    if(shouldCache) {
        NSString *uuid = [[PHCache sharedPHCache] cacheFetchResultAndReturnUUID:collections andObjectType:[PHAssetCollection class] andOrginalFetchParams:params];
        [multipleAlbumsResponse setObject:uuid forKey:@"_cacheKey"];
    }
    return multipleAlbumsResponse;
}

+(NSMutableDictionary *)generateAlbumsResponseFromParams:(NSDictionary *)params andAlbums:(PHFetchResult<PHCollection *> *)albums andCacheAssets:(BOOL)cacheAssets {
    
    RNPFAssetCountType countType = [RCTConvert RNPFAssetCountType:params[@"assetCount"]];
    int numberOfPreviewAssets = [RCTConvert int:params[@"previewAssets"]];
    BOOL includeMetadata = [RCTConvert BOOL:params[@"includeMetadata"]];
    BOOL includeResourcesMetadata = [RCTConvert BOOL:params[@"includeResourcesMetadata"]];

    NSMutableDictionary *collectionDictionary = [NSMutableDictionary new];
    NSMutableArray *albumsArray = [NSMutableArray arrayWithCapacity:albums.count];
    
    //We are going to fetch only for preview items.
    //Let's set a fetchLimit.
    NSDictionary *fetchOptions = [RCTConvert NSDictionary:params[@"assetFetchOptions"]];
    NSMutableDictionary *assetFetchParams = [[NSMutableDictionary alloc] init];

    if(!cacheAssets && countType == RNPFAssetCountTypeEstimated && numberOfPreviewAssets > 0) {
        //If we are not caching the result and the assetCount should only be estimated.
        //We can set a fetchLimit when getting the previewAssets (Small optimization)
        NSMutableDictionary *fetchOptionsMutable = [fetchOptions mutableCopy];
        [fetchOptionsMutable setObject:@(numberOfPreviewAssets) forKey:@"fetchLimit"];
        fetchOptions = fetchOptionsMutable;
    }
    if(fetchOptions) {
        [assetFetchParams setObject:fetchOptions forKey:@"fetchOptions"];
    }
    
    
    for(PHCollection *collection in albums)
    {
        NSMutableDictionary *albumDictionary = [self generateAlbumResponseFromCollection:collection numberOfPreviewAssets:numberOfPreviewAssets countType:countType includeMetadata:includeMetadata includeResourcesMetadata:includeResourcesMetadata cacheAssets:cacheAssets assetFetchParams:assetFetchParams];
            
        [albumsArray addObject:albumDictionary];
        
    }
    [collectionDictionary setObject:albumsArray forKey:@"albums"];
    return collectionDictionary;
}

+ (NSMutableDictionary *)generateAlbumResponseFromCollection:(PHCollection *)collection numberOfPreviewAssets:(int)numberOfPreviewAssets countType:(RNPFAssetCountType)countType includeMetadata:(BOOL)includeMetadata includeResourcesMetadata:(BOOL)resourcesMetadata cacheAssets:(BOOL)cacheAssets assetFetchParams:(NSDictionary *)assetFetchParams {
    
    NSMutableDictionary *albumDictionary = [NSMutableDictionary new];

    if([collection isKindOfClass:[PHAssetCollection class]]) {
        PHAssetCollection *phAssetCollection = (PHAssetCollection *)collection;
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
        if(includeMetadata) {
            [albumDictionary setObject:@([RNPFHelpers getTimeSince1970:phAssetCollection.startDate])forKey:@"startDate"];
            [albumDictionary setObject:@([RNPFHelpers getTimeSince1970:phAssetCollection.endDate]) forKey:@"endDate"];
            [albumDictionary setObject:[RNPFHelpers CLLocationToJson:phAssetCollection.approximateLocation] forKey:@"approximateLocation"];
            [albumDictionary setObject:ObjectOrNull(phAssetCollection.localizedLocationNames) forKey:@"localizedLocationNames"];
        }
        if(countType == RNPFAssetCountTypeEstimated) {
            NSUInteger estimatedAssetCount = [phAssetCollection estimatedAssetCount];
            if(NSNotFound == estimatedAssetCount) {
                [albumDictionary setObject:@(-1) forKey:@"assetCount"];
            }else {
                [albumDictionary setObject:@(estimatedAssetCount) forKey:@"assetCount"];
            }
        }
        
        if(cacheAssets || numberOfPreviewAssets > 0 || countType == RNPFAssetCountTypeExact) {
            
            PHFetchResult<PHAsset *> * assets = [PHCollectionService getAssetForCollection:phAssetCollection andFetchParams:assetFetchParams];
            
            if(cacheAssets) {
                NSString *uuid = [[PHCache sharedPHCache] cacheFetchResultAndReturnUUID:assets andObjectType:[PHAsset class] andOrginalFetchParams:assetFetchParams];
                [albumDictionary setObject:uuid forKey:@"_cacheKey"];
            }
            
            if(countType == RNPFAssetCountTypeExact) {
                [albumDictionary setObject:@(assets.count) forKey:@"assetCount"];
            }
            
            if(numberOfPreviewAssets > 0) {
                BOOL assetDisplayStartToEnd = [RCTConvert BOOL:assetFetchParams[@"assetDisplayStartToEnd"]];
                BOOL assetDisplayBottomUp = [RCTConvert BOOL:assetFetchParams[@"assetDisplayBottomUp"]];
                NSArray<NSDictionary *> *previewAssets = [PHAssetsService assetsArrayToUriArray:[PHAssetsService getAssetsForFetchResult:assets startIndex:0 endIndex:(numberOfPreviewAssets-1) assetDisplayStartToEnd:assetDisplayStartToEnd andAssetDisplayBottomUp:assetDisplayBottomUp] andincludeMetadata:NO andIncludeAssetResourcesMetadata:resourcesMetadata];
                [albumDictionary setObject:previewAssets forKey:@"previewAssets"];
            }
            
        }
    }

    [albumDictionary setObject:collection.localizedTitle forKey:@"title"];
    [albumDictionary setObject:collection.localIdentifier forKey:@"localIdentifier"];
    
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

+(void) deleteAlbumsWithLocalIdentifers:(NSArray *)localIdentifiers andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock {
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:localIdentifiers options:nil];
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest deleteAssetCollections:collections];
    } completionHandler:^(BOOL success, NSError *error) {
        completeBlock(success, error);
    }];
}

+(void) addAssets:(PHFetchResult<PHAsset *> *)assets toAssetCollection:(PHAssetCollection *)assetCollection andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
        [albumChangeRequest addAssets:assets];
        
    } completionHandler:^(BOOL success, NSError *error) {
        completeBlock(success, error);
    }];
}

+(void) removeAssets:(PHFetchResult<PHAsset *> *)assets fromAssetCollection:(PHAssetCollection *)assetCollection andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
        [albumChangeRequest removeAssets:assets];
        
    } completionHandler:^(BOOL success, NSError *error) {
        completeBlock(success, error);
    }];
}

+(void) saveImage:(UIImage *)image toAlbum:(NSString *)albumLocalIdentfier andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSString *__nullable localIdentifier))completeBlock {
    __block PHObjectPlaceholder *placeholder;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        placeholder = [assetRequest placeholderForCreatedAsset];
        
        if(albumLocalIdentfier != nil) {
            PHAssetCollection *album = [PHCollectionService getAssetForLocalIdentifer:albumLocalIdentfier];
            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:album];
            [albumChangeRequest addAssets:@[placeholder]];
            
        }
    } completionHandler:^(BOOL success, NSError *error) {
        completeBlock(success, error, placeholder.localIdentifier);
    }];
}



@end
