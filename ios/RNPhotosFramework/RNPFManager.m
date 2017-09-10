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
#import "PHSaveAssetToFileOperationResult.h"
#import "iDebounce.h"
#import "PHCache.h"
#import "RCTImageResizer.h"
#import "PHVideoExporter.h"

@import Photos;

@implementation RNPFManager
RCT_EXPORT_MODULE()

NSString *const RNPHotoFrameworkErrorUnableToLoad = @"RNPHOTOSFRAMEWORK_UNABLE_TO_LOAD";
NSString *const RNPHotoFrameworkErrorUnableToSave = @"RNPHOTOSFRAMEWORK_UNABLE_TO_SAVE";


/*
 Startup And Globals
 */

#pragma mark - Startup And Globals

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
    return @[@"onCreateAssetsProgress", @"onSaveAssetsToFileProgress", @"onLibraryChange", @"onObjectChange"];
}

// Will be called when this module's first listener is added.
-(void)startObserving {
    hasListeners = YES;
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
    hasListeners = NO;
}

RCT_EXPORT_METHOD(setAllowsCachingHighQualityImages:(BOOL)allowed)
{
    [[PHCachingImageManagerInstance sharedCachingManager] setAllowsCachingHighQualityImages:allowed];
}


RCT_EXPORT_METHOD(libraryStartup:(BOOL)useCacheAndChangeTracking
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    [[PHCache sharedPHCache] cleanCache];
    if(useCacheAndChangeTracking && self.changeObserver == nil) {
        self.changeObserver = [[PHChangeObserver alloc] initWithEventEmitter:self];
    }
    resolve(@{ @"success" : @((BOOL)YES) });
}


RCT_EXPORT_METHOD(startChangeObserving:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    self.changeObserver = [[PHChangeObserver alloc] initWithEventEmitter:self];
}

/*
 LibraryAuthorization
 */

#pragma mark - LibraryAuthorization

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


/*
 GetAssets
 */

#pragma mark - GetAssets


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
    return resolve(@{
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

/*
 DeleteAssets
 */

#pragma mark - DeleteAssets


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


/*
 GetAssetMetaData
 */

#pragma mark - GetAssetMetaData


RCT_EXPORT_METHOD(getAssetsMetadata:(NSArray<NSString *> *)arrayWithLocalIdentifiers
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHFetchResult<PHAsset *> * arrayWithAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:arrayWithLocalIdentifiers];
    NSMutableDictionary<NSString *, NSDictionary *> *dictWithMetadataObjs = [NSMutableDictionary dictionaryWithCapacity:arrayWithAssets.count];
    [arrayWithAssets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        [dictWithMetadataObjs setObject:[PHAssetsService extendAssetDictWithAssetMetadata:[NSMutableDictionary new] andPHAsset:asset] forKey:asset.localIdentifier];
        
    }];
    resolve(dictWithMetadataObjs);
}

RCT_EXPORT_METHOD(getAssetsResourcesMetadata:(NSArray<NSString *> *)arrayWithLocalIdentifiers
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHFetchResult<PHAsset *> * arrayWithAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:arrayWithLocalIdentifiers];
    NSMutableDictionary<NSString *, NSDictionary *> *dictWithMetadataObjs = [NSMutableDictionary dictionaryWithCapacity:arrayWithAssets.count];
    [arrayWithAssets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        [dictWithMetadataObjs setObject:[PHAssetsService extendAssetDictWithAssetResourcesMetadata:[NSMutableDictionary new] andPHAsset:asset] forKey:asset.localIdentifier];
    }];
    resolve(dictWithMetadataObjs);
}


