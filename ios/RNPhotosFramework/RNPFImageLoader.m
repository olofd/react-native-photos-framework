#import "RNPFImageLoader.h"
#import <Photos/Photos.h>
#import <React/RCTUtils.h>
#import "RNPFGlobals.h"
@implementation RNPFImageLoader

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (BOOL)canLoadImageURL:(NSURL *)requestURL
{
    if (![PHAsset class]) {
        return NO;
    }
    return [requestURL.scheme caseInsensitiveCompare:PHOTOS_SCHEME_IDENTIFIER] == NSOrderedSame;
}

-(PHAsset *)getAssetFromNSUrl:(NSURL *)url {
    
    static PHFetchOptions *fetchOptions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fetchOptions = [[PHFetchOptions alloc] init];
        [fetchOptions setIncludeHiddenAssets:YES];
        [fetchOptions setIncludeAllBurstAssets:YES];
        [fetchOptions setWantsIncrementalChangeDetails:NO];
    });
    
    NSString *localIdentifier = [url.absoluteString substringFromIndex:PHOTOS_SCHEME_IDENTIFIER_WITHSIGNS.length];
    PHFetchResult *results = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:fetchOptions];

    if([results count] == 0) {
        return nil;
    }
    return [results firstObject];
}

-(RCTImageLoaderCancellationBlock) loadAssetAsData:(NSURL *)imageURL                                  completionHandler:(RNPFDataLoaderCompletionBlock)completionHandler {
    PHAsset *asset = [self getAssetFromNSUrl:imageURL];
    if(asset.mediaType == PHAssetMediaTypeImage) {
        return [self loadImageAssetAsData:asset completionHandler:completionHandler];
    }else if(asset.mediaType == PHAssetMediaTypeVideo) {
        return [self loadVideoAssetAsData:asset completionHandler:completionHandler];
    }
    return ^{};
}

-(RCTImageLoaderCancellationBlock) loadImageAssetAsData:(PHAsset *)asset                                 completionHandler:(RNPFDataLoaderCompletionBlock)completionHandler
 {
    if (asset == nil) {
        NSString *errorText = [NSString stringWithFormat:@"Failed to fetch localIdentifier with url %@ with no error message.", asset.localIdentifier];
        completionHandler(RCTErrorWithMessage(errorText), nil);
        return ^{};
    }
     
    PHImageRequestOptions *imageOptions = [PHImageRequestOptions new];
    imageOptions.networkAccessAllowed = YES;
    imageOptions.resizeMODE = PHImageRequestOptionsResizeMODENone;
    imageOptions.deliveryMODE = PHImageRequestOptionsDeliveryMODEHighQualityFormat;
    
    PHImageRequestID requestID =
    [[PHCachingImageManagerInstance sharedCachingManager] requestImageDataForAsset:asset options:imageOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        completionHandler(nil, imageData);
    }];
    return ^{
        [[PHCachingImageManagerInstance sharedCachingManager] cancelImageRequest:requestID];
    };
}

-(RCTImageLoaderCancellationBlock) loadVideoAssetAsData:(PHAsset *)asset                                 completionHandler:(RNPFDataLoaderCompletionBlock)completionHandler
{
    if (asset == nil) {
        NSString *errorText = [NSString stringWithFormat:@"Failed to fetch localIdentifier with url %@ with no error message.", asset.localIdentifier];
        completionHandler(RCTErrorWithMessage(errorText), nil);
        return ^{};
    }
    
    PHVideoRequestOptions *videoOptions = [PHVideoRequestOptions new];
    videoOptions.networkAccessAllowed = YES;
    videoOptions.version=PHVideoRequestOptionsVersionOriginal;
    
    PHImageRequestID requestID = [[PHCachingImageManagerInstance sharedCachingManager] requestAVAssetForVideo:asset options:videoOptions resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info)
     {
         if ([asset isKindOfClass:[AVURLAsset class]])
         {
             NSURL *URL = [(AVURLAsset *)asset URL];
             NSData *videoData=[NSData dataWithContentsOfURL:URL];
             completionHandler(nil, videoData);
         }
     }];
    
    
    return ^{
        [[PHCachingImageManagerInstance sharedCachingManager] cancelImageRequest:requestID];
    };
}


