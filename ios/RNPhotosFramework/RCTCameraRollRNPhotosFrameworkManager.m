#import "RCTCameraRollRNPhotosFrameworkManager.h"
#import "PHCachingImageManagerInstance.h"
#import <React/RCTConvert.h>
#import <React/RCTImageLoader.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import "RCTConvert+RNPhotosFramework.h"
#import "PHChangeObserver.h"
#import "PHFetchOptionsService.h"
#import "PHAssetsService.h"
#import "PHCollectionService.h"
#import "RCTCachedFetchResult.h"
#import <React/RCTProfile.h>
#import "PHSaveAssetRequest.h"
#import "PHHelpers.h"
@import Photos;

@implementation RCTCameraRollRNPhotosFrameworkManager
RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;
NSString *const RNPHotoFrameworkErrorUnableToLoad = @"RNPHOTOSFRAMEWORK_UNABLE_TO_LOAD";
NSString *const RNPHotoFrameworkErrorUnableToSave = @"RNPHOTOSFRAMEWORK_UNABLE_TO_SAVE";

- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.facebook.React.ReactNaticePhotosFramework", DISPATCH_QUEUE_SERIAL);
}

RCT_EXPORT_METHOD(authorizationStatus:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    resolve(@{
              @"status" : [[RCTConvert PHAuthorizationStatusValuesReversed] objectForKey:@(status)],
              @"isAuthorized" : @((BOOL)(status == PHAuthorizationStatusAuthorized))
            });
}

RCT_EXPORT_METHOD(requestAuthorization:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        resolve(@{
                  @"status" : [[RCTConvert PHAuthorizationStatusValuesReversed] objectForKey:@(status)],
                  @"isAuthorized" : @((BOOL)(status == PHAuthorizationStatusAuthorized))
                  });
    }];
}


RCT_EXPORT_METHOD(getAssets:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    RCT_PROFILE_BEGIN_EVENT(0, @"-[RCTCameraRollRNPhotosFrameworkManager getAssets", nil);
    
    PHFetchResult<PHAsset *> *assetsFetchResult = [PHAssetsService getAssetsForParams:params];
    
    NSString *startIndexParam = params[@"startIndex"];
    NSString *endIndexParam = params[@"endIndex"];
    BOOL includeMetadata = [RCTConvert BOOL:params[@"includeMetadata"]];
    BOOL includeResourcesMetadata = [RCTConvert BOOL:params[@"includeResourcesMetadata"]];

    
    int startIndex = [RCTConvert int:startIndexParam];
    int endIndex = endIndexParam != nil ? [RCTConvert int:endIndexParam] : (int)(assetsFetchResult.count -1);
    
    BOOL assetDisplayStartToEnd = [RCTConvert BOOL:params[@"assetDisplayStartToEnd"]];
    BOOL assetDisplayBottomUp = [RCTConvert BOOL:params[@"assetDisplayBottomUp"]];
    NSArray<PHAssetWithCollectionIndex *> *assets = [PHAssetsService getAssetsForFetchResult:assetsFetchResult startIndex:startIndex endIndex:endIndex assetDisplayStartToEnd:assetDisplayStartToEnd andAssetDisplayBottomUp:assetDisplayBottomUp];
    [self prepareAssetsForDisplayWithParams:params andAssets:assets];
    NSInteger assetCount = assetsFetchResult.count;
    BOOL includesLastAsset = assetCount == 0 || endIndex >= (assetCount -1);
    resolve(@{
              @"assets" : [PHAssetsService assetsArrayToUriArray:assets andincludeMetadata:includeMetadata andIncludeAssetResourcesMetadata:includeResourcesMetadata],
              @"includesLastAsset" : @(includesLastAsset)
              });
    RCT_PROFILE_END_EVENT(RCTProfileTagAlways, @"");
}

RCT_EXPORT_METHOD(getAssetsWithIndecies:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    BOOL includeMetadata = [RCTConvert BOOL:params[@"includeMetadata"]];
    BOOL includeResourcesMetadata = [RCTConvert BOOL:params[@"includeResourcesMetadata"]];

    PHFetchResult<PHAsset *> *assetsFetchResult = [PHAssetsService getAssetsForParams:params];
    NSArray<PHAssetWithCollectionIndex *> *assets = [PHAssetsService getAssetsForFetchResult:assetsFetchResult atIndecies:[RCTConvert NSArray:params[@"indecies"]]];
    [self prepareAssetsForDisplayWithParams:params andAssets:assets];
    resolve(@{
              @"assets" : [PHAssetsService assetsArrayToUriArray:assets andincludeMetadata:includeMetadata andIncludeAssetResourcesMetadata:includeResourcesMetadata],
              });
}


