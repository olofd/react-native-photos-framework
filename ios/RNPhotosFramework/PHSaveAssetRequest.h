#import <Foundation/Foundation.h>
#import "PHSaveAsset.h"
@interface PHSaveAssetRequest : NSObject
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) PHSaveAsset *source;
@end


