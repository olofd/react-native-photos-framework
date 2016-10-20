//
//  RCTConvert+RNPhotosFramework.m
//  RNPhotosFramework
//
//  Created by Olof Dahlbom on 2016-10-20.
//  Copyright © 2016 Olof Dahlbom. All rights reserved.
//

#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
@import Photos;
@implementation RCTConvert(ReactNativePhotosFramework)


RCT_ENUM_CONVERTER(PHAssetMediaType, (@{
                                        
                                        // New values
                                        @"photo": @(PHAssetMediaTypeImage),
                                        @"video": @(PHAssetMediaTypeVideo),
                                        @"audio": @(PHAssetMediaTypeAudio),
                                        @"unknown": @(PHAssetMediaTypeUnknown)
                                        
                                        }), PHAssetMediaTypeImage, integerValue)

RCT_ENUM_CONVERTER(RNPFAssetCountType, (@{
                                        
                                        // New values
                                        @"none": @(RNPFAssetCountTypeNone),
                                        @"estimated": @(RNPFAssetCountTypeEstimated),
                                        @"exact": @(RNPFAssetCountTypeExact)
                                        
                                        }), RNPFAssetCountTypeNone, integerValue)

RCT_ENUM_CONVERTER(PHAssetMediaSubtype, (@{
                                           @"none": @(PHAssetMediaSubtypeNone),
                                           @"photoPanorama": @(PHAssetMediaSubtypePhotoPanorama),
                                           @"photoHDR": @(PHAssetMediaSubtypePhotoHDR),
                                           @"photoScreenshot": @(PHAssetMediaSubtypePhotoScreenshot),
                                           @"photoLive": @(PHAssetMediaSubtypePhotoLive),
                                           @"videoStreamed": @(PHAssetMediaSubtypeVideoStreamed),
                                           @"videoHighFrameRate": @(PHAssetMediaSubtypeVideoHighFrameRate),
                                           @"videoTimeLapse": @(PHAssetMediaSubtypeVideoTimelapse),
                                           
                                           }), PHAssetMediaSubtypeNone, integerValue)

RCT_ENUM_CONVERTER(PHAssetCollectionType, (@{
                                             @"album": @(PHAssetCollectionTypeAlbum),
                                             @"smartAlbum": @(PHAssetCollectionTypeSmartAlbum),
                                             @"moment": @(PHAssetCollectionTypeMoment)
                                             
                                             }), PHAssetCollectionTypeAlbum, integerValue)

RCT_ENUM_CONVERTER(PHAssetCollectionSubtype, (@{
                                                @"any" : @(PHCollectionListSubtypeAny),
                                                @"albumRegular": @(PHAssetCollectionSubtypeAlbumRegular),
                                                @"syncedEvent": @(PHAssetCollectionSubtypeAlbumSyncedEvent),
                                                @"syncedFaces": @(PHAssetCollectionSubtypeAlbumSyncedFaces),
                                                @"syncedAlbum": @(PHAssetCollectionSubtypeAlbumSyncedAlbum),
                                                @"imported": @(PHAssetCollectionSubtypeAlbumImported),
                                                
                                                @"albumMyPhotoStream": @(PHAssetCollectionSubtypeAlbumMyPhotoStream),
                                                @"albumCloudShared": @(PHAssetCollectionSubtypeAlbumCloudShared),
                                                
                                                @"smartAlbumGeneric": @(PHAssetCollectionSubtypeSmartAlbumGeneric),
                                                @"smartAlbumPanoramas": @(PHAssetCollectionSubtypeSmartAlbumPanoramas),
                                                @"smartAlbumVideos": @(PHAssetCollectionSubtypeSmartAlbumVideos),
                                                @"smartAlbumFavorites": @(PHAssetCollectionSubtypeSmartAlbumFavorites),
                                                @"smartAlbumTimelapses": @(PHAssetCollectionSubtypeSmartAlbumTimelapses),
                                                @"smartAlbumAllHidden": @(PHAssetCollectionSubtypeSmartAlbumAllHidden),
                                                @"smartAlbumRecentlyAdded": @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded),
                                                @"smartAlbumBursts": @(PHAssetCollectionSubtypeSmartAlbumBursts),
                                                @"smartAlbumSlomoVideos": @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos),
                                                @"smartAlbumUserLibrary": @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
                                                @"smartAlbumSelfPortraits": @(PHAssetCollectionSubtypeSmartAlbumSelfPortraits),
                                                @"smartAlbumScreenshots": @(PHAssetCollectionSubtypeSmartAlbumScreenshots),
                                                
                                                }), PHAssetCollectionSubtypeAlbumRegular, integerValue)

RCT_ENUM_CONVERTER(PHAssetSourceType, (@{
                                         
                                         // New values
                                         @"none": @(PHAssetSourceTypeNone),
                                         @"userLibrary": @(PHAssetSourceTypeUserLibrary),
                                         @"cloudShared": @(PHAssetSourceTypeCloudShared),
                                         @"itunesSynced": @(PHAssetSourceTypeiTunesSynced)
                                         
                                         }), PHAssetSourceTypeNone, integerValue)

+ (NSArray<NSNumber *> *)PHAssetMediaTypes:(NSArray<NSString *> *)arrayWithMediaTypeStrings
{
    if(arrayWithMediaTypeStrings.count == 0){
        return nil;
    }
    NSMutableArray *arrayWithMediaTypeEnums = [NSMutableArray arrayWithCapacity:arrayWithMediaTypeStrings.count];
    for(int i = 0; i < arrayWithMediaTypeStrings.count;i++) {
        PHAssetMediaType mediaType = [RCTConvert PHAssetMediaType:[arrayWithMediaTypeStrings objectAtIndex:i]];
        [arrayWithMediaTypeEnums addObject:@(mediaType)];
    }
    return arrayWithMediaTypeEnums;
}

+(NSMutableArray * ) PHAssetMediaSubtypes:(NSArray<NSString *> *)arrayWithSubMediaTypeStrings {
    if(arrayWithSubMediaTypeStrings.count == 0){
        return nil;
    }
    NSMutableArray *arrayWithSubMediaTypes = [NSMutableArray array];
    for(int i = 0; i < arrayWithSubMediaTypeStrings.count;i++) {
        PHAssetMediaSubtype mediaSubTyp = [RCTConvert PHAssetMediaSubtype:[arrayWithSubMediaTypeStrings objectAtIndex:i]];
        [arrayWithSubMediaTypes addObject:[NSNumber numberWithInt:mediaSubTyp]];
    }
    return arrayWithSubMediaTypes;
}

+(int) PHAssetSourceTypes:(NSArray<NSString *> *)arrayWithSourceTypeStrings {
    if(arrayWithSourceTypeStrings.count == 0){
        return nil;
    }
    int sourceTypes;
    for(int i = 0; i < arrayWithSourceTypeStrings.count;i++) {
        PHAssetSourceType sourceType = [RCTConvert PHAssetSourceType:[arrayWithSourceTypeStrings objectAtIndex:i]];
        sourceTypes = sourceTypes | sourceType;
    }
    return sourceTypes;
}

@end
