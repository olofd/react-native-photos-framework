#import <Foundation/Foundation.h>

@interface PHCancellationToken : NSObject

@property (strong, atomic) NSString* id;
@property BOOL isCancelled;
@end
