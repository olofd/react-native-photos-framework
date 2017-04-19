#import <Foundation/Foundation.h>
@import Photos;
@interface PHCachedFetchResult : NSObject

- (instancetype)initWithFetchResult:(PHFetchResult *)fetcHResult andObjectType:(Class)objectType andOriginalFetchParams:(NSDictionary *)params;

@property Class objectType;
@property (strong) PHFetchResult *fetchResult;
@property (strong) NSDictionary *originalFetchParams;

@end
