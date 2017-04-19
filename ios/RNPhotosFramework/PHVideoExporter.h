#import <Foundation/Foundation.h>
#import "SDAVAssetExportSession.h"

@interface PHVideoExporter : NSObject

typedef void (^videoExporterCompleteBlock)(BOOL success, NSError *__nullable error, NSURL  * __nullable fileUrl);
typedef void (^videoExporterProgressBlock)(float progress);

-(void (^_Nonnull)()) exportVideoWithAsset:(AVAsset *_Nonnull)avasset andDir:(NSString *_Nonnull)dir andFileName:(NSString *_Nonnull)fileName andPostProcessParams:(NSDictionary *_Nullable)params andProgressBlock:(videoExporterProgressBlock _Nonnull )progressBlock andCompletionBlock:(videoExporterCompleteBlock _Nonnull )completeBlock;

@property (nonatomic, copy) videoExporterProgressBlock _Nonnull progressBlock;
@property (strong, nonatomic) SDAVAssetExportSession * _Nullable encoder;
@end