RCT_EXPORT_METHOD(getImageAssetsMetadata:(NSArray<NSString *> *)arrayWithLocalIdentifiers
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    PHFetchResult<PHAsset *> * arrayWithAssets = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:arrayWithLocalIdentifiers];
    NSMutableArray *mutableArrayWithAssets = [NSMutableArray arrayWithCapacity:arrayWithAssets.count];
    NSMutableDictionary<NSString *, NSDictionary *> *dictWithMetadataObjs = [NSMutableDictionary dictionaryWithCapacity:arrayWithAssets.count];
    
    [arrayWithAssets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        [mutableArrayWithAssets addObject:asset];
    }];
    [self getImageAssetsMetaData:mutableArrayWithAssets andResultDict:dictWithMetadataObjs andCompleteBLock:^(NSMutableDictionary<NSString *, NSDictionary *> *resultDict) {
        resolve(resultDict);
    }];
}


-(void) getImageAssetsMetaData:(NSMutableArray<PHAsset *> *)assets andResultDict:(NSMutableDictionary<NSString *, NSDictionary *> *)resultDict andCompleteBLock:(nullable void(^)(NSMutableDictionary<NSString *, NSDictionary *> * resultDict))completeBlock {
    
    if(assets.count == 0){
        return completeBlock(resultDict);
    }
    PHAsset *currentAsset = [assets objectAtIndex:0];
    [assets removeObject:currentAsset];
    if(currentAsset != nil) {
        __weak RNPFManager *weakSelf = self;
        [PHAssetsService extendAssetDictWithPhotoAssetEditingMetadata:[NSMutableDictionary new] andPHAsset:currentAsset andCompletionBlock:^(NSMutableDictionary *dict) {
            [resultDict setObject:dict forKey:currentAsset.localIdentifier];
            return [weakSelf getImageAssetsMetaData:assets andResultDict:resultDict andCompleteBLock:completeBlock];
        }];
    }else {
        return [self getImageAssetsMetaData:assets andResultDict:resultDict andCompleteBLock:completeBlock];
    }
}

/*
 UPDATEASSETS
 */


#pragma mark - UpdateAssets

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

/*
 SAVEASSETSTOFILE
 */


#pragma mark - SaveAssetsToFile

RCT_EXPORT_METHOD(saveAssetsToDisk:(NSDictionary *)params
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
    
    NSArray<PHSaveAssetFileRequest *> *media = [RCTConvert PHSaveAssetFileRequestArray:params[@"media"]];
    if(media == nil || media.count == 0) {
        return resolve(@{@"files" : @[], @"success" : @((BOOL)true)});
    }
    
    NSMutableArray *arrayWithProgress;
    
    NSDictionary *events= [RCTConvert NSDictionary:params[@"events"]];
    
    NSString *progressEventId = [RCTConvert NSString:events[@"onSaveAssetsToFileProgress"]];
    NSString *cancellationEventId = [RCTConvert NSString:events[@"onCancellationTokenCreated"]];
    
   // [self sendEventWithName:@"onCancellationTokenCreated" body:@{@"id" : cancellationEventId, @"data" : arrayWithProgress}];

    if(progressEventId != nil) {
        arrayWithProgress = [NSMutableArray arrayWithCapacity:media.count];
        for(int i = 0; i < media.count;i++) {
            PHSaveAssetFileRequest *m = [media objectAtIndex:i];
            [arrayWithProgress addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@(0), m.uriString, nil]];
        }
    }
    
    [self saveAssetsToFileMany:media andCompleteBLock:^(NSMutableArray<PHSaveAssetToFileOperationResult *> * _Nonnull results) {
        if(results == nil) {
            return reject(@"Something went wrong, result was nil", nil, nil);
        }
        NSMutableArray *arrayResponse = [[NSMutableArray alloc] initWithCapacity:results.count];
        for(int i = 0; i < results.count; i ++) {
            PHSaveAssetToFileOperationResult *fileResult = [results objectAtIndex:i];
            [arrayResponse addObject:@{
                                       @"localIdentifier" :fileResult.localIdentifier,
                                       @"fileUrl" : fileResult.fileUrl,
                                       @"success" : @(fileResult.success),
                                       @"error" : fileResult.error != nil ? [fileResult.error localizedDescription] : [NSNull null]
                                       }];
        }
        return resolve(arrayResponse);
        
        
    } andProgressBlock:^(NSString * _Nonnull uri, int index, float progress) {
        if(hasListeners) {
            @synchronized(arrayWithProgress)
            {
                NSMutableDictionary *dictForEntry = [arrayWithProgress objectAtIndex:index];
                int64_t currentProgress = [[dictForEntry objectForKey:uri] integerValue];
                currentProgress = progress;
                [dictForEntry setObject:@(currentProgress) forKey:uri];
            }
            if(progressEventId != nil) {
                [iDebounce debounce:^{
                    dispatch_async(self.currentQueue, ^{
                        [self sendEventWithName:@"onSaveAssetsToFileProgress" body:@{@"id" : progressEventId, @"data" : arrayWithProgress}];
                    });
                } withIdentifier:progressEventId wait:0.050];
            }
        }
        
    }];
}

