#import "PHCache.h"

@implementation PHCache

+ (PHCache *)sharedPHCache {
    static PHCache *sharedPHCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPHCache = [[PHCache alloc] init];
        sharedPHCache.fetchResults = [[NSMutableDictionary alloc] init];
    });
    return sharedPHCache;
}

-(void) cleanCache {
    if(self.fetchResults) {
        self.fetchResults = [[NSMutableDictionary alloc] init];
    }
}

-(NSString *) cacheFetchResultAndReturnUUID:(PHFetchResult *)fetchResult andObjectType:(Class)objectType andOrginalFetchParams:(NSDictionary *)params {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    @synchronized (self.fetchResults) {
        [self.fetchResults setObject:[[PHCachedFetchResult alloc] initWithFetchResult:fetchResult andObjectType:objectType andOriginalFetchParams:params] forKey:uuid];
    }
    return uuid;
}

-(NSString *) cacheFetchResultWithUUID:(PHFetchResult *)fetchResult andObjectType:(Class)objectType andUUID:(NSString *)uuid andOrginalFetchParams:(NSDictionary *)params  {
    @synchronized (self.fetchResults) {
        [self.fetchResults setObject:[[PHCachedFetchResult alloc] initWithFetchResult:fetchResult andObjectType:objectType andOriginalFetchParams:params] forKey:uuid];
    }
    return uuid;
}

-(void) removeFetchResultFromCacheWithUUID:(NSString *)uuid {
    @synchronized (self.fetchResults) {
        [self.fetchResults removeObjectForKey:uuid];
    }
}

-(PHCachedFetchResult *) getFetchResultFromCacheWithuuid:(NSString *)uuid {
    @synchronized (self.fetchResults) {
        return [self.fetchResults objectForKey:uuid];
    }
}

@end
