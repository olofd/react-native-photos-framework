#import "PHChangeObserver.h"
#import "RCTBridge.h"
#import "RCTBridge+Private.h"
#import "RCTEventDispatcher.h"
#import "RCTCachedFetchResult.h"
@implementation PHChangeObserver

static id ObjectOrNull(id object)
{
    return object ?: [NSNull null];
}

-(void) receiveTestNotification:(NSNotification*)notification {
    NSLog(@"onRestart");
}

+ (PHChangeObserver *)sharedChangeObserver {
    static PHChangeObserver *sharedChangeObserver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedChangeObserver = [[PHChangeObserver alloc] init];
        [sharedChangeObserver setupChangeObserver];
    });
    return sharedChangeObserver;
}

-(void) cleanCache {
    if(self.fetchResults) {
        self.fetchResults = [[NSMutableDictionary alloc] init];
    }
}

-(void)setupChangeObserver {
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    self.fetchResults = [[NSMutableDictionary alloc] init];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    if(changeInstance != nil) {
        //Unfortunately we seem to have to use a private-api here.
        //Let me know if you know how we can avoid this.
        RCTBridge * bridge = [RCTBridge currentBridge];
        
        NSMutableDictionary<NSString *, RCTCachedFetchResult *> *previousFetches = [[PHChangeObserver sharedChangeObserver] fetchResults];
        [previousFetches enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull uuid, RCTCachedFetchResult * _Nonnull cachedFetchResult, BOOL * _Nonnull stop) {

            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:cachedFetchResult.fetchResult];
            if(changeDetails != nil) {
                [bridge.eventDispatcher sendAppEventWithName:@"RNPFObjectChange"
                                                        body:@{
                                                               @"_cacheKey": uuid,
                                                               @"removedIndexes" : [self indexSetToReturnableArray:changeDetails.removedIndexes],
                                                               @"insertedIndexes" : [self indexSetToReturnableArray:changeDetails.insertedIndexes],
                                                               @"changedIndexes" : [self indexSetToReturnableArray:changeDetails.changedIndexes],
                                                               @"hasIncrementalChanges" : @(changeDetails.hasIncrementalChanges),
                                                               @"hasMoves" : @(changeDetails.hasMoves)
                                                               }];
                cachedFetchResult.fetchResult = [changeDetails fetchResultAfterChanges];
            }
        }];
        
        [bridge.eventDispatcher sendAppEventWithName:@"RNPFLibraryChange"
                                                body:@{}];
    }

}

-(NSArray *)indexSetToReturnableArray:(NSIndexSet *)inputIndexSet {
    NSMutableArray *indexArray = [NSNull null];
    if(inputIndexSet) {
        indexArray = [NSMutableArray arrayWithCapacity:inputIndexSet.count];
        [inputIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [indexArray addObject:@(idx)];
        }];
    }
    return indexArray;
}

-(NSString *) cacheFetchResultAndReturnUUID:(PHFetchResult *)fetchResult andObjectType:(Class)objectType {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    [self.fetchResults setObject:[[RCTCachedFetchResult alloc] initWithFetchResult:fetchResult andObjectType:objectType] forKey:uuid];
    return uuid;
}

-(RCTCachedFetchResult *) getFetchResultFromCacheWithuuid:(NSString *)uuid {
    return [self.fetchResults objectForKey:uuid];
}


@end
