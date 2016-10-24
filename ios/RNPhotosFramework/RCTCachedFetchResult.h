#import <Foundation/Foundation.h>
@import Photos;
@interface RCTCachedFetchResult : NSObject

- (instancetype)initWithFetchResult:(PHFetchResult *)fetcHResult andObjectType:(Class)objectType;

@property Class objectType;
@property (strong, nonatomic) PHFetchResult *fetchResult;
@end
