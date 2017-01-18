#import "PHAssetsService.h"
#import <React/RCTConvert.h>
#import "RCTConvert+RNPhotosFramework.h"
#import "PHFetchOptionsService.h"
#import "PHCache.h"
#import "RNPFHelpers.h"
#import <React/RCTConvert.h>
#import "RCTConvert+RNPhotosFramework.h"
#import <React/RCTProfile.h>
#import "PHAssetWithCollectionIndex.h"

@import Photos;
@implementation PHAssetsService

+(PHFetchResult<PHAsset *> *) getAssetsForParams:(NSDictionary *)params  {
    NSString * cacheKey = [RCTConvert NSString:params[@"_cacheKey"]];
    NSString * albumLocalIdentifier = [RCTConvert NSString:params[@"albumLocalIdentifier"]];

    if(cacheKey != nil) {
        PHCachedFetchResult *cachedResultSet = [[PHCache sharedPHCache] getFetchResultFromCacheWithuuid:cacheKey];
        if(cachedResultSet != nil) {
            return [cachedResultSet fetchResult];
        }
    }

    PHFetchResult<PHAsset *> *fetchResult;
    if(albumLocalIdentifier != nil) {
        fetchResult = [self getAssetsForParams:params andAlbumLocalIdentifier:albumLocalIdentifier];
    }
    if(fetchResult == nil) {
        fetchResult = [PHAssetsService getAllAssetsForParams:params];
    }

    if(cacheKey != nil && fetchResult != nil) {
        [[PHCache sharedPHCache] cacheFetchResultWithUUID:fetchResult andObjectType:[PHAsset class] andUUID:cacheKey andOrginalFetchParams:params];
    }

    return fetchResult;
}

+(PHFetchResult<PHAsset *> *)getAssetsForParams:(NSDictionary *)params andAlbumLocalIdentifier:(NSString *)albumLocalIdentifier {
    PHFetchOptions *options = [PHFetchOptionsService getAssetFetchOptionsFromParams:params];
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumLocalIdentifier] options:nil];

    PHFetchResult<PHAsset *> * assets = [PHAsset fetchAssetsInAssetCollection:collections.firstObject options:options];
    return assets;
}

+(PHFetchResult<PHAsset *> *) getAssetsFromArrayOfLocalIdentifiers:(NSArray<NSString *> *)arrayWithLocalIdentifiers {
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.includeHiddenAssets = YES;
    fetchOptions.includeAllBurstAssets = YES;
    return [PHAsset fetchAssetsWithLocalIdentifiers:arrayWithLocalIdentifiers options:fetchOptions];
}

+(PHFetchResult<PHAsset *> *) getAllAssetsForParams:(NSDictionary *)params {
    PHFetchOptions *options = [PHFetchOptionsService getAssetFetchOptionsFromParams:params];
    return [PHAsset fetchAssetsWithOptions:options];
}

+(NSArray<NSDictionary *> *) assetsArrayToUriArray:(NSArray<id> *)assetsArray andincludeMetadata:(BOOL)includeMetadata andIncludeAssetResourcesMetadata:(BOOL)includeResourcesMetadata {
    RCT_PROFILE_BEGIN_EVENT(0, @"-[RCTCameraRollRNPhotosFrameworkManager assetsArrayToUriArray", nil);

    NSMutableArray *uriArray = [NSMutableArray arrayWithCapacity:assetsArray.count];
    NSDictionary *reveredMediaTypes = [RCTConvert PHAssetMediaTypeValuesReversed];
    for(int i = 0;i < assetsArray.count; i++) {
        id assetObj = [assetsArray objectAtIndex:i];
        NSNumber *assetIndex = (NSNumber *)[NSNull null];
        PHAsset *asset;
        if([assetObj isKindOfClass:[PHAsset class]]) {
            asset = assetObj;
        }else {
            PHAssetWithCollectionIndex *assetWithCollectionIndex = assetObj;
            asset = assetWithCollectionIndex.asset;
            assetIndex = assetWithCollectionIndex.collectionIndex;
        }

        NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             [asset localIdentifier], @"localIdentifier",
                                             @([asset pixelWidth]), @"width",
                                             @([asset pixelHeight]), @"height",
                                             [reveredMediaTypes objectForKey:@([asset mediaType])], @"mediaType",
                                             assetIndex, @"collectionIndex",
                                             nil];
        if(includeMetadata) {
            [self extendAssetDictWithAssetMetadata:responseDict andPHAsset:asset];
        }
        if(includeResourcesMetadata) {
            [self extendAssetDictWithAssetResourcesMetadata:responseDict andPHAsset:asset];
        }

        [uriArray addObject:responseDict];
    }
    RCT_PROFILE_END_EVENT(RCTProfileTagAlways, @"");

    return uriArray;
}