-(void) saveAssetsToFileMany:(NSArray<PHSaveAssetFileRequest *> *)saveFileRequests
            andCompleteBLock:(assetsFileSaveCompleteBlock)completeBlock andProgressBlock:(fileDownloadExtendedPrograessBlockSimple)progressBlock {
    
    __block NSMutableArray<PHSaveAssetToFileOperationResult *> *resultArray = [[NSMutableArray alloc] initWithCapacity:saveFileRequests.count];
    NSOperationQueue *myOQ = [[NSOperationQueue alloc] init];
    [myOQ setMaxConcurrentOperationCount:5];
    assetFileSaveOperationBlock onTaskFinnished = ^void(BOOL success, NSError *__nullable error, NSString  * __nullable localIdentifier, NSString  * __nullable fileUrl) {
        if(!myOQ.isSuspended) {
            @synchronized(resultArray)
            {
                [resultArray addObject:[[PHSaveAssetToFileOperationResult alloc] initWithLocalIdentifier:localIdentifier fileUrl:fileUrl andSuccess:success andError:error]];
                if(resultArray.count == saveFileRequests.count) {
                    [myOQ setSuspended:YES];
                    [myOQ cancelAllOperations];
                    completeBlock(resultArray);
                }
            }
        }
    };
    for(int i = 0; i < saveFileRequests.count;i++) {
        __block PHSaveAssetFileRequest *currentRequest = [saveFileRequests objectAtIndex:i];
        [myOQ addOperationWithBlock:^(void){
            if([currentRequest.mediaType isEqualToString:@"image"]) {
                [self writeImageToFile:currentRequest andCompleteBLock:onTaskFinnished andProgressBlock:^(int64_t progress, int64_t total) {
                    progressBlock(currentRequest.uriString, i, ((float)progress / total) * 100);
                }];
            }else if([currentRequest.mediaType isEqualToString:@"video"]) {
                [self writeVideoToFile:currentRequest andCompleteBLock:onTaskFinnished andProgressBlock:^(float progress) {
                    progressBlock(currentRequest.uriString, i, progress);
                }];
            }
        }];
    }
}

