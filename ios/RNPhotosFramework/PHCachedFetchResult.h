#import <Foundation/Foundation.h>
@import Photos;
@interface PHCachedFetchResult : NSObject

- (instancetype)initWithFetchResult:(PHFetchResult *)fetcHResult andObjectType:(Class)objectType andOriginalFetchParams:(NSDictionary *)params;

@property Class objectType;
@property (strong, nonatomic) PHFetchResult *fetchResult;
@property (strong, nonatomic) NSDictionary *originalFetchParams;

@end