RCT_EXPORT_METHOD(cleanCache:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    [[PHChangeObserver sharedChangeObserver] cleanCache];
    resolve(@{ @"success" : @((BOOL)YES) });
}


RCT_EXPORT_METHOD(updateAlbumTitle:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHAssetCollection *collection = [PHCollectionService getAssetCollectionForParams:params];
    NSString *newTitle = [RCTConvert NSString:params[@"newTitle"]];
    if(newTitle == nil) {
        return reject(@"You have to provide newTitle-prop to rename album", nil, nil);
    }
    if (![collection canPerformEditOperation:PHCollectionEditOperationRename]) {
        return reject(@"Can't PerformEditOperation", nil, nil);
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCollectionChangeRequest *changeTitlerequest =[PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
        changeTitlerequest.title = newTitle;
        
    } completionHandler:^(BOOL success, NSError *error) {
        if(success) {
            return resolve(@{ @"success" : @(success) });
        }else {
            return reject(@"Error updating title", nil, error);
        }
    }];
}


RCT_EXPORT_METHOD(addAssetsToAlbum:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHAssetCollection *assetCollection = [PHCollectionService getAssetCollectionForParams:params];
    PHFetchResult<PHAsset *> *fetchedAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:[RCTConvert NSArray:params[@"assets"]]];
    [PHCollectionService addAssets:fetchedAssets toAssetCollection:assetCollection andCompleteBLock:^(BOOL success, NSError * _Nullable error) {
        if(success) {
            return resolve(@{ @"success" : @(success) });
        }else {
            return reject(@"Error adding assets to album", nil, error);
        }
        
    }];
}

RCT_EXPORT_METHOD(removeAssetsFromAlbum:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHAssetCollection *assetCollection = [PHCollectionService getAssetCollectionForParams:params];
    PHFetchResult<PHAsset *> *fetchedAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:[RCTConvert NSArray:params[@"assets"]]];
    [PHCollectionService removeAssets:fetchedAssets fromAssetCollection:assetCollection andCompleteBLock:^(BOOL success, NSError * _Nullable error) {
        if(success) {
            return resolve(@{ @"success" : @(success) });
        }else {
            return reject(@"Error removing assets from album", nil, error);
        }

    }];
}

RCT_EXPORT_METHOD(getAlbums:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    return resolve([PHCollectionService getAlbums:params]);
}

RCT_EXPORT_METHOD(stopTracking:(NSString *)cacheKey
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    if(cacheKey != nil) {
        [[PHChangeObserver sharedChangeObserver] removeFetchResultFromCacheWithUUID:cacheKey];
    }
    return resolve(@{@"success" : @(YES)});
}

