#import <Foundation/Foundation.h>
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
@import Photos;
@interface PHCollectionService : NSObject
+(NSMutableDictionary *) getAlbums:(NSDictionary *)params;
+(PHAssetCollection *) getAssetCollectionForParams:(NSDictionary *)params;
+(void) addAssets:(NSArray<PHAsset *> *)assets toAssetCollection:(PHAssetCollection *)assetCollection andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock;
+(void) removeAssets:(NSArray<PHAsset *> *)assets fromAssetCollection:(PHAssetCollection *)assetCollection andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error))completeBlock;
+(PHFetchResult<PHAssetCollection *> *)getUserAlbumsTiteled:(NSString *)title withParams:(NSDictionary *)params;
+(NSMutableDictionary *) generateCollectionResponseWithCollections:(PHFetchResult<PHAssetCollection *> *)collections andParams:(NSDictionary *)params;
+(void) createAlbumWithTitle:(NSString *)title andCompleteBLock:(nullable void(^)(BOOL success, NSError *__nullable error, NSString *__nullable localIdentifier))completeBlock;
@end
