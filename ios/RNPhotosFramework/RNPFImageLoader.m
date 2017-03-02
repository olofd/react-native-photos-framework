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
    imageOptions.resizeMode = PHImageRequestOptionsResizeModeNone;
    imageOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
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
                                        resizeMode:(RCTResizeMode)resizeMode
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
        imageOptions.resizeMode = PHImageRequestOptionsResizeModeNone;
    } else {
        targetSize = CGSizeApplyAffineTransform(size, CGAffineTransformMakeScale(scale, scale));
        imageOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    }
    
    PHImageContentMode contentMode = PHImageContentModeAspectFill;
    if (resizeMode == RCTResizeModeContain) {
        contentMode = PHImageContentModeAspectFit;
    }
    
    __block PHImageRequestOptionsDeliveryMode deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    imageOptions.deliveryMode = deliveryMode;
    
    if(imageURL.query != nil) {
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:imageURL
                                                    resolvingAgainstBaseURL:NO];
        NSArray *queryItems = urlComponents.queryItems;
        NSString *deliveryModeQuery = [self valueForKey:@"deliveryMode"
                                         fromQueryItems:queryItems];
        if(deliveryModeQuery != nil) {
            if([deliveryModeQuery isEqualToString:@"opportunistic"]) {
                deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            }
            else if([deliveryModeQuery isEqualToString:@"highQuality"]) {
                deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            }
            else if([deliveryModeQuery isEqualToString:@"fast"]) {
                deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
            }
        }
    }
    
    
    PHImageRequestID requestID =
    [[PHCachingImageManagerInstance sharedCachingManager] requestImageForAsset:asset
                                                                    targetSize:targetSize
                                                                   contentMode:contentMode
                                                                       options:imageOptions
                                                                 resultHandler:^(UIImage *result, NSDictionary<NSString *, id> *info) {
                                                                     if (result) {
                                                                         if(deliveryMode == PHImageRequestOptionsDeliveryModeOpportunistic && [info[@"PHImageResultIsDegradedKey"] boolValue] == YES) {
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
