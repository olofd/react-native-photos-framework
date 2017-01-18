#import <React/RCTConvert.h>
#import <React/RCTImageLoader.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <React/RCTProfile.h>
#import "RNPFManager.h"
#import "PHCachingImageManagerInstance.h"
#import "RCTConvert+RNPhotosFramework.h"
#import "PHChangeObserver.h"
#import "PHFetchOptionsService.h"
#import "PHAssetsService.h"
#import "PHCollectionService.h"
#import "PHCachedFetchResult.h"
#import "PHSaveAssetRequest.h"
#import "RNPFHelpers.h"
#import "RNPFFileDownloader.h"
#import "PHOperationResult.h"
#import "iDebounce.h"
#import "PHCache.h"

@import Photos;

@implementation RNPFManager
RCT_EXPORT_MODULE()

NSString *const RNPHotoFrameworkErrorUnableToLoad = @"RNPHOTOSFRAMEWORK_UNABLE_TO_LOAD";
NSString *const RNPHotoFrameworkErrorUnableToSave = @"RNPHOTOSFRAMEWORK_UNABLE_TO_SAVE";

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.changeObserver = [[PHChangeObserver alloc] initWithEventEmitter:self];
    }
    return self;
}

- (void)dealloc
{
    if(self.changeObserver) {
        [self.changeObserver removeChangeObserver];
    }
}

- (dispatch_queue_t)methodQueue
{
    self.currentQueue = dispatch_queue_create("com.dahlbom.React.ReactNaticePhotosFramework", DISPATCH_QUEUE_SERIAL);
    return self.currentQueue;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"onCreateAssetsProgress", @"onLibraryChange", @"onObjectChange"];
}

RCT_EXPORT_METHOD(startChangeObserving:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    self.changeObserver = [[PHChangeObserver alloc] initWithEventEmitter:self];
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
    RCT_PROFILE_BEGIN_EVENT(0, @"-[RNPFManager getAssets", nil);
    
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
    [[PHCache sharedPHCache] cleanCache];
    
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
        [[PHCache sharedPHCache] removeFetchResultFromCacheWithUUID:cacheKey];
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
        [arrayWithMetadataObjs addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:asset.localIdentifier, @"localIdentifier", [PHAssetsService extendAssetDictWithAssetMetadata:[NSMutableDictionary new] andPHAsset:asset], @"metadata", nil]];

    }];
    resolve(arrayWithMetadataObjs);
}

RCT_EXPORT_METHOD(getAssetsResourcesMetadata:(NSArray<NSString *> *)arrayWithLocalIdentifiers
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHFetchResult<PHAsset *> * arrayWithAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:arrayWithLocalIdentifiers];
    NSMutableArray<NSDictionary *> *arrayWithMetadataObjs = [NSMutableArray arrayWithCapacity:arrayWithAssets.count];
    [arrayWithAssets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:asset.localIdentifier, @"localIdentifier", nil];
        [dict addEntriesFromDictionary:[PHAssetsService extendAssetDictWithAssetResourcesMetadata:[NSMutableDictionary new] andPHAsset:asset]];
        [arrayWithMetadataObjs addObject:dict];
    }];
    resolve(arrayWithMetadataObjs);
}

RCT_EXPORT_METHOD(getImageAssetsMetadata:(NSArray<NSString *> *)arrayWithLocalIdentifiers
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHFetchResult<PHAsset *> * arrayWithAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:arrayWithLocalIdentifiers];
    NSMutableArray *mutableArrayWithAssets = [NSMutableArray arrayWithCapacity:arrayWithAssets.count];
    NSMutableArray<NSDictionary *> *arrayWithMetadataObjs = [NSMutableArray arrayWithCapacity:arrayWithAssets.count];
    [arrayWithAssets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        [mutableArrayWithAssets addObject:asset];
    }];
    [self getImageAssetsMetaData:mutableArrayWithAssets andResultArray:arrayWithMetadataObjs andCompleteBLock:^(NSMutableArray<NSDictionary *> *resultArray) {
        resolve(resultArray);
    }];
}

-(void) getImageAssetsMetaData:(NSMutableArray<PHAsset *> *)assets andResultArray:(NSMutableArray<NSDictionary *> *)resultArray andCompleteBLock:(nullable void(^)(NSMutableArray<NSDictionary *> * resultArray))completeBlock {
    
    if(assets.count == 0){
        return completeBlock(resultArray);
    }
    PHAsset *currentAsset = [assets objectAtIndex:0];
    [assets removeObject:currentAsset];
    if(currentAsset != nil) {
        __weak RNPFManager *weakSelf = self;
        [PHAssetsService extendAssetDictWithPhotoAssetEditionMetadata:[NSMutableDictionary new] andPHAsset:currentAsset andCompletionBlock:^(NSMutableDictionary *dict) {
            
            [resultArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:currentAsset.localIdentifier, @"localIdentifier", dict, @"imageMetadata", nil]];
            
            return [weakSelf getImageAssetsMetaData:assets andResultArray:resultArray andCompleteBLock:completeBlock];
        }];
    }else {
        return [self getImageAssetsMetaData:assets andResultArray:resultArray andCompleteBLock:completeBlock];
    }
}


