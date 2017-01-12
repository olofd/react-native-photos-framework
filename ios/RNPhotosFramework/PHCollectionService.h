#import <Foundation/Foundation.h>
#import <React/RCTConvert.h>
#import "RCTConvert+RNPhotosFramework.h"
@import Photos;
@interface PHCollectionService : NSObject
NS_ASSUME_NONNULL_BEGIN

+(NSMutableDictionary *) getAlbums:(NSDictionary *)params;

+(PHAssetCollection *) getAssetCollectionForParams:(NSDictionary *)params;

+(void) addAssets:(PHFetchResult<PHAsset *> *)assets toAssetCollection:(PHAssetCollection *)assetCollection andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock;

+(void) removeAssets:(PHFetchResult<PHAsset *> *)assets fromAssetCollection:(PHAssetCollection *)assetCollection andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock;

+(PHFetchResult<PHAssetCollection *> *)getUserAlbumsByTitles:(NSArray *)titles withParams:(NSDictionary *)params;

+(NSMutableDictionary *) generateCollectionResponseWithCollections:(PHFetchResult<PHCollection *> *)collections andParams:(NSDictionary *)params;

+(NSMutableDictionary *)generateAlbumsResponseFromParams:(NSDictionary *)params andAlbums:(PHFetchResult<PHCollection *> *)albums andCacheAssets:(BOOL)cacheAssets;

+(void) createAlbumsWithTitles:(NSArray *)titles andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSArray<NSString *> * localIdentifier))completeBlock;

+(void) deleteAlbumsWithLocalIdentifers:(NSArray *)localIdentifiers andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock;

+(void) saveImage:(UIImage *)image toAlbum:(NSString *)albumLocalIdentifier andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSString *__nullable localIdentifier))completeBlock;
+(PHAssetCollection *) getAssetForLocalIdentifer:(NSString *)localIdentifier;

+(PHFetchResult<PHAssetCollection *> *)getAlbumsWithLocalIdentifiers:(NSArray<NSString *> *)localIdentifiers andParams:(NSDictionary * __nullable)params;

NS_ASSUME_NONNULL_END

@end
