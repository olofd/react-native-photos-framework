#import <Foundation/Foundation.h>
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
@import Photos;
@interface PHCollectionService : NSObject
+(NSMutableDictionary *) getAlbums:(NSDictionary *)params;
+(PHAssetCollection *) getAssetCollectionForParams:(NSDictionary *)params;
+(void) addAssets:(NSArray<PHAsset *> *)assets toAssetCollection:(PHAssetCollection *)assetCollection andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock;
+(void) removeAssets:(NSArray<PHAsset *> *)assets fromAssetCollection:(PHAssetCollection *)assetCollection andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock;
+(PHFetchResult<PHAssetCollection *> *)getUserAlbumsByTitles:(NSArray *)titles withParams:(NSDictionary *)params;
+(NSMutableDictionary *) generateCollectionResponseWithCollections:(PHFetchResult<PHAssetCollection *> *)collections andParams:(NSDictionary *)params;
+(NSMutableDictionary *)generateAlbumsResponseFromParams:(NSDictionary *)params andAlbums:(PHFetchResult<PHAssetCollection *> *)albums andCacheAssets:(BOOL)cacheAssets;
+(void) createAlbumsWithTitles:(NSArray *)titles andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSArray<NSString *> * localIdentifier))completeBlock;
+(void) deleteAlbumsWithLocalIdentifers:(NSMutableArray *)localIdentifiers andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock;
+(void) saveImage:(UIImage *)image toAlbum:(PHCollection *)album andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSString *__nullable localIdentifier))completeBlock;
+(PHAssetCollection *) getAssetForLocalIdentifer:(NSString *)localIdentifier;
+(PHFetchResult<PHAssetCollection *> *)getAlbumsWithLocalIdentifiers:(NSArray<NSString *> *)localIdentifiers andParams:(NSDictionary *)params;
@end
