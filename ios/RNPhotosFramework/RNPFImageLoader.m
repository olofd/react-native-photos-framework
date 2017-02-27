#import "RNPFImageLoader.h"
#import <Photos/Photos.h>
#import <React/RCTUtils.h>

@implementation RNPFImageLoader

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

#pragma mark - RCTImageLoader
#define PHOTOS_SCHEME_IDENTIFIER @"photos"
NSString *const SCHEME_WITH_SIGNS = PHOTOS_SCHEME_IDENTIFIER @"://";

- (BOOL)canLoadImageURL:(NSURL *)requestURL
{
    if (![PHAsset class]) {
        return NO;
    }
    return [requestURL.scheme caseInsensitiveCompare:PHOTOS_SCHEME_IDENTIFIER] == NSOrderedSame;
}

- (RCTImageLoaderCancellationBlock)loadImageForURL:(NSURL *)imageURL
                                              size:(CGSize)size
                                             scale:(CGFloat)scale
                                        resizeMode:(RCTResizeMode)resizeMode
                                   progressHandler:(RCTImageLoaderProgressBlock)progressHandler
                                partialLoadHandler:(RCTImageLoaderPartialLoadBlock)partialLoadHandler
                                 completionHandler:(RCTImageLoaderCompletionBlock)completionHandler
{
    static PHFetchOptions *fetchOptions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fetchOptions = [[PHFetchOptions alloc] init];
        [fetchOptions setIncludeHiddenAssets:YES];
        [fetchOptions setIncludeAllBurstAssets:YES];
        [fetchOptions setWantsIncrementalChangeDetails:NO];
    });
    
    NSString *localIdentifier = [imageURL.absoluteString substringFromIndex:SCHEME_WITH_SIGNS.length];
    PHFetchResult *results = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:fetchOptions];
    
    if (results.count == 0) {
        NSString *errorText = [NSString stringWithFormat:@"Failed to fetch PHAsset with local identifier %@ with no error message.", localIdentifier];
        completionHandler(RCTErrorWithMessage(errorText), nil);
        return ^{};
    }
    
    PHAsset *asset = [results firstObject];
    PHImageRequestOptions *imageOptions = [PHImageRequestOptions new];
    
    // Allow PhotoKit to fetch images from iCloud
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
