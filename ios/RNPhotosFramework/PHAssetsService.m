#import "PHAssetsService.h"
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
#import "PHFetchOptionsService.h"
#import "PHChangeObserver.h"
#import "PHHelpers.h"
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
@import Photos;
@implementation PHAssetsService

+(PHFetchResult<PHAsset *> *) getAssetsForParams:(NSDictionary *)params  {
    NSString * cacheKey = [RCTConvert NSString:params[@"_cacheKey"]];
    NSString * albumLocalIdentifier = [RCTConvert NSString:params[@"albumLocalIdentifier"]];
    if(albumLocalIdentifier == nil){
        return [PHAssetsService getAssetsForParams:params andCacheKey:cacheKey];
    }
    PHFetchOptions *options = [PHFetchOptionsService getFetchOptionsFromParams:params];
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumLocalIdentifier] options:nil];
    return [PHAsset fetchAssetsInAssetCollection:collections.firstObject options:options];
}

+(PHFetchResult<PHAsset *> *) getAssetsFromArrayOfLocalIdentifiers:(NSArray<NSString *> *)arrayWithLocalIdentifiers {
    return [PHAsset fetchAssetsWithLocalIdentifiers:arrayWithLocalIdentifiers options:nil];
}

+(PHFetchResult<PHAsset *> *) getAssetsForParams:(NSDictionary *)params andCacheKey:(NSString *)cacheKey  {
    if(cacheKey == nil) {
        return [PHAssetsService getAllAssetsForParams:params];
    }
    return [[[PHChangeObserver sharedChangeObserver] getFetchResultFromCacheWithuuid:cacheKey] fetchResult];
}

+(PHFetchResult<PHAsset *> *) getAllAssetsForParams:(NSDictionary *)params {
    PHFetchOptions *options = [PHFetchOptionsService getFetchOptionsFromParams:params];
    return [PHAsset fetchAssetsWithOptions:options];
}

+(NSArray<NSDictionary *> *) assetsArrayToUriArray:(NSArray<PHAsset *> *)assetsArray andIncludeMetaData:(BOOL)includeMetaData {
    NSMutableArray *uriArray = [NSMutableArray arrayWithCapacity:assetsArray.count];
    NSDictionary *reveredMediaTypes = [RCTConvert PHAssetMediaTypeValuesReversed];
    for(int i = 0;i < assetsArray.count;i++) {
        PHAsset *asset =[assetsArray objectAtIndex:i];
        NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[asset localIdentifier], @"localIdentifier", @([asset pixelWidth]), @"width", @([asset pixelHeight]), @"height", [reveredMediaTypes objectForKey:@([asset mediaType])], @"mediaType",nil];
        if(includeMetaData) {
            [self extendAssetDicWithAssetMetaData:responseDict andPHAsset:asset];
        }
        
        [uriArray addObject:responseDict];
    }
    return uriArray;
}

+(NSMutableDictionary *)extendAssetDicWithAssetMetaData:(NSMutableDictionary *)dictToExtend andPHAsset:(PHAsset *)asset {
    [dictToExtend setObject:@([PHHelpers getTimeSince1970:[asset creationDate]]) forKey:@"creationDate"];
    [dictToExtend setObject:@([PHHelpers getTimeSince1970:[asset modificationDate]])forKey:@"modificationDate"];
    [dictToExtend setObject:[PHHelpers CLLocationToJson:[asset location]] forKey:@"location"];
    [dictToExtend setObject:[PHHelpers nsOptionsToArray:[asset mediaSubtypes] andBitSize:32 andReversedEnumDict:[RCTConvert PHAssetMediaSubtypeValuesReversed]] forKey:@"mediaSubTypes"];
    [dictToExtend setObject:@([asset isFavorite]) forKey:@"isFavorite"];
    [dictToExtend setObject:@([asset isHidden]) forKey:@"isHidden"];
    [dictToExtend setObject:[PHHelpers nsOptionsToValue:[asset sourceType] andBitSize:32 andReversedEnumDict:[RCTConvert PHAssetSourceTypeValuesReversed]] forKey:@"sourceType"];
    NSString *burstIdentifier = [asset burstIdentifier];
    if(burstIdentifier != nil) {
        [dictToExtend setObject:burstIdentifier forKey:@"burstIdentifier"];
        [dictToExtend setObject:@([asset representsBurst]) forKey:@"representsBurst"];
        [dictToExtend setObject:[PHHelpers nsOptionsToArray:[asset burstSelectionTypes] andBitSize:32 andReversedEnumDict:[RCTConvert PHAssetBurstSelectionTypeValuesReversed]] forKey:@"burstSelectionTypes"];
    }
    if([asset mediaType] == PHAssetMediaTypeVideo || [asset mediaType] == PHAssetMediaTypeAudio) {
        [dictToExtend setObject:@([asset duration]) forKey:@"duration"];
    }
    return dictToExtend;
}

+(NSMutableArray<PHAsset *> *) getAssetsForFetchResult:(PHFetchResult *)assetsFetchResult startIndex:(NSUInteger)startIndex endIndex:(NSUInteger)endIndex {
    
    NSMutableArray<PHAsset *> *assets = [NSMutableArray new];
    [assetsFetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger index, BOOL *stop) {
        if(index >= endIndex){
            *stop = YES;
            return;
        }
        if(index >= startIndex){
            [assets addObject:asset];
        }
        
    }];
    return assets;
}

@end