- (RCTImageLoaderCancellationBlock)loadImageForURL:(NSURL *)imageURL
                                              size:(CGSize)size
                                             scale:(CGFloat)scale
                                        resizeMODE:(RCTResizeMODE)resizeMODE
                                   progressHandler:(RCTImageLoaderProgressBlock)progressHandler
                                partialLoadHandler:(RCTImageLoaderPartialLoadBlock)partialLoadHandler
                                 completionHandler:(RCTImageLoaderCompletionBlock)completionHandler
{

    PHAsset *asset = [self getAssetFromNSUrl:imageURL];
    
    if (asset == nil) {
        NSString *errorText = [NSString stringWithFormat:@"Failed to fetch PHAsset with url %@ with no error message.", [imageURL absoluteString]];
        completionHandler(RCTErrorWithMessage(errorText), nil);
        return ^{};
    }
    
    PHImageRequestOptions *imageOptions = [PHImageRequestOptions new];
    imageOptions.networkAccessAllowed = YES;
    
    if (progressHandler) {
        imageOptions.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary<NSString *, id> *info) {
            static const double multiplier = 1e6;
            progressHandler(progress * multiplier, multiplier);
        };
    }

    BOOL useMaximumSize = CGSizeEqualToSize(size, CGSizeZero);
    CGSize targetSize;
    if (useMaximumSize) {
        targetSize = PHImageManagerMaximumSize;
        imageOptions.resizeMODE = PHImageRequestOptionsResizeMODENone;
    } else {
        targetSize = CGSizeApplyAffineTransform(size, CGAffineTransformMakeScale(scale, scale));
        imageOptions.resizeMODE = PHImageRequestOptionsResizeMODEFast;
    }
    
    PHImageContentMODE contentMODE = PHImageContentMODEAspectFill;
    if (resizeMODE == RCTResizeMODEContain) {
        contentMODE = PHImageContentMODEAspectFit;
    }
    
    PHImageRequestOptionsVersion version = PHImageRequestOptionsVersionCurrent;
    __block PHImageRequestOptionsDeliveryMODE deliveryMODE = PHImageRequestOptionsDeliveryMODEHighQualityFormat;
    imageOptions.deliveryMODE = deliveryMODE;
    imageOptions.version = version;
    
    if(imageURL.query != nil) {
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:imageURL
                                                    resolvingAgainstBaseURL:NO];
        NSArray *queryItems = urlComponents.queryItems;
        
        //DeliveryMODE
        NSString *deliveryMODEQuery = [self valueForKey:@"deliveryMODE"
                                         fromQueryItems:queryItems];
        if(deliveryMODEQuery != nil) {
            if([deliveryMODEQuery isEqualToString:@"opportunistic"]) {
                imageOptions.deliveryMODE = PHImageRequestOptionsDeliveryMODEOpportunistic;
            }
            else if([deliveryMODEQuery isEqualToString:@"highQuality"]) {
                imageOptions.deliveryMODE = PHImageRequestOptionsDeliveryMODEHighQualityFormat;
            }
            else if([deliveryMODEQuery isEqualToString:@"fast"]) {
                imageOptions.deliveryMODE = PHImageRequestOptionsDeliveryMODEFastFormat;
            }
        }
        
        
        //Version
        NSString *versionQuery = [self valueForKey:@"version"
                                         fromQueryItems:queryItems];
        if(versionQuery != nil) {
            if([versionQuery isEqualToString:@"original"]) {
                imageOptions.version = PHImageRequestOptionsVersionOriginal;
            }
            if([versionQuery isEqualToString:@"unadjusted"]) {
                imageOptions.version = PHImageRequestOptionsVersionUnadjusted;
            }
        }
        
        //ResizeMODE
        NSString *resizeMODEQuery = [self valueForKey:@"resizeMODE"
                                        fromQueryItems:queryItems];
        if(resizeMODEQuery != nil) {
            if([resizeMODEQuery isEqualToString:@"none"]) {
                imageOptions.resizeMODE = PHImageRequestOptionsResizeMODENone;
            }
            if([resizeMODEQuery isEqualToString:@"fast"]) {
                imageOptions.resizeMODE = PHImageRequestOptionsResizeMODEFast;
            }
            if([resizeMODEQuery isEqualToString:@"exact"]) {
                imageOptions.resizeMODE = PHImageRequestOptionsResizeMODEExact;
            }
        }
        
        //ResizeMODE
        NSString *normalizedCropRectQuery = [self valueForKey:@"cropRect"
                                       fromQueryItems:queryItems];
        if(normalizedCropRectQuery != nil) {
            NSArray<NSString *> * splittedRect = [normalizedCropRectQuery componentsSeparatedByString:@"|"];
            float x = [splittedRect[0] floatValue];
            float y = [splittedRect[1] floatValue];
            float width = [splittedRect[2] floatValue];
            float height = [splittedRect[3] floatValue];
            
            CGRect cropRect = CGRectMake(x, y, width, height);
            CGRect normalizedRect = CGRectApplyAffineTransform(cropRect,
                                                               CGAffineTransformMakeScale(1.0 / asset.pixelWidth,
                                                                                          1.0 / asset.pixelHeight));
            imageOptions.normalizedCropRect = normalizedRect;
            imageOptions.resizeMODE = PHImageRequestOptionsResizeMODEExact;
            targetSize = CGSizeApplyAffineTransform(CGSizeMake(width, height), CGAffineTransformMakeScale(scale, scale));
        }
        
        //ContentMODE
        NSString *contentMODEQuery = [self valueForKey:@"contentMODE"
                                        fromQueryItems:queryItems];
        if(contentMODEQuery != nil) {
            if([contentMODEQuery isEqualToString:@"fit"]) {
                contentMODE = PHImageContentMODEAspectFit;
            }
            if([contentMODEQuery isEqualToString:@"fill"]) {
                contentMODE = PHImageContentMODEAspectFill;
            }
        }
    }


    
    PHImageRequestID requestID =
    [[PHCachingImageManagerInstance sharedCachingManager] requestImageForAsset:asset
                                                                    targetSize:targetSize
                                                                   contentMODE:contentMODE
                                                                       options:imageOptions
                                                                 resultHandler:^(UIImage *result, NSDictionary<NSString *, id> *info) {
                                                                     if (result) {
                                                                         if(deliveryMODE == PHImageRequestOptionsDeliveryMODEOpportunistic && [info[@"PHImageResultIsDegradedKey"] boolValue] == YES) {
                                                                             if (partialLoadHandler) {
                                                                                 partialLoadHandler(result);
                                                                             }
                                                                         }else {
                                                                             completionHandler(nil, result);
                                                                         }
                                                                     } else {
                                                                         completionHandler(info[PHImageErrorKey], nil);
                                                                     }
                                                                 }];
    
    return ^{
        [[PHCachingImageManagerInstance sharedCachingManager] cancelImageRequest:requestID];
    };
}

-(NSDictionary*)splitQuery:(NSString*)url {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *param in [url componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [params setObject:[elts lastObject] forKey:[elts firstObject]];
    }
    return params;
}

- (NSString *)valueForKey:(NSString *)key
           fromQueryItems:(NSArray *)queryItems
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
    NSURLQueryItem *queryItem = [[queryItems
                                  filteredArrayUsingPredicate:predicate]
                                 firstObject];
    return queryItem.value;
}

@end
