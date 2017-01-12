#import "PHOperationResult.h"

@implementation PHOperationResult
- (instancetype)initWithLocalIdentifier:(NSString *)localIdentifier andSuccess:(BOOL)success andError:(NSError *)error
{
    self = [super init];
    if (self) {
        self.localIdentifier = localIdentifier;
        self.success = success;
        self.error = error;
    }
    return self;
}

@end
