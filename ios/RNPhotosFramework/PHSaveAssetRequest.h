#import <Foundation/Foundation.h>

@interface PHSaveAssetRequest : NSObject
@property (strong, nonatomic) NSURLRequest *uri;
@property (strong, nonatomic) NSString *type;
@end
