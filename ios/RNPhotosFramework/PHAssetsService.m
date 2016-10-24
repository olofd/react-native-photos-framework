#import "PHAssetsService.h"
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
#import "PHFetchOptionsService.h"
#import "PHChangeObserver.h"
@import Photos;
@implementation PHAssetsService

+(PHFetchResult<PHAsset *> *) getAssetsForParams:(NSDictionary *)params  {
    NSString * cacheKey = [RCTConvert NSString:params[@"_cacheKey"]];
    NSString * albumLocalIdentifier = [RCTConvert NSString:params[@"albumLocalIdentifier"]];
    if(albumLocalIdentifier == nil){
        return [PHAssetsService getAssetsForParams:params andCacheKey:cacheKey];
    }
    PHFetchOptions *options = [PHFetchOptionsService getFetchOptionsFromParams:[RCTConvert NSDictionary:params[@"fetchOptions"]]];
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumLocalIdentifier] options:options];
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

+(NSArray<NSDictionary *> *) assetsArrayToUriArray:(NSArray<PHAsset *> *)assetsArray {
    NSMutableArray *uriArray = [NSMutableArray arrayWithCapacity:assetsArray.count];
    for(int i = 0;i < assetsArray.count;i++) {
        PHAsset *asset =[assetsArray objectAtIndex:i];
        [uriArray addObject:@{
                              @"localIdentifier" : [asset localIdentifier],
                              @"width" : @([asset pixelWidth]),
                              @"height" : @([asset pixelHeight])
                              }];
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
