#import "PHAssetWithCollectionIndex.h"

@implementation PHAssetWithCollectionIndex

- (instancetype)initWithAsset:(PHAsset *)asset andCollectionIndex:(NSNumber *)index
{
    self = [super init];
    if (self) {
        self.asset = asset;
        self.collectionIndex = index;
    }
    return self;
}

+ (NSArray<PHAsset *> *) toAssetsArray:(NSArray<PHAssetWithCollectionIndex *> *)assetsWithIndexArray {
    if(assetsWithIndexArray == nil) {
        return nil;
    }
    NSMutableArray *arrayWithAssets = [NSMutableArray new];
    [assetsWithIndexArray enumerateObjectsUsingBlock:^(PHAssetWithCollectionIndex * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [arrayWithAssets addObject:[obj asset]];
    }];
    return arrayWithAssets;
}


@end
