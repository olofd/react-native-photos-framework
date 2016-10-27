#import "PHCollectionService.h"
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
#import "PHFetchOptionsService.h"
#import "PHChangeObserver.h"
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
#import "PHHelpers.h"
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
        PHFetchOptions *options = [PHFetchOptionsService getFetchOptionsFromParams:params];
        PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumLocalIdentifier] options:options];
        return collections.firstObject;
    }
    return [[[PHChangeObserver sharedChangeObserver] getFetchResultFromCacheWithuuid:cacheKey] fetchResult];
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
    PHFetchOptions *options = [PHFetchOptionsService getFetchOptionsFromParams:params];
    PHFetchResult<PHAssetCollection *> *albums = [PHAssetCollection fetchAssetCollectionsWithType:type subtype:subType options:options];
    return albums;
}

+(PHFetchResult<PHAssetCollection *> *)getTopUserAlbums:(NSDictionary *)params
{
    PHFetchOptions *options = [PHFetchOptionsService getFetchOptionsFromParams:params];
    PHFetchResult<PHAssetCollection *> *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:options];
    return topLevelUserCollections;
}

+(PHFetchResult<PHAssetCollection *> *)getUserAlbumsByTitles:(NSArray *)titles withParams:(NSDictionary *)params {
    PHFetchOptions *fetchOptions = [PHFetchOptionsService getFetchOptionsFromParams:params];
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
        NSString *uuid = [[PHChangeObserver sharedChangeObserver] cacheFetchResultAndReturnUUID:collections andObjectType:[PHAssetCollection class]];
        [multipleAlbumsResponse setObject:uuid forKey:@"_cacheKey"];
    }
    return multipleAlbumsResponse;
}

+(NSMutableDictionary *)generateAlbumsResponseFromParams:(NSDictionary *)params andAlbums:(PHFetchResult<PHAssetCollection *> *)albums andCacheAssets:(BOOL)cacheAssets {
    
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
            PHAssetCollection *phAssetCollection = (PHAssetCollection *)collection;
            NSMutableDictionary *albumDictionary = [NSMutableDictionary new];
            
            [albumDictionary setObject:[[RCTConvert PHAssetCollectionTypeValuesReversed] objectForKey:@([phAssetCollection assetCollectionType])] forKey:@"type"];
            [albumDictionary setObject:[[RCTConvert PHAssetCollectionSubtypeValuesReversed] objectForKey:@([phAssetCollection assetCollectionSubtype])] forKey:@"subType"];

            [albumDictionary setObject:phAssetCollection.localizedTitle forKey:@"title"];
            [albumDictionary setObject:phAssetCollection.localIdentifier forKey:@"localIdentifier"];
            
            BOOL * includeMetaData =  [RCTConvert BOOL:params[@"includeMetaData"]];
            if(includeMetaData) {
                [albumDictionary setObject:@([PHHelpers getTimeSince1970:phAssetCollection.startDate])forKey:@"startDate"];
                [albumDictionary setObject:@([PHHelpers getTimeSince1970:phAssetCollection.endDate]) forKey:@"endDate"];
                [albumDictionary setObject:[PHHelpers CLLocationToJson:phAssetCollection.approximateLocation] forKey:@"approximateLocation"];
                [albumDictionary setObject:ObjectOrNull(phAssetCollection.localizedLocationNames) forKey:@"localizedLocationNames"];
            }

            if(cacheAssets || countType == RNPFAssetCountTypeExact) {
                PHFetchResult<PHAsset *> * assets = [PHCollectionService getAssetForCollection:collection andFetchParams:params];
                [albumDictionary setObject:@(assets.count) forKey:@"assetCount"];
                if(cacheAssets) {
                    NSString *uuid = [[PHChangeObserver sharedChangeObserver] cacheFetchResultAndReturnUUID:assets andObjectType:[PHAsset class]];
                    [albumDictionary setObject:uuid forKey:@"_cacheKey"];
                }
                
            }else if(countType == RNPFAssetCountTypeEstimated) {
                [albumDictionary setObject:@([phAssetCollection estimatedAssetCount]) forKey:@"assetCount"];
            }
            
            [albumsArray addObject:albumDictionary];
        }
    }
    [collectionDictionary setObject:albumsArray forKey:@"albums"];
    return collectionDictionary;
}

+(PHFetchResult<PHAsset *> *) getAssetForCollection:(PHAssetCollection *)collection andFetchParams:(NSDictionary *)params {
    PHFetchOptions *options = [PHFetchOptionsService getFetchOptionsFromParams:params];
    return  [PHAsset fetchAssetsInAssetCollection:collection options:options];
}

/*+(void)saveImage:(NSURLRequest *)request
            type:(NSString *)type
    toCollection:(PHFetchResult<PHAssetCollection *> *)collection
andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSString *__nullable localIdentifier))completeBlock {
    if ([type isEqualToString:@"video"]) {
        // It's unclear if thread-safe
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSException raise:@"Not implementeted exception" format:@"Sry"];
            
        });
    } else {
        [_bridge.imageLoader loadImageWithURLRequest:request
                                            callback:^(NSError *loadError, UIImage *loadedImage) {
                                                if (loadError) {
                                                    completeBlock(NO, loadError, nil);
                                                    return;
                                                }
                                                // It's unclear if writeImageToSavedPhotosAlbum is thread-safe
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [self saveImage:loadedImage toAlbum:collection andCompleteBLock:^(BOOL success, NSError * _Nullable error, NSString * _Nullable localIdentifier) {
                                                        completeBlock(success, error, localIdentifier);
                                                    }];
                                                });
                                            }];
    }
}*/

+(void) createAlbumsWithTitles:(NSArray *)titles andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSArray<NSString *> * localIdentifier))completeBlock {
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
        PHFetchResult *photosAsset;
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        placeholder = [assetRequest placeholderForCreatedAsset];
        photosAsset = [PHAsset fetchAssetsInAssetCollection:album options:nil];
        PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:album assets:photosAsset];
        [albumChangeRequest addAssets:@[placeholder]];
        
    } completionHandler:^(BOOL success, NSError *error) {
        completeBlock(success, error, placeholder.localIdentifier);
    }];
}



@end