RCT_EXPORT_METHOD(getAlbumsMany:(NSArray *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSMutableArray *responseArray = [NSMutableArray new];
    for(int i = 0; i < params.count;i++) {
        NSDictionary *albumsQuery = [params objectAtIndex:i];
        [responseArray addObject:[PHCollectionService getAlbums:albumsQuery]];
    }
    return resolve(responseArray);
}

RCT_EXPORT_METHOD(getAlbumsByTitles:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSArray * albumTitles = [RCTConvert NSArray:params[@"albumTitles"]];
    if(albumTitles == nil) {
        return reject(@"albumTitles cannot be null", nil, nil);
    }
    PHFetchResult<PHAssetCollection *> * collections = [PHCollectionService getUserAlbumsByTitles:albumTitles withParams:params];
    resolve([PHCollectionService generateCollectionResponseWithCollections:(PHFetchResult<PHCollection *> *)collections andParams:params]);
}

RCT_EXPORT_METHOD(createAlbums:(NSArray *)albumTitles
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    if(albumTitles == nil) {
        return reject(@"input array with album-names array<string> cannot be null", nil, nil);
    }
    
    if(albumTitles.count == 0) {
        return resolve(@[]);
    }
    
    [PHCollectionService createAlbumsWithTitles:albumTitles andCompleteBLock:^(BOOL success, NSError * _Nullable error, NSArray<NSString *> *localIdentifiers) {
        if(success) {
            PHFetchResult<PHAssetCollection *> *collections = [PHCollectionService getAlbumsWithLocalIdentifiers:localIdentifiers andParams:nil];
            
          NSMutableDictionary *response = [PHCollectionService generateCollectionResponseWithCollections:(PHFetchResult<PHCollection *> *)collections andParams:[NSDictionary dictionaryWithObjectsAndKeys:@"true", @"noCache", nil]];
            
            return resolve([response objectForKey:@"albums"]);
        }else{
            return reject([NSString stringWithFormat:@"Error creating albumTitles %@", albumTitles], nil, error);
        }
    }];
}


RCT_EXPORT_METHOD(deleteAssets:(NSArray *)localIdentifiers
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    if(localIdentifiers == nil || localIdentifiers.count == 0) {
        return resolve(@{@"localIdentifiers" : @[], @"success" : @((BOOL)true)});
    }
    PHFetchResult<PHAsset *> * assets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:localIdentifiers];
    [PHAssetsService deleteAssets:assets andCompleteBLock:^(BOOL success, NSError * _Nullable error, NSArray<NSString *> *localIdentifiers) {
        if(localIdentifiers && localIdentifiers.count != 0) {
            return resolve(@{@"localIdentifiers" : localIdentifiers, @"success" : @(success) });
        }
        return reject(@"Error removing assets", nil, error);
    }];
    
}

RCT_EXPORT_METHOD(deleteAlbums:(NSArray *)albumsLocalIdentifiers
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    if(albumsLocalIdentifiers == nil) {
        return reject(@"input array with album-localIdentifiers array<string> cannot be null", nil, nil);
    }
    
    if(albumsLocalIdentifiers.count == 0) {
        return resolve(@[]);
    }
    
    [PHCollectionService deleteAlbumsWithLocalIdentifers:albumsLocalIdentifiers andCompleteBLock:^(BOOL success, NSError * _Nullable error) {
        if(success) {
            return resolve(@{@"success" : @(success)});
        }else{
            return reject(@"Error deleting albums", nil, error);
        }
    }];
}

RCT_EXPORT_METHOD(getAssetsMetadata:(NSArray<NSString *> *)arrayWithLocalIdentifiers
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHFetchResult<PHAsset *> * arrayWithAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:arrayWithLocalIdentifiers];
    NSMutableArray<NSDictionary *>  *arrayWithMetadataObjs = [NSMutableArray arrayWithCapacity:arrayWithAssets.count];
    [arrayWithAssets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        [arrayWithMetadataObjs addObject:[PHAssetsService extendAssetDicWithAssetMetadata:[NSMutableDictionary dictionaryWithObject:asset.localIdentifier forKey:@"localIdentifier"] andPHAsset:asset]];
    }];
    resolve(arrayWithMetadataObjs);
}


-(void) prepareAssetsForDisplayWithParams:(NSDictionary *)params andAssets:(NSArray<PHAssetWithCollectionIndex *> *)assets {
    NSString *prepareProp = params[@"prepareForSizeDisplay"];
    if(prepareProp != nil) {
        CGSize prepareForSizeDisplay = [RCTConvert CGSize:params[@"prepareForSizeDisplay"]];
        CGFloat prepareScale = [RCTConvert CGFloat:params[@"prepareScale"]];
        PHCachingImageManager *cacheManager = [PHCachingImageManagerInstance sharedCachingManager];
        
        if(prepareForSizeDisplay.width != 0 && prepareForSizeDisplay.height != 0) {
            if(prepareScale < 0.1) {
                prepareScale = 2;
            }
            [cacheManager startCachingImagesForAssets:[PHAssetWithCollectionIndex toAssetsArray:assets] targetSize:CGSizeApplyAffineTransform(prepareForSizeDisplay, CGAffineTransformMakeScale(prepareScale, prepareScale)) contentMode:PHImageContentModeAspectFill options:nil];
        }
    }

}

