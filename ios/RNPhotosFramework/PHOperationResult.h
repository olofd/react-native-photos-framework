#import <Foundation/Foundation.h>

@interface PHOperationResult : NSObject

- (instancetype)initWithLocalIdentifier:(NSString *)localIdentifier andSuccess:(BOOL)success andError:(NSError *)error;

@property (strong, nonatomic) NSString *localIdentifier;
@property (strong, nonatomic) NSError *error;
@property (assign, nonatomic) BOOL success;

@end
