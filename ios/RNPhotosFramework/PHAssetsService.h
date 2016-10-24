#import <Foundation/Foundation.h>
@import Photos;
@interface PHAssetsService : NSObject
+(PHFetchResult<PHAsset *> *) getAssetsForParams:(NSDictionary *)params;
+(PHFetchResult<PHAsset *> *) getAssetsForExplicitAssetsParam:(NSDictionary *)params;
+(NSArray<NSDictionary *> *) assetsArrayToUriArray:(NSArray<PHAsset *> *)assetsArray;
+(NSMutableArray<PHAsset *> *) getAssetsForFetchResult:(PHFetchResult *)assetsFetchResult startIndex:(NSUInteger)startIndex endIndex:(NSUInteger)endIndex;
@end
