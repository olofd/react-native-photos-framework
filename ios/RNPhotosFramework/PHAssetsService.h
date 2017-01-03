#import <Foundation/Foundation.h>
#import "PHAssetWithCollectionIndex.h"
@import Photos;
@interface PHAssetsService : NSObject

+(PHFetchResult<PHAsset *> *) getAssetsForParams:(NSDictionary *)params;
+(NSArray<NSDictionary *> *) assetsArrayToUriArray:(NSArray<PHAssetWithCollectionIndex *> *)assetsArray andIncludeMetaData:(BOOL)includeMetaData;
+(NSMutableArray<PHAssetWithCollectionIndex*> *) getAssetsForFetchResult:(PHFetchResult *)assetsFetchResult startIndex:(int)startIndex endIndex:(int)endIndex assetDisplayStartToEnd:(BOOL)assetDisplayStartToEnd andAssetDisplayBottomUp:(BOOL)assetDisplayBottomUp;
+(NSMutableArray<PHAssetWithCollectionIndex*> *) getAssetsForFetchResult:(PHFetchResult *)assetsFetchResult atIndecies:(NSArray<NSNumber *> *)indecies;
+(PHFetchResult<PHAsset *> *) getAssetsFromArrayOfLocalIdentifiers:(NSArray<NSString *> *)arrayWithLocalIdentifiers;
+(NSMutableDictionary *)extendAssetDicWithAssetMetaData:(NSMutableDictionary *)dictToExtend andPHAsset:(PHAsset *)asset;
+(void)deleteAssets:(PHFetchResult<PHAsset *> *)assetsToDelete andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSArray<NSString *> * localIdentifiers))completeBlock;

@end
