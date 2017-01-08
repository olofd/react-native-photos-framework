#import <Foundation/Foundation.h>

@interface PHSaveAsset : NSObject
@property (strong, nonatomic) NSString *uri;
@property (strong, nonatomic) NSString *type;
@property BOOL isAsset;
@property BOOL isNetwork;
@end
