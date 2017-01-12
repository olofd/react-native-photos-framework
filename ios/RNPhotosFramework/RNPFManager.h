#import <AssetsLibrary/AssetsLibrary.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTConvert.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h> 
#import <React/RCTEventEmitter.h>
#import "PHOperationResult.h"
#import "PHChangeObserver.h"

@import UIKit;
@import Photos;

typedef void (^assetOperationBlock)(BOOL success, NSError *__nullable error, NSString  * __nullable localIdentifier);
typedef void (^fileDownloadExtendedPrograessBlock)(NSString * _Nonnull uri, int index,int64_t progress, int64_t total);
typedef void(^createAssetsCompleteBlock)( NSMutableArray<PHOperationResult *> * _Nonnull  result);

@interface RNPFManager : RCTEventEmitter <RCTBridgeModule>
@property (nonatomic, strong) __nonnull dispatch_queue_t currentQueue;
@property (nonatomic, strong)  PHChangeObserver * __nullable changeObserver;
@end