RCT_EXPORT_METHOD(createAssets:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    NSArray<PHSaveAssetRequest *> *images = [RCTConvert PHSaveAssetRequestArray:params[@"images"]];
    NSArray<PHSaveAssetRequest *> *videos = [RCTConvert PHSaveAssetRequestArray:params[@"videos"]];
    if((images == nil || images.count == 0) && (videos == nil || videos.count == 0)) {
        return resolve(@{@"localIdentifiers" : @[], @"success" : @((BOOL)true)});
    }
    NSString *albumLocalIdentifier = [RCTConvert NSString:params[@"albumLocalIdentifier"]];
    PHAssetCollection *collection = [PHCollectionService getAssetForLocalIdentifer:albumLocalIdentifier];
    
    [self saveImages:[images mutableCopy] andLocalIdentifers:[NSMutableArray arrayWithCapacity:images.count] andCollection:collection andCompleteBLock:^(BOOL success, NSError * _Nullable error, NSMutableArray<NSString *> *localIdentifiers) {
        if(localIdentifiers && localIdentifiers.count != 0) {
            BOOL includeMetadata = [RCTConvert BOOL:params[@"includeMetadata"]];
            BOOL includeResourcesMetadata = [RCTConvert BOOL:params[@"includeResourcesMetadata"]];
            
            
            PHFetchResult<PHAsset *> *newAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:localIdentifiers];
            NSArray<NSDictionary *> *assetResponse = [PHAssetsService assetsArrayToUriArray:(NSArray<id> *)newAssets andincludeMetadata:includeMetadata andIncludeAssetResourcesMetadata:includeResourcesMetadata];
            return resolve(@{@"assets" : assetResponse, @"success" : @(success) });
        }
        return reject(@"Error creating assets", nil, error);

    }];
}

-(void) saveImages:(NSMutableArray<PHSaveAssetRequest *> *)requests andLocalIdentifers:(NSMutableArray<NSString *> *)localIdentifiers andCollection:(PHAssetCollection *)collection andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSMutableArray<NSString *> * localIdentifiers))completeBlock {
    
    if(requests.count == 0){
        return completeBlock(YES, nil, localIdentifiers);
    }
    PHSaveAssetRequest *currentRequest = [requests objectAtIndex:0];
    [requests removeObject:currentRequest];
    if(currentRequest != nil) {
        __weak RCTCameraRollRNPhotosFrameworkManager *weakSelf = self;
        [self saveImage:currentRequest toCollection:collection andCompleteBLock:^(BOOL success, NSError * _Nullable error, NSString * _Nullable localIdentifier) {
            if(success) {
                [localIdentifiers addObject:localIdentifier];
                return [weakSelf saveImages:requests andLocalIdentifers:localIdentifiers andCollection:collection andCompleteBLock:completeBlock];
            }else {
                return completeBlock(success, nil, localIdentifiers);
            }

        }];
    }else {
       return [self saveImages:requests andLocalIdentifers:localIdentifiers andCollection:collection andCompleteBLock:completeBlock];
    }

}

RCT_EXPORT_METHOD(createImageAsset:(PHSaveAssetRequest *)request
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    [self saveImage:request toCollection:nil andCompleteBLock:^(BOOL success, NSError * _Nullable error, NSString * _Nullable localIdentifier) {
        if(success) {
            return resolve(@{ @"success" : @(success) });
        }else {
            return reject(@"Error creating image asset", nil, error);
        }
    }];
}

-(void)saveImage:(PHSaveAssetRequest *)request
    toCollection:(PHAssetCollection *)collection
andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSString *__nullable localIdentifier))completeBlock {
    if ([request.type isEqualToString:@"video"]) {
        // It's unclear if thread-safe
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSException raise:@"Not implementeted exception" format:@"Sry"];
            
        });
    } else {

        [_bridge.imageLoader loadImageWithURLRequest:request.uri
                                 size:CGSizeZero
                                scale:1
                              clipped:YES
                           resizeMode:RCTResizeModeStretch
                        progressBlock:nil
                     partialLoadBlock:nil
                                     completionBlock:^(NSError *loadError, UIImage *loadedImage) {
                                         if (loadError) {
                                             completeBlock(NO, loadError, nil);
                                             return;
                                         }
                                         [PHCollectionService saveImage:loadedImage toAlbum:collection andCompleteBLock:completeBlock];
                                     }];
    }
}

@end
