#import "PHChangeObserver.h"
#import "RCTBridge.h"
#import "RCTBridge+Private.h"
#import "RCTEventDispatcher.h"

@implementation PHChangeObserver

static id ObjectOrNull(id object)
{
    return object ?: [NSNull null];
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
    //Unfortunately we seem to have to use a private-api here.
    //Let me know if you know how we can avoid this.

    RCTBridge * bridge = [RCTBridge currentBridge];

    NSMutableDictionary<NSString *, PHFetchResult *> *previousFetches = [[PHChangeObserver sharedChangeObserver] fetchResults];
    [previousFetches enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull uuid, PHFetchResult * _Nonnull fetchResult, BOOL * _Nonnull stop) {
        PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:fetchResult];
        if(changeDetails != nil) {
            [bridge.eventDispatcher sendAppEventWithName:@"RNPFChange"
                                                    body:@{
                                                           @"uuid": uuid,
                                                           @"removedIndexes" : [self indexSetToReturnableArray:changeDetails.removedIndexes],
                                                           @"insertedIndexes" : [self indexSetToReturnableArray:changeDetails.insertedIndexes],
                                                           @"changedIndexes" : [self indexSetToReturnableArray:changeDetails.changedIndexes]
                                                           }];
            [previousFetches setObject:[changeDetails fetchResultAfterChanges] forKey:uuid];
        }
    }];
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

-(NSString *) cacheFetchResultAndReturnUUID:(PHFetchResult *)fetchResult {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSMutableDictionary<NSString *, PHFetchResult *> *previousFetchResults = self.fetchResults;
    [previousFetchResults setObject:fetchResult forKey:uuid];
    return uuid;
}

-(PHFetchResult *) getFetchResultFromCacheWithuuid:(NSString *)uuid {
    NSMutableDictionary<NSString *, PHFetchResult *> *previousFetchResults = self.fetchResults;
    return [previousFetchResults objectForKey:uuid];
}


@end