-(void) writeImageToFile:(PHSaveAssetFileRequest *)fileRequest andCompleteBLock:(assetFileSaveOperationBlock)completeBlock andProgressBlock:(fileDownloadProgressBlock)progressBlock {
    [self loadImageWithURLRequest:fileRequest.uri
                                             clipped:YES
                                          resizeMode:RCTResizeModeStretch
                                    progressBlock:^(int64_t progress, int64_t total) {
                                           return progressBlock(progress, total);
                                       }
                                     partialLoadBlock:nil
                                     completionBlock:^(NSError *error, UIImage *loadedImage) {
                                         if (error) {
                                             return completeBlock(NO, error, fileRequest.localIdentifier, nil);
                                         }
                                         
                                         if(fileRequest.postProcessOptions != nil) {
                                             float width = [RCTConvert float:fileRequest.postProcessOptions[@"width"]];
                                             float height = [RCTConvert float:fileRequest.postProcessOptions[@"height"]];
                                             float quality = [RCTConvert float:fileRequest.postProcessOptions[@"quality"]];
                                             float rotation = [RCTConvert float:fileRequest.postProcessOptions[@"rotation"]];
                                             
                                             if(width < 0.1) {
                                                 width = loadedImage.size.width;
                                             }
                                             if(height < 0.1) {
                                                 height = loadedImage.size.height;
                                             }
                                             if(quality < 0.1) {
                                                 quality = 100;
                                             }
                                             
                                             NSString *format = [RCTConvert NSString:fileRequest.postProcessOptions[@"format"]];
                                             if(![format isEqualToString:@"JPEG"] || ![format isEqualToString:@"PNG"]) {
                                                 format = @"JPEG";
                                             }
                                             return [RNPFImageResizer createResizedImage:loadedImage width:width height:height format:format quality:quality rotation:rotation outputPath:fileRequest.dir fileName:fileRequest.fileName andCompleteBLock:^(NSString *error, NSString *path) {
                                                 if(error != nil) {
                                                     return completeBlock(NO, nil, fileRequest.localIdentifier, nil);
                                                 }
                                                 progressBlock(100, 100);
                                                 return completeBlock(YES, nil,fileRequest.localIdentifier, path);
                                             }];
                                         }
                                         
                                         
                                         NSString *fullFileName = [fileRequest.dir stringByAppendingPathComponent:fileRequest.fileName];
                                         
                                         NSData * binaryImageData = UIImagePNGRepresentation(loadedImage);
                                         
                                         BOOL success = [binaryImageData writeToFile:fullFileName atomically:YES];
                                         if(success) {
                                             return completeBlock(YES, nil, fileRequest.localIdentifier, fullFileName);
                                         }
                                         
                                     } andOptions:[RCTConvert NSDictionary:fileRequest.loadOptions]];
}

-(void) writeVideoToFile:(PHSaveAssetFileRequest *)fileRequest andCompleteBLock:(assetFileSaveOperationBlock)completeBlock andProgressBlock:(fileDownloadProgressBlockSimple)progressBlock {
    __block PHVideoExporter *videoExporter;
    PHAsset* asset = [PHAssetsService getAssetsFromArrayOfLocalIdentifiers:@[fileRequest.localIdentifier]].firstObject;
    
    fileRequest.videoRequestOptions.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        progressBlock((progress * 100) / 2);
    };
    
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset
                                                    options:fileRequest.videoRequestOptions
                                              resultHandler:
     ^(AVAsset * _Nullable avasset,
       AVAudioMix * _Nullable audioMix,
       NSDictionary * _Nullable info)
     {
         progressBlock(50);
         
         if(fileRequest.postProcessOptions != nil) {
             videoExporter = [PHVideoExporter new];
             [videoExporter exportVideoWithAsset:avasset andDir:fileRequest.dir andFileName:fileRequest.fileName andPostProcessParams:fileRequest.postProcessOptions andProgressBlock:^(float progress) {
                 progressBlock((progress * 100));
                 
             } andCompletionBlock:^(BOOL success, NSError * _Nullable error, NSURL * _Nullable fileUrl) {
                 progressBlock(100);
                 completeBlock(success, error, fileRequest.localIdentifier, [fileUrl absoluteString]);
             }];
         }else {
             
             NSError *error;
             __block NSString *fullFileName = [fileRequest.dir stringByAppendingPathComponent:fileRequest.fileName];
             
             if ([[NSFileManager defaultManager] fileExistsAtPath:fullFileName] && [[NSFileManager defaultManager] isDeletableFileAtPath:fullFileName]) {
                 BOOL success = [[NSFileManager defaultManager] removeItemAtPath:fullFileName error:&error];
                 if (!success) {
                     NSLog(@"Error removing file at path: %@", error.localizedDescription);
                 }
             }
             NSURL *fileURL = [NSURL fileURLWithPath:fullFileName];

             AVURLAsset *avurlasset = (AVURLAsset*) avasset;

             if ([[NSFileManager defaultManager] copyItemAtURL:avurlasset.URL
                                                         toURL:fileURL
                                                         error:&error]) {
                 if(error) {
                     return completeBlock(NO, error, fileRequest.localIdentifier, nil);
                 }else {
                     progressBlock(100);
                     return completeBlock(YES, nil, fileRequest.localIdentifier, fullFileName);
                 }
             }
         }
     }];
}

