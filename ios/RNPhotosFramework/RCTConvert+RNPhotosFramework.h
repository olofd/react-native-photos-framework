//
//  RCTConvert+RNPhotosFramework.h
//  RNPhotosFramework
//
//  Created by Olof Dahlbom on 2016-10-20.
//  Copyright © 2016 Olof Dahlbom. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Photos;
@interface RCTConvert(ReactNativePhotosFramework)

+ (PHAssetMediaType)PHAssetMediaType:(id)json;
+ (PHAssetMediaSubtype)PHAssetMediaSubtype:(id)json;
+ (PHAssetCollectionType)PHAssetCollectionType:(id)json;
+ (PHAssetCollectionSubtype)PHAssetCollectionSubtype:(id)json;
+ (PHAssetSourceType)PHAssetSourceType:(id)json;

+ (NSArray<NSNumber *> *)PHAssetMediaTypes:(NSArray<NSString *> *)arrayWithMediaTypeStrings;
+(NSMutableArray * ) PHAssetMediaSubtypes:(NSArray<NSString *> *)arrayWithSubMediaTypeStrings;
+(int) PHAssetSourceTypes:(NSArray<NSString *> *)arrayWithSourceTypeStrings;

@end
