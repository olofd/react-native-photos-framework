#import "PHSaveAssetToFileOperationResult.h"

@implementation PHSaveAssetToFileOperationResult

- (instancetype)initWithLocalIdentifier:(NSString *)localIdentifier fileUrl:(NSString *)fileUrl andSuccess:(BOOL)success andError:(NSError *)error
{
    self = [super initWithLocalIdentifier:localIdentifier andSuccess:success andError:error];
    if (self) {
        self.fileUrl = fileUrl;
    }
    return self;
}

@end
