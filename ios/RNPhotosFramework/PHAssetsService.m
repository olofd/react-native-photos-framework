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
    PHFetchOptions *options = [PHFetchOptionsService getFetchOptionsFromParams:[RCTConvert NSDictionary:params[@"fetchOptions"]]];
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumLocalIdentifier] options:nil];
    return [PHAsset fetchAssetsInAssetCollection:collections.firstObject options:options];
}

+(PHFetchResult<PHAsset *> *) getAssetsForExplicitAssetsParam:(NSDictionary *)params {
    NSArray *assets = [RCTConvert NSArray:params[@"assets"]];
    NSMutableArray<NSString *> * localIdentifiers = [NSMutableArray arrayWithCapacity:assets.count];
    for(int i = 0; i < assets.count; i++) {
        NSDictionary *asset = [assets objectAtIndex:i];
        [localIdentifiers addObject:[asset objectForKey:@"localIdentifier"]];
    }
    return [PHAsset fetchAssetsWithLocalIdentifiers:localIdentifiers options:nil];
}

+(PHFetchResult<PHAsset *> *) getAssetsForParams:(NSDictionary *)params andCacheKey:(NSString *)cacheKey  {
    if(cacheKey == nil) {
        return [PHAssetsService getAllAssetsForParams:params];
    }
    return [[[PHChangeObserver sharedChangeObserver] getFetchResultFromCacheWithuuid:cacheKey] fetchResult];
}

+(PHFetchResult<PHAsset *> *) getAllAssetsForParams:(NSDictionary *)params {
    PHFetchOptions *options = [PHFetchOptionsService getFetchOptionsFromParams:[RCTConvert NSDictionary:params[@"fetchOptions"]]];
    return [PHAsset fetchAssetsWithOptions:options];
}

+(NSArray<NSDictionary *> *) assetsArrayToUriArray:(NSArray<PHAsset *> *)assetsArray andIncludeMetaData:(BOOL)includeMetaData {
    NSMutableArray *uriArray = [NSMutableArray arrayWithCapacity:assetsArray.count];
    NSDictionary *reveredMediaTypes = [RCTConvert PHAssetMediaTypeValuesReversed];
    for(int i = 0;i < assetsArray.count;i++) {
        PHAsset *asset =[assetsArray objectAtIndex:i];
        NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[asset localIdentifier], @"localIdentifier", @([asset pixelWidth]), @"width", @([asset pixelHeight]), @"height", [reveredMediaTypes objectForKey:@([asset mediaType])], @"mediaType",nil];
        if(includeMetaData) {
            [responseDict setObject:@([PHHelpers getTimeSince1970:[asset creationDate]]) forKey:@"creationDate"];
            [responseDict setObject:@([PHHelpers getTimeSince1970:[asset modificationDate]])forKey:@"modificationDate"];
            [responseDict setObject:[PHHelpers CLLocationToJson:[asset location]] forKey:@"location"];
            [responseDict setObject:[PHHelpers nsOptionsToArray:[asset mediaSubtypes] andBitSize:32 andReversedEnumDict:[RCTConvert PHAssetMediaSubtypeValuesReversed]] forKey:@"mediaSubTypes"];
            [responseDict setObject:@([asset isFavorite]) forKey:@"isFavorite"];
            [responseDict setObject:@([asset isHidden]) forKey:@"isHidden"];
            [responseDict setObject:[PHHelpers nsOptionsToValue:[asset sourceType] andBitSize:32 andReversedEnumDict:[RCTConvert PHAssetSourceTypeValuesReversed]] forKey:@"sourceType"];
            NSString *burstIdentifier = [asset burstIdentifier];
            if(burstIdentifier != nil) {
                [responseDict setObject:burstIdentifier forKey:@"burstIdentifier"];
                [responseDict setObject:@([asset representsBurst]) forKey:@"representsBurst"];
                [responseDict setObject:[PHHelpers nsOptionsToArray:[asset burstSelectionTypes] andBitSize:32 andReversedEnumDict:[RCTConvert PHAssetBurstSelectionTypeValuesReversed]] forKey:@"burstSelectionTypes"];
            }
            if([asset mediaType] == PHAssetMediaTypeVideo || [asset mediaType] == PHAssetMediaTypeAudio) {
                [responseDict setObject:@([asset duration]) forKey:@"duration"];
            }
        }
        
        [uriArray addObject:responseDict];
    }
    return uriArray;
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
