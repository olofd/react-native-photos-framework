#import "PHChangeObserver.h"
#import "RCTBridge.h"
#import "RCTBridge+Private.h"
#import "RCTEventDispatcher.h"
#import "RCTCachedFetchResult.h"
#import "PHCollectionService.h"
#import "PHAssetsService.h"
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
                NSMutableArray *removedLocalIdentifiers = [NSMutableArray arrayWithCapacity:changeDetails.removedObjects.count];
                NSArray *removedIndexes = [self indexSetToReturnableArray:changeDetails.removedIndexes];
                for(int i = 0; i < [changeDetails.removedObjects count];i++) {
                    PHObject *object = (PHObject *)[changeDetails.removedObjects objectAtIndex:i];
                    if(object) {
                        [removedLocalIdentifiers addObject:@{
                                                             @"index" : [removedIndexes objectAtIndex:i],
                                                             @"localIdentifier" : [object localIdentifier]
                                                             }];
                    }
                }
                
                
                NSMutableArray *insertedObjects = [NSMutableArray arrayWithCapacity:changeDetails.insertedObjects.count];
                NSArray *insertedIndexes = [self indexSetToReturnableArray:changeDetails.insertedIndexes];
                for(int i = 0; i < [changeDetails.insertedIndexes count];i++) {
                    PHObject *object = (PHObject *)[changeDetails.insertedObjects objectAtIndex:i];
                    if([object isKindOfClass:[PHCollection class]]) {
                        PHCollection *collection = (PHCollection *)object;
                        NSMutableDictionary *insertedObject = [[[PHCollectionService generateAlbumsResponseFromParams:cachedFetchResult.originalFetchParams andAlbums:@[collection] andCacheAssets:NO] objectForKey:@"albums"]
                        objectAtIndex:0];
                        [insertedObjects addObject:@{
                                                    @"index" : [insertedIndexes objectAtIndex:i],
                                                    @"obj" : insertedObject
                                                    }];
                    }
                    
                    if([object isKindOfClass:[PHAsset class]]) {
                        PHAsset *asset = (PHAsset *)object;
                        NSMutableDictionary *insertedObject = [[PHAssetsService assetsArrayToUriArray:@[object] andIncludeMetaData:[RCTConvert BOOL:cachedFetchResult.originalFetchParams[@"includeMetaData"]]] objectAtIndex:0];
                        [insertedObjects addObject:@{
                                                     @"index" : [insertedIndexes objectAtIndex:i],
                                                     @"obj" : insertedObject
                                                     }];
                    }
                }
                
                NSMutableArray *changedObjects = [NSMutableArray arrayWithCapacity:changeDetails.changedObjects.count];
                NSArray *changedIndexes = [self indexSetToReturnableArray:changeDetails.changedIndexes];
                for(int i = 0; i < [changeDetails.changedObjects count];i++) {
                    PHObject *object = (PHObject *)[changeDetails.changedObjects objectAtIndex:i];
                    if([object isKindOfClass:[PHCollection class]]) {
                        PHCollection *collection = (PHCollection *)object;
                        NSMutableDictionary *changedObject = [[[PHCollectionService generateAlbumsResponseFromParams:cachedFetchResult.originalFetchParams andAlbums:@[collection] andCacheAssets:NO] objectForKey:@"albums"] objectAtIndex:0];
                        [changedObjects addObject:@{
                                                    @"index" : [changedIndexes objectAtIndex:i],
                                                    @"obj" : changedObject
                                                    }];
                        
                    }
                    
                    if([object isKindOfClass:[PHAsset class]]) {
                        PHAsset *asset = (PHAsset *)object;
                        NSMutableDictionary *changedObject = [[PHAssetsService assetsArrayToUriArray:@[object] andIncludeMetaData:[RCTConvert BOOL:cachedFetchResult.originalFetchParams[@"includeMetaData"]]] objectAtIndex:0];
                        [changedObjects addObject:@{
                                                     @"index" : [changedIndexes objectAtIndex:i],
                                                     @"obj" : changedObject
                                                     }];
                    }
                    
                }
                NSMutableArray *moves = [NSNull null];
                if(changeDetails.hasMoves) {
                    moves = [NSMutableArray new];
                    [changeDetails enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                        [moves addObject:@(fromIndex)];
                        [moves addObject:@(toIndex)];
                    }];
                }

                [bridge.eventDispatcher sendAppEventWithName:@"RNPFObjectChange"
                                                        body:@{
                                                               @"_cacheKey": uuid,
                                                               @"type" : @"AssetChange",
                                                               @"removedIndexes" : removedIndexes,
                                                               @"insertedIndexes" : insertedIndexes,
                                                               @"changedIndexes" : changedIndexes,
                                                               @"insertedObjects" : insertedObjects,
                                                               @"removedObjects" : removedLocalIdentifiers,
                                                               @"changedObjects" : changedObjects,
                                                               @"hasIncrementalChanges" : @(changeDetails.hasIncrementalChanges),
                                                               @"moves" : moves
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

-(NSString *) cacheFetchResultAndReturnUUID:(PHFetchResult *)fetchResult andObjectType:(Class)objectType andOrginalFetchParams:(NSDictionary *)params {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    [self.fetchResults setObject:[[RCTCachedFetchResult alloc] initWithFetchResult:fetchResult andObjectType:objectType andOriginalFetchParams:params] forKey:uuid];
    return uuid;
}

-(NSString *) cacheFetchResultWithUUID:(PHFetchResult *)fetchResult andObjectType:(Class)objectType andUUID:(NSString *)uuid andOrginalFetchParams:(NSDictionary *)params  {
    [self.fetchResults setObject:[[RCTCachedFetchResult alloc] initWithFetchResult:fetchResult andObjectType:objectType andOriginalFetchParams:params] forKey:uuid];
    return uuid;
}

-(void) removeFetchResultFromCacheWithUUID:(NSString *)uuid {
    [self.fetchResults removeObjectForKey:uuid];
}

-(RCTCachedFetchResult *) getFetchResultFromCacheWithuuid:(NSString *)uuid {
    return [self.fetchResults objectForKey:uuid];
}


@end
