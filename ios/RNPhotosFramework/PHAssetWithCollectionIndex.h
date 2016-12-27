#import <Foundation/Foundation.h>
@import Photos;
@interface PHAssetWithCollectionIndex : NSObject

- (instancetype)initWithAsset:(PHAsset *)asset andCollectionIndex:(NSNumber *)index;
+ (NSArray<PHAsset *> *) toAssetsArray:(NSArray<PHAssetWithCollectionIndex *> *)assetsWithIndexArray;

@property (strong, nonatomic) PHAsset *asset;
@property (strong, nonatomic) NSNumber *collectionIndex;

@end
