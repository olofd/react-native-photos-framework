#import <React/RCTImageLoader.h>
#import "PHCachingImageManagerInstance.h"

typedef void (^RNPFDataLoaderCompletionBlock)(NSError *error, NSData *data);

@interface RNPFImageLoader : NSObject <RCTImageURLLoader>

-(RCTImageLoaderCancellationBlock) loadAssetAsData:(NSURL *)imageURL                                  completionHandler:(RNPFDataLoaderCompletionBlock)completionHandler;

@end
