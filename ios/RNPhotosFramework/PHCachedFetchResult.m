#import "PHCachedFetchResult.h"

@implementation PHCachedFetchResult
- (instancetype)initWithFetchResult:(PHFetchResult *)fetcHResult andObjectType:(Class)objectType andOriginalFetchParams:(NSDictionary *)params
{
    self = [super init];
    if (self) {
        self.fetchResult = fetcHResult;
        self.objectType = objectType;
        self.originalFetchParams = params;
    }
    return self;
}
@end
