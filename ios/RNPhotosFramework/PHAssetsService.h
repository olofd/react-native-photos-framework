#import <Foundation/Foundation.h>
@import Photos;
@interface PHAssetsService : NSObject
+(PHFetchResult<PHAsset *> *) getAssetsForParams:(NSDictionary *)params;
+(NSArray<NSDictionary *> *) assetsArrayToUriArray:(NSArray<PHAsset *> *)assetsArray andIncludeMetaData:(BOOL)includeMetaData;
+(NSMutableArray<PHAsset *> *) getAssetsForFetchResult:(PHFetchResult *)assetsFetchResult startIndex:(NSUInteger)startIndex endIndex:(NSUInteger)endIndex;
+(PHFetchResult<PHAsset *> *) getAssetsFromArrayOfLocalIdentifiers:(NSArray<NSString *> *)arrayWithLocalIdentifiers;
+(NSMutableDictionary *)extendAssetDicWithAssetMetaData:(NSMutableDictionary *)dictToExtend andPHAsset:(PHAsset *)asset;
@end
