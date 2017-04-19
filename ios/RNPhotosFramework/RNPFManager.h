#import <AssetsLibrary/AssetsLibrary.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTConvert.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h> 
#import <React/RCTEventEmitter.h>
#import "PHOperationResult.h"
#import "PHChangeObserver.h"
#import "PHSaveAssetToFileOperationResult.h"

@import UIKit;
@import Photos;

typedef void (^assetFileSaveOperationBlock)(BOOL success, NSError *__nullable error, NSString  * __nullable localIdentifier, NSString  * __nullable fileUrl);
typedef void(^assetsFileSaveCompleteBlock)( NSMutableArray<PHSaveAssetToFileOperationResult *> * _Nonnull  result);


typedef void (^assetOperationBlock)(BOOL success, NSError *__nullable error, NSString  * __nullable localIdentifier);
typedef void (^fileDownloadExtendedPrograessBlock)(NSString * _Nonnull uri, int index, int64_t progress, int64_t total);
typedef void (^fileDownloadExtendedPrograessBlockSimple)(NSString * _Nonnull uri, int index, float progress);

typedef void(^createAssetsCompleteBlock)( NSMutableArray<PHOperationResult *> * _Nonnull  result);

@interface RNPFManager : RCTEventEmitter <RCTBridgeModule> {
    bool hasListeners;
}
@property (nonatomic, strong) __nonnull dispatch_queue_t currentQueue;
@property (nonatomic, strong)  PHChangeObserver * __nullable changeObserver;
@end
