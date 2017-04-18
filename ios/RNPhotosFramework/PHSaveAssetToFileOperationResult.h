#import <Foundation/Foundation.h>
#import "PHOperationResult.h"

@interface PHSaveAssetToFileOperationResult : PHOperationResult

- (instancetype)initWithLocalIdentifier:(NSString *)localIdentifier fileUrl:(NSString *)fileUrl andSuccess:(BOOL)success andError:(NSError *)error;

@property (strong, nonatomic) NSString *fileUrl;

@end