+(NSMutableDictionary *)extendAssetDictWithAssetMetadata:(NSMutableDictionary *)dictToExtend andPHAsset:(PHAsset *)asset {

    [dictToExtend setObject:@([RNPFHelpers getTimeSince1970:[asset creationDate]]) forKey:@"creationDateUTCSeconds"];
    [dictToExtend setObject:@([RNPFHelpers getTimeSince1970:[asset modificationDate]])forKey:@"modificationDateUTCSeconds"];
    [dictToExtend setObject:[RNPFHelpers CLLocationToJson:[asset location]] forKey:@"location"];
    [dictToExtend setObject:[RNPFHelpers nsOptionsToArray:[asset mediaSubtypes] andBitSize:32 andReversedEnumDict:[RCTConvert PHAssetMediaSubtypeValuesReversed]] forKey:@"mediaSubTypes"];
    [dictToExtend setObject:@([asset isFavorite]) forKey:@"isFavorite"];
    [dictToExtend setObject:@([asset isHidden]) forKey:@"isHidden"];
    if ([asset respondsToSelector:@selector(sourceType)]) {
        // not available in iOS 8
        [dictToExtend setObject:[RNPFHelpers nsOptionsToValue:[asset sourceType] andBitSize:32 andReversedEnumDict:[RCTConvert PHAssetSourceTypeValuesReversed]] forKey:@"sourceType"];
    }
    NSString *burstIdentifier = [asset burstIdentifier];
    if(burstIdentifier != nil) {
        [dictToExtend setObject:burstIdentifier forKey:@"burstIdentifier"];
        [dictToExtend setObject:@([asset representsBurst]) forKey:@"representsBurst"];
        [dictToExtend setObject:[RNPFHelpers nsOptionsToArray:[asset burstSelectionTypes] andBitSize:32 andReversedEnumDict:[RCTConvert PHAssetBurstSelectionTypeValuesReversed]] forKey:@"burstSelectionTypes"];
    }
    if([asset mediaType] == PHAssetMediaTypeVideo || [asset mediaType] == PHAssetMediaTypeAudio) {
        [dictToExtend setObject:@([asset duration]) forKey:@"duration"];
    }
    return dictToExtend;
}

+(NSMutableDictionary *)extendAssetDictWithAssetResourcesMetadata:(NSMutableDictionary *)dictToExtend andPHAsset:(PHAsset *)asset {

    NSArray<PHAssetResource *> *resources = [PHAssetResource assetResourcesForAsset:asset];
    NSMutableArray *arrayWithResourcesMetadata = [NSMutableArray new];

    for(int i = 0; i < resources.count;i++) {
        PHAssetResource *resourceMetadata = [resources objectAtIndex:i];
        [arrayWithResourcesMetadata addObject:@{
                                                     @"originalFilename" : resourceMetadata.originalFilename,
                                                     @"assetLocalIdentifier" : resourceMetadata.assetLocalIdentifier,
                                                     @"uniformTypeIdentifier" : resourceMetadata.uniformTypeIdentifier,
                                                     @"type" : [[RCTConvert PHAssetResourceTypeValuesReversed] objectForKey:@(resourceMetadata.type)]
                                                     }];
    }

    [dictToExtend setObject:arrayWithResourcesMetadata forKey:@"resourcesMetadata"];

    return dictToExtend;
}

