#import "RNPFUrlRequestHandler.h"
#import <ImageIO/ImageIO.h>

#import <React/RCTConvert.h>
#import <React/RCTDefines.h>
#import <React/RCTImageLoader.h>
#import <React/RCTLog.h>
#import <React/RCTNetworking.h>
#import <React/RCTUtils.h>
#import "RNPFGlobals.h"
#import "PHAssetsService.h"
#import "RNPFImageLoader.h"

@implementation RNPFUrlRequestHandler
@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

- (BOOL)canHandleRequest:(NSURLRequest *)request
{
    BOOL handleRequest = [request.URL.scheme caseInsensitiveCompare:PHOTOS_SCHEME_IDENTIFIER] == NSOrderedSame;
    return handleRequest;
}

- (id)sendRequest:(NSURLRequest *)request withDelegate:(id<RCTURLRequestDelegate>)delegate
{
    __block RCTImageLoaderCancellationBlock requestToken;
    RNPFImageLoader *imageLoader = [[RNPFImageLoader alloc] init];
    requestToken = [imageLoader loadAssetAsData:request.URL completionHandler:^(NSError *error, NSData *assetData) {
        if (error) {
            [delegate URLRequest:requestToken didCompleteWithError:error];
            return;
        }
        [delegate URLRequest:requestToken didReceiveData:assetData];
        [delegate URLRequest:requestToken didCompleteWithError:nil];
    }];
    return requestToken;
}

- (float) handlerPriority {
    return 99;
}


@end
