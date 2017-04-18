#import <Foundation/Foundation.h>
@import Photos;
@interface PHAssetWithCollectionIndex : NSObject

- (instancetype)initWithAsset:(PHAsset *)asset andCollectionIndex:(NSNumber *)index;
+ (NSArray<PHAsset *> *) toAssetsArray:(NSArray<PHAssetWithCollectionIndex *> *)assetsWithIndexArray;

@property (atomic, strong) PHAsset *asset;
@property (strong) NSNumber *collectionIndex;

@end