+(void)extendAssetDictWithPhotoAssetEditionMetadata:(NSMutableDictionary *)dictToExtend andPHAsset:(PHAsset *)asset andCompletionBlock:(void(^)(NSMutableDictionary * dict))completeBlock  {
    __block NSMutableDictionary * dictionaryToExtendBlocked = dictToExtend;
    [PHAssetsService requestEditingMetadataWithCompletionBlock:^(NSDictionary<NSString *,id> *dict) {
        [dictionaryToExtendBlocked addEntriesFromDictionary:dict];
        completeBlock(dictionaryToExtendBlocked);
    } andAsset:asset];
}


+(NSMutableArray<PHAssetWithCollectionIndex*> *) getAssetsForFetchResult:(PHFetchResult *)assetsFetchResult startIndex:(int)startIndex endIndex:(int)endIndex assetDisplayStartToEnd:(BOOL)assetDisplayStartToEnd andAssetDisplayBottomUp:(BOOL)assetDisplayBottomUp {

    NSMutableArray<PHAssetWithCollectionIndex *> *assets = [NSMutableArray new];
    int assetCount = (int)assetsFetchResult.count;

    if(assetCount != 0) {

        NSIndexSet *indexSet = [self getIndexSetForAssetEnumerationWithAssetCount:(int)assetsFetchResult.count startIndex:startIndex endIndex:endIndex assetDisplayStartToEnd:assetDisplayStartToEnd];

        NSEnumerationOptions enumerationOptionsStartToEnd = assetDisplayBottomUp ? NSEnumerationReverse : NSEnumerationConcurrent;
        NSEnumerationOptions enumerationOptionsEndToStart = assetDisplayBottomUp ? NSEnumerationConcurrent : NSEnumerationReverse;
        // display assets from the bottom to top of page if assetDisplayBottomUp is true
        NSEnumerationOptions enumerationOptions = assetDisplayStartToEnd ? enumerationOptionsStartToEnd : enumerationOptionsEndToStart;

        [assetsFetchResult enumerateObjectsAtIndexes:indexSet options:enumerationOptions usingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
            [assets addObject:[[PHAssetWithCollectionIndex alloc] initWithAsset:asset andCollectionIndex:@(idx)]];
        }];
    }

    return assets;
}

+(NSMutableArray<PHAssetWithCollectionIndex*> *) getAssetsForFetchResult:(PHFetchResult *)assetsFetchResult atIndecies:(NSArray<NSNumber *> *)indecies {
    NSMutableArray<PHAssetWithCollectionIndex *> *assets = [NSMutableArray new];
    NSUInteger assetCount = assetsFetchResult.count;
    for(int i = 0; i < indecies.count; i++) {
        int collectionIndex = [[indecies objectAtIndex:i] intValue];
        if(collectionIndex <= (assetCount - 1) && collectionIndex >= 0) {
            PHAsset *asset = [assetsFetchResult objectAtIndex:collectionIndex];
            [assets addObject:[[PHAssetWithCollectionIndex alloc] initWithAsset:asset andCollectionIndex:@(collectionIndex)]];

        }
    }
    return assets;
}


+(NSIndexSet *) getIndexSetForAssetEnumerationWithAssetCount:(int)assetCount startIndex:(int)startIndex endIndex:(int)endIndex assetDisplayStartToEnd:(BOOL)assetDisplayStartToEnd {
        int originalStartIndex = startIndex;
        int originalEndIndex = endIndex;
        startIndex = (assetCount - endIndex) - 1;
        endIndex = assetCount - originalStartIndex;
        // load oldest assets from library first if assetDisplayStartToEnd is true
        if(assetDisplayStartToEnd) {
            startIndex = originalStartIndex;
            endIndex = originalEndIndex;
        }
        if(startIndex < 0) {
            startIndex = 0;
        }
        if(endIndex < 0) {
            endIndex = 0;
        }
        if(startIndex >= assetCount) {
            startIndex = assetCount;
        }
        if(endIndex >= assetCount) {
            endIndex = assetCount;
        }
        int indexRangeLength = endIndex - startIndex;
        // adjust range length calculation if original and active index are 0
        if(originalStartIndex == 0 && startIndex == 0){
            indexRangeLength = (endIndex - startIndex) + 1;
        }
        if(indexRangeLength >= assetCount){
            indexRangeLength = assetCount;
        }
        return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, indexRangeLength)];
}