RCT_EXPORT_METHOD(updateAssets:(NSArray *)arrayWithLocalIdentifiers andUpdateObjs:(NSDictionary *)updateObjs
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHFetchResult<PHAsset *> * arrayWithAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:arrayWithLocalIdentifiers];
    
    if(arrayWithAssets == nil || arrayWithAssets.count == 0){
        return resolve(@{});
    }
    NSMutableArray *mutableArrayWithAssets = [NSMutableArray arrayWithCapacity:arrayWithAssets.count];
    [arrayWithAssets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        [mutableArrayWithAssets addObject:asset];
    }];
    [self updateAssets:mutableArrayWithAssets andUpdateObjs:updateObjs andResultArray:[NSMutableDictionary new] andCompleteBLock:^(NSMutableDictionary *result) {
        resolve(result);
    }];
}


-(void) updateAssets:(NSMutableArray<PHAsset *> *)assets andUpdateObjs:(NSDictionary *)updateObjs andResultArray:(NSMutableDictionary *)result andCompleteBLock:(nullable void(^)(NSMutableDictionary * result))completeBlock {
    
    if(assets.count == 0){
        return completeBlock(result);
    }
    PHAsset *currentAsset = [assets objectAtIndex:0];
    [assets removeObject:currentAsset];
    if(currentAsset != nil) {
        __weak RNPFManager *weakSelf = self;
        NSDictionary *assetUpdateParams = [updateObjs objectForKey:currentAsset.localIdentifier];
        if(assetUpdateParams) {
            [PHAssetsService updateAssetWithParams:assetUpdateParams completionBlock:^(BOOL success, NSError * _Nullable error, NSString * _Nullable localIdentifier) {
                
                [result setObject:@{
                                    @"success" : @(success),
                                    @"error" : (error != nil ? error.localizedDescription : @"")
                                    } forKey:localIdentifier];
      
                return [weakSelf updateAssets:assets andUpdateObjs:updateObjs andResultArray:result andCompleteBLock:completeBlock];
                
            } andAsset:currentAsset];
        }

    }else {
        return [self updateAssets:assets andUpdateObjs:updateObjs andResultArray:result andCompleteBLock:completeBlock];
    }
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
    NSArray<PHSaveAssetRequest *> *media = [RCTConvert PHSaveAssetRequestArray:params[@"media"]];
    if(media == nil || media.count == 0) {
        return resolve(@{@"localIdentifiers" : @[], @"success" : @((BOOL)true)});
    }
    NSString *albumLocalIdentifier = [RCTConvert NSString:params[@"albumLocalIdentifier"]];
    
    NSMutableArray *arrayWithProgress;
    
    NSString *progressEventId = [RCTConvert NSString:params[@"onCreateAssetsProgress"]];
    if(progressEventId != nil) {
        arrayWithProgress = [NSMutableArray arrayWithCapacity:media.count];
        for(int i = 0; i < media.count;i++) {
            PHSaveAssetRequest *m = [media objectAtIndex:i];
            [arrayWithProgress addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@(0), m.source.uri, nil]];
        }
    }
    
    
    [self saveMediaMany:media andCollectionLocalIdentifier:albumLocalIdentifier andCompleteBLock:^(NSMutableArray<PHOperationResult *> *result) {
        
        NSMutableArray *arrayWithLocalIdentfiers = [[NSMutableArray alloc] initWithCapacity:result.count];
        for(int i = 0; i < result.count;i++) {
            PHOperationResult *operation = [result objectAtIndex:i];
            if(operation.success) {
                [arrayWithLocalIdentfiers addObject:operation.localIdentifier];
            }
        }
        
        BOOL includeMetadata = [RCTConvert BOOL:params[@"includeMetadata"]];
        BOOL includeResourcesMetadata = [RCTConvert BOOL:params[@"includeResourcesMetadata"]];
        
        PHFetchResult<PHAsset *> *newAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:arrayWithLocalIdentfiers];
        NSArray<NSDictionary *> *assetResponse = [PHAssetsService assetsArrayToUriArray:(NSArray<id> *)newAssets andincludeMetadata:includeMetadata andIncludeAssetResourcesMetadata:includeResourcesMetadata];
        return resolve(@{@"assets" : assetResponse, @"success" : @(YES) });
        
    } andProgressBlock:^(NSString *uri, int index, int64_t progress, int64_t total) {
        if(progressEventId != nil) {
            @synchronized(arrayWithProgress)
            {
                NSMutableDictionary *dictForEntry = [arrayWithProgress objectAtIndex:index];
                int64_t currentProgress = [[dictForEntry objectForKey:uri] integerValue];
                currentProgress = ((float)progress / total) * 100;
                [dictForEntry setObject:@(currentProgress) forKey:uri];
            }
            [iDebounce debounce:^{
                dispatch_async(self.currentQueue, ^{
                    NSLog(@"Sending");
                    [self sendEventWithName:@"onCreateAssetsProgress" body:@{@"id" : progressEventId, @"data" : arrayWithProgress}];
                });
            } withIdentifier:progressEventId wait:0.050];
        }
    }];
}

