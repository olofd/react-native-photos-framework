#import <Foundation/Foundation.h>
@import Photos;
@interface PHAssetsService : NSObject
+(PHFetchResult<PHAsset *> *) getAssetsForParams:(NSDictionary *)params;
+(NSArray<NSDictionary *> *) assetsArrayToUriArray:(NSArray<PHAsset *> *)assetsArray andIncludeMetaData:(BOOL)includeMetaData;
+(NSMutableArray<PHAsset *> *) getAssetsForFetchResult:(PHFetchResult *)assetsFetchResult startIndex:(int)startIndex endIndex:(int)endIndex andReverseIndices:(BOOL)reverseIndices;
+(PHFetchResult<PHAsset *> *) getAssetsFromArrayOfLocalIdentifiers:(NSArray<NSString *> *)arrayWithLocalIdentifiers;
+(NSMutableDictionary *)extendAssetDicWithAssetMetaData:(NSMutableDictionary *)dictToExtend andPHAsset:(PHAsset *)asset;
+(void)deleteAssets:(NSArray<PHAsset *> *)assetsToDelete andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSArray<NSString *> * localIdentifiers))completeBlock;
@end
