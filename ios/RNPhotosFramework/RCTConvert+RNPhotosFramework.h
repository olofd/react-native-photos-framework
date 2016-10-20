//
//  RCTConvert+RNPhotosFramework.h
//  RNPhotosFramework
//
//  Created by Olof Dahlbom on 2016-10-20.
//  Copyright © 2016 Olof Dahlbom. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Photos;

typedef NS_ENUM(NSInteger, RNPFAssetCountType) {
    RNPFAssetCountTypeNone = 1,
    RNPFAssetCountTypeEstimated = 2,
    RNPFAssetCountTypeExact = 3,
};

@interface RCTConvert(ReactNativePhotosFramework)

+ (RNPFAssetCountType)RNPFAssetCountType:(id)json;
+ (PHAssetMediaType)PHAssetMediaType:(id)json;
+ (PHAssetMediaSubtype)PHAssetMediaSubtype:(id)json;
+ (PHAssetCollectionType)PHAssetCollectionType:(id)json;
+ (PHAssetCollectionSubtype)PHAssetCollectionSubtype:(id)json;
+ (PHAssetSourceType)PHAssetSourceType:(id)json;

+ (NSArray<NSNumber *> *)PHAssetMediaTypes:(NSArray<NSString *> *)arrayWithMediaTypeStrings;
+(NSMutableArray * ) PHAssetMediaSubtypes:(NSArray<NSString *> *)arrayWithSubMediaTypeStrings;
+(int) PHAssetSourceTypes:(NSArray<NSString *> *)arrayWithSourceTypeStrings;

@end