-(void) saveMediaMany:(NSArray<PHSaveAssetRequest *> *)requests andCollectionLocalIdentifier:(NSString *)collectionLocalIdentifier andCompleteBLock:(createAssetsCompleteBlock)completeBlock andProgressBlock:(fileDownloadExtendedPrograessBlock)progressBlock {
    
    NSMutableArray<PHOperationResult *> *resultArray = [[NSMutableArray alloc] initWithCapacity:requests.count];
    NSOperationQueue *myOQ=[[NSOperationQueue alloc] init];
    [myOQ setMaxConcurrentOperationCount:5];
    assetOperationBlock onTaskFinnished = ^void(BOOL success, NSError *__nullable error, NSString  * __nullable localIdentifier) {
        if(!myOQ.isSuspended) {
            @synchronized(resultArray)
            {
                [resultArray addObject:[[PHOperationResult alloc] initWithLocalIdentifier:localIdentifier andSuccess:success andError:error]];
                if(resultArray.count == requests.count) {
                    [myOQ setSuspended:YES];
                    [myOQ cancelAllOperations];
                    completeBlock(resultArray);
                }
            }
        }
    };
    for(int i = 0; i < requests.count;i++) {
        __block PHSaveAssetRequest *currentRequest = [requests objectAtIndex:i];
        [myOQ addOperationWithBlock:^(void){
            [self saveMedia:currentRequest toCollection:collectionLocalIdentifier andCompleteBLock:onTaskFinnished andProgressBlock:^(int64_t progress, int64_t total) {
                progressBlock(currentRequest.source.uri, i, progress, total);
            }];
        }];
    }
}

-(void)saveMedia:(PHSaveAssetRequest *)request
    toCollection:(NSString *)collectionLocalIdentifier
    andCompleteBLock:(assetOperationBlock)completeBlock
    andProgressBlock:(fileDownloadProgressBlock)progressBlock {
    if ([request.type isEqualToString:@"video"]) {
        [self saveVideo:request.source toAlbum:collectionLocalIdentifier andCompleteBLock:completeBlock andProgressBlock:progressBlock];
    } else if([request.type isEqualToString:@"image"]) {
        NSURLRequest *url = [RCTConvert NSURLRequest:request.source.uri];
        [self.bridge.imageLoader loadImageWithURLRequest:url
                                                size:CGSizeZero
                                               scale:1
                                             clipped:YES
                                          resizeMode:RCTResizeModeStretch
                                          progressBlock:^(int64_t progress, int64_t total) {
                                              progressBlock(progress, total);
                                          }
                                    partialLoadBlock:nil
                                     completionBlock:^(NSError *loadError, UIImage *loadedImage) {
                                         if (loadError) {
                                             completeBlock(NO, loadError, nil);
                                             return;
                                         }
                                         [PHCollectionService saveImage:loadedImage toAlbum:collectionLocalIdentifier andCompleteBLock:completeBlock];
                                     }];
    }
}

-(void) saveVideo:(PHSaveAsset *)source toAlbum:(NSString *)albumLocalIdentifier andCompleteBLock:(assetOperationBlock)completeBlock andProgressBlock:(fileDownloadProgressBlock)progressBlock {
     NSString *type = source.type != nil ? [@"." stringByAppendingString:source.type] : @".mp4";
     NSURL *url = (source.isNetwork || source.isAsset) ?
     [NSURL URLWithString:source.uri] :
     [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:source.uri ofType:source.type]];
     
     if (source.isNetwork) {
         RNPFFileDownloader *fileDownloader = [RNPFFileDownloader new];
         [fileDownloader startDownload:url andSaveWithExtension:type andProgressBlock:^(int64_t progress, int64_t total) {
             progressBlock(progress, total);
         } andCompletionBlock:^(NSURL *downloadUrl) {
            [self saveVideoAtURL:downloadUrl toAlbum:albumLocalIdentifier andCompleteBLock:completeBlock];
         } andErrorBlock:^(NSError *error) {
             completeBlock(NO, error, nil);
         }];
     }
     else {
         [self saveVideoAtURL:url toAlbum:albumLocalIdentifier andCompleteBLock:completeBlock];
     }
}

-(void)saveVideoAtURL:(NSURL *)url toAlbum:(NSString *)albumLocalIdentifier andCompleteBLock:(assetOperationBlock)completeBlock {
    __block PHObjectPlaceholder *placeholder;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
        placeholder = [assetRequest placeholderForCreatedAsset];
        
        if(albumLocalIdentifier != nil) {
            PHAssetCollection *album = [PHCollectionService getAssetForLocalIdentifer:albumLocalIdentifier];
            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:album];
            [albumChangeRequest addAssets:@[placeholder]];

        }
    } completionHandler:^(BOOL success, NSError *error) {
        completeBlock(success, error, placeholder.localIdentifier);
    }];
}

@end
