#import "PHAssetsService.h"
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
#import "PHFetchOptionsService.h"
#import "PHChangeObserver.h"
#import "PHHelpers.h"
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
#import "RCTProfile.h"

@import Photos;
@implementation PHAssetsService

+(PHFetchResult<PHAsset *> *) getAssetsForParams:(NSDictionary *)params  {
    NSString * cacheKey = [RCTConvert NSString:params[@"_cacheKey"]];
    NSString * albumLocalIdentifier = [RCTConvert NSString:params[@"albumLocalIdentifier"]];
    
    if(cacheKey != nil) {
        RCTCachedFetchResult *cachedResultSet = [[PHChangeObserver sharedChangeObserver] getFetchResultFromCacheWithuuid:cacheKey];
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
        [[PHChangeObserver sharedChangeObserver] cacheFetchResultWithUUID:fetchResult andObjectType:[PHAsset class] andUUID:cacheKey andOrginalFetchParams:params];
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
    return [PHAsset fetchAssetsWithLocalIdentifiers:arrayWithLocalIdentifiers options:nil];
}

+(PHFetchResult<PHAsset *> *) getAllAssetsForParams:(NSDictionary *)params {
    PHFetchOptions *options = [PHFetchOptionsService getAssetFetchOptionsFromParams:params];
    return [PHAsset fetchAssetsWithOptions:options];
}

+(NSArray<NSDictionary *> *) assetsArrayToUriArray:(NSArray<PHAsset *> *)assetsArray andIncludeMetaData:(BOOL)includeMetaData {
    RCT_PROFILE_BEGIN_EVENT(0, @"-[RCTCameraRollRNPhotosFrameworkManager assetsArrayToUriArray", nil);

    NSMutableArray *uriArray = [NSMutableArray arrayWithCapacity:assetsArray.count];
    NSDictionary *reveredMediaTypes = [RCTConvert PHAssetMediaTypeValuesReversed];
    for(int i = 0;i < assetsArray.count; i++) {
        PHAsset *asset = [assetsArray objectAtIndex:i];
        NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[asset localIdentifier], @"localIdentifier", @([asset pixelWidth]), @"width", @([asset pixelHeight]), @"height", [reveredMediaTypes objectForKey:@([asset mediaType])], @"mediaType", nil];
        if(includeMetaData) {
            [self extendAssetDicWithAssetMetaData:responseDict andPHAsset:asset];
        }
        
        [uriArray addObject:responseDict];
    }
    RCT_PROFILE_END_EVENT(RCTProfileTagAlways, @"");

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
        if(index >= startIndex){
            [assets addObject:asset];
        }
        if(index >= endIndex){
            *stop = YES;
            return;
        }
        
    }];
    return assets;
}

+(void)deleteAssets:(NSArray<PHAsset *> *)assetsToDelete andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSArray<NSString *> * localIdentifiers))completeBlock {
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
        PHContentEditingInputRequestOptions *editOptions = [[PHContentEditingInputRequestOptions alloc]init];
        editOptions.networkAccessAllowed = YES;
        [asset requestContentEditingInputWithOptions:editOptions completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
            CIImage *image = [CIImage imageWithContentsOfURL:contentEditingInput.fullSizeImageURL];
            completeBlock(image.properties);
        }];
}

-(void)requestImageDataWithCompletionBlockAndAsset:(PHAsset *)asset {
    PHImageRequestOptions * imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.networkAccessAllowed = YES;
    [[PHImageManager defaultManager]
     requestImageDataForAsset:asset
     options:imageRequestOptions
     resultHandler:^(NSData *imageData, NSString *dataUTI,
                     UIImageOrientation orientation,
                     NSDictionary *info)
     {
         NSLog(@"info = %@", info);
         if ([info objectForKey:@"PHImageFileURLKey"]) {
             // path looks like this -
             // file:///var/mobile/Media/DCIM/###APPLE/IMG_####.JPG
             NSURL *path = [info objectForKey:@"PHImageFileURLKey"];
         }
     }];
}

+(void)updateLocation:(CLLocation*)location creationDate:(NSDate*)creationDate completionBlock:(void(^)(BOOL success))completionBlock andAsset:(PHAsset *)asset {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest changeRequestForAsset:asset];
        if(location) assetRequest.location = location;
        if(creationDate) assetRequest.creationDate = creationDate;
    } completionHandler:^(BOOL success, NSError *error) {
        if(success){
            completionBlock(YES);
        } else {
            completionBlock(NO);
        }
    }];
}


/*+(void)saveImageToCameraRoll:(UIImage*)image location:(CLLocation*)location completionBlock:(PHAssetAssetBoolBlock)completionBlock{
    __block PHObjectPlaceholder *placeholderAsset = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *newAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        newAssetRequest.location = location;
        newAssetRequest.creationDate = [NSDate date];
        placeholderAsset = newAssetRequest.placeholderForCreatedAsset;
    } completionHandler:^(BOOL success, NSError *error) {
        if(success){
            PHAsset *asset = [self getAssetFromlocalIdentifier:placeholderAsset.localIdentifier];
            completionBlock(asset, YES);
        } else {
            completionBlock(nil, NO);
        }
    }];
}

+(void)saveVideoAtURL:(NSURL*)url location:(CLLocation*)location completionBlock:(PHAssetAssetBoolBlock)completionBlock{
    __block PHObjectPlaceholder *placeholderAsset = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *newAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
        newAssetRequest.location = location;
        newAssetRequest.creationDate = [NSDate date];
        placeholderAsset = newAssetRequest.placeholderForCreatedAsset;
    } completionHandler:^(BOOL success, NSError *error) {
        if(success){
            PHAsset *asset = [self getAssetFromlocalIdentifier:placeholderAsset.localIdentifier];
            completionBlock(asset, YES);
        } else {
            completionBlock(nil, NO);
        }
    }];
}*/

@end
