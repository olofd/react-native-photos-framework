#import <Foundation/Foundation.h>
#import "PHSaveAssetRequest.h"
@import Photos;

typedef NS_ENUM(NSInteger, RNPFAssetCountType) {
    RNPFAssetCountTypeEstimated = 1,
    RNPFAssetCountTypeExact = 2,
};

@interface RCTConvert(ReactNativePhotosFramework)

+ (RNPFAssetCountType)RNPFAssetCountType:(id)json;
+ (PHAssetMediaType)PHAssetMediaType:(id)json;
+ (PHAssetMediaSubtype)PHAssetMediaSubtype:(id)json;
+ (PHAssetCollectionType)PHAssetCollectionType:(id)json;
+ (PHAssetCollectionSubtype)PHAssetCollectionSubtype:(id)json;
+ (PHAssetSourceType)PHAssetSourceType:(id)json;
+ (PHAuthorizationStatus)PHAuthorizationStatus:(id)json;
+ (PHAssetResourceType)PHAssetResourceType:(id)json;


+ (NSArray<NSNumber *> *)PHAssetMediaTypes:(NSArray<NSString *> *)arrayWithMediaTypeStrings;
+ (NSMutableArray * ) PHAssetMediaSubtypes:(NSArray<NSString *> *)arrayWithSubMediaTypeStrings;
+ (int) PHAssetSourceTypes:(NSArray<NSString *> *)arrayWithSourceTypeStrings;
+ (PHSaveAssetRequest *)PHSaveAssetRequest:(id)json;
+ (NSArray<PHSaveAssetRequest *> *)PHSaveAssetRequestArray:(id)json;

+ (NSDictionary *)RNPFAssetCountTypeValuesReversed;
+ (NSDictionary *)PHAssetMediaTypeValuesReversed;
+ (NSDictionary *)PHAssetMediaSubtypeValuesReversed;
+ (NSDictionary *)PHAssetBurstSelectionTypeValuesReversed;
+ (NSDictionary *)PHAssetSourceTypeValuesReversed;
+ (NSDictionary *)PHAssetCollectionTypeValuesReversed;
+ (NSDictionary *)PHAssetCollectionSubtypeValuesReversed;
+ (NSDictionary *)PHAuthorizationStatusValuesReversed;
+ (NSDictionary *)PHAssetResourceTypeValuesReversed;

+ (CLLocation *)CLLocation:(id)json;

@end