/*
 CREATEASSETS
 */


#pragma mark - CreateAssets
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
        if(hasListeners && progressEventId != nil) {
            @synchronized(arrayWithProgress)
            {
                NSMutableDictionary *dictForEntry = [arrayWithProgress objectAtIndex:index];
                int64_t currentProgress = [[dictForEntry objectForKey:uri] integerValue];
                currentProgress = ((float)progress / total) * 100;
                [dictForEntry setObject:@(currentProgress) forKey:uri];
            }
            
            [iDebounce debounce:^{
                dispatch_async(self.currentQueue, ^{
                    [self sendEventWithName:@"onCreateAssetsProgress" body:@{@"id" : progressEventId, @"data" : arrayWithProgress}];
                });
            } withIdentifier:progressEventId wait:0.050];
        }
    }];
}

-(void) saveMediaMany:(NSArray<PHSaveAssetRequest *> *)requests andCollectionLocalIdentifier:(NSString *)collectionLocalIdentifier andCompleteBLock:(createAssetsCompleteBlock)completeBlock andProgressBlock:(fileDownloadExtendedPrograessBlock)progressBlock {
    
    NSMutableArray<PHOperationResult *> *resultArray = [[NSMutableArray alloc] initWithCapacity:requests.count];
    NSOperationQueue *myOQ = [[NSOperationQueue alloc] init];
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

/*
 GetAlbums
 */

#pragma mark - GetAlbums

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

/*
 CreateAlbums
 */

#pragma mark - CreateAlbums

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

/*
 DeleteAlbums
 */

#pragma mark - DeleteAlbums

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

/*
 UpdateAlbum
 */

#pragma mark - UpdateAlbum

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

#pragma mark - Helpers
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

-(RCTImageLoaderCancellationBlock) loadImageWithURLRequest:(NSURLRequest *)imageURLRequest
                 clipped:(BOOL)clipped
              resizeMode:(RCTResizeMode)resizeMode
           progressBlock:(RCTImageLoaderProgressBlock)progressBlock
        partialLoadBlock:(RCTImageLoaderPartialLoadBlock)partialLoadBlock
         completionBlock:(RCTImageLoaderCompletionBlock)completionBlock
      andOptions:(NSDictionary *)params {
    
    CGSize size = CGSizeZero;
    float width = [RCTConvert float:params[@"width"]];
    float height = [RCTConvert float:params[@"height"]];
    if(width > 0 || height > 0) {
        size = CGSizeMake(width, height);
    }
    
    CGFloat scale = [RCTConvert CGFloat:params[@"scale"]];
    if(scale < 0.1) {
        scale = 1;
    }
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:imageURLRequest.URL resolvingAgainstBaseURL:NO];
    components.queryItems = [self parseParamsToImageLoaderQueryOptions:params];
    
    return [self.bridge.imageLoader loadImageWithURLRequest:[NSURLRequest requestWithURL:components.URL]
                                                size:size
                                               scale:scale
                                             clipped:clipped
                                          resizeMode:resizeMode
                                       progressBlock:progressBlock
                                    partialLoadBlock:partialLoadBlock
                                     completionBlock:completionBlock];
}

-(NSArray<NSURLQueryItem *> *)parseParamsToImageLoaderQueryOptions:(NSDictionary *)params {
    
    NSArray *allowedQueryStringValues = [NSArray arrayWithObjects:@"deliveryMode", @"version", @"resizeMode", @"cropRect", @"contentMode", nil];
    NSMutableArray *queryItems = [NSMutableArray array];
    if(params != nil) {
        for (NSString *key in params) {
            BOOL isAllowed = [allowedQueryStringValues containsObject:key];
            if(isAllowed) {
                [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:params[key]]];
            }
        }
    }
    return queryItems;
}


@end