+(void)deleteAssets:(PHFetchResult<PHAsset *> *)assetsToDelete andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSArray<NSString *> * localIdentifiers))completeBlock {
    __block NSMutableArray<NSString *> *deletedAssetsLocalIdentifers = [NSMutableArray arrayWithCapacity:assetsToDelete.count];
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        for(int i = 0; i< assetsToDelete.count; i++) {
            PHAsset *assetToDelete = [assetsToDelete objectAtIndex:i];
            BOOL req = [assetToDelete canPerformEditOperation:PHAssetEditOperationDelete];
            if (req) {
                [deletedAssetsLocalIdentifers addObject:assetToDelete.localIdentifier];
                [PHAssetChangeRequest deleteAssets:@[assetToDelete]];
            }
        }
    } completionHandler:^(BOOL success, NSError *error) {
        completeBlock(success, error, deletedAssetsLocalIdentifers);
    }];
}

+(void)requestEditingMetadataWithCompletionBlock:(void(^)(NSDictionary<NSString *,id> * dict))completeBlock andAsset:(PHAsset *)asset{
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = YES;
    options.synchronous = NO;
    options.version = PHImageRequestOptionsVersionOriginal;
    PHImageManager *manager = [[PHImageManager alloc] init];
    [manager requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info){
        CIImage *image = [CIImage imageWithData:imageData];
        completeBlock(image.properties);
    }];
}

+(void)updateAssetWithParams:(NSDictionary *)params completionBlock:(void(^)(BOOL success, NSError * _Nullable error, NSString * _Nullable localIdentifier))completionBlock andAsset:(PHAsset *)asset {
    if(!params || !asset) {
        return completionBlock(NO, [NSError errorWithDomain:@"react-native-photos-framework" code:1 userInfo:@{@"info" : @"[updateAssetWithParams] params or asset was nil"}], asset.localIdentifier);
    }
    BOOL runUpdate = NO;
    BOOL updateHidden = NO;
    BOOL updateFavorite = NO;
    BOOL updateCreationDate = NO;
    BOOL updateLocation = NO;
    
    NSString *hiddenValue = [params objectForKey:@"hidden"];
    BOOL hidden = false;
    if(hiddenValue) {
        hidden = [RCTConvert BOOL:params[@"hidden"]];
        if(hidden != asset.hidden) {
            runUpdate = YES;
            updateHidden = YES;
        }
    }
    
    NSString *favoriteValue = [params objectForKey:@"favorite"];
    BOOL favorite = false;
    if(favoriteValue) {
        favorite = [RCTConvert BOOL:params[@"favorite"]];
        if(favorite != asset.favorite) {
            runUpdate = YES;
            updateFavorite = YES;
        }
    }
    
    
    NSString *creationDateValue = [params objectForKey:@"creationDate"];
    NSDate *creationDate = asset.creationDate;
    if(creationDateValue) {
        creationDate = [RCTConvert NSDate:creationDateValue];
        if(creationDate) {
            runUpdate = YES;
            updateCreationDate = YES;
        }
    }
    
    NSDictionary *locationValue = [RCTConvert NSDictionary:params[@"location"]];
    CLLocation *location = asset.location;
    if(locationValue) {
        location = [RCTConvert CLLocation:locationValue];
        if(location) {
            runUpdate = YES;
            updateLocation = YES;
        }
    }
    if(!runUpdate) {
        return completionBlock(YES, nil, asset.localIdentifier);
    }
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest changeRequestForAsset:asset];
        if(updateHidden) {
            assetRequest.hidden = hidden;
        }
        if(updateFavorite) {
            assetRequest.favorite = favorite;
        }
        if(updateCreationDate) {
            assetRequest.creationDate = creationDate;
        }
        if(updateLocation) {
            assetRequest.location = location;
        }
    } completionHandler:^(BOOL success, NSError *error) {
        completionBlock(success, error, asset.localIdentifier);
    }];
}

@end
