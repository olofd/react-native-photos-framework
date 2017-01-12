#import "PHChangeObserver.h"
#import <React/RCTBridge.h>
#import <React/RCTBridge+Private.h>
#import <React/RCTEventDispatcher.h>
#import "PHCachedFetchResult.h"
#import "PHCollectionService.h"
#import "PHAssetsService.h"
#import "PHCache.h"
@implementation PHChangeObserver

- (instancetype)initWithEventEmitter:(RCTEventEmitter *)eventEmitter
{
    self = [super init];
    if (self) {
        self.eventEmitter = eventEmitter;
        [self setupChangeObserver];
    }
    return self;
}

-(void)setupChangeObserver {
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

-(void)removeChangeObserver {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    if(changeInstance != nil) {
        
        NSMutableDictionary<NSString *, PHCachedFetchResult *> *previousFetches = [[PHCache sharedPHCache] fetchResults];
        
        [previousFetches enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull uuid, PHCachedFetchResult * _Nonnull cachedFetchResult, BOOL * _Nonnull stop) {
            
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:cachedFetchResult.fetchResult];
            
            if(changeDetails != nil) {
                
                
                BOOL trackInsertsAndDeletes = [RCTConvert BOOL:cachedFetchResult.originalFetchParams[@"trackInsertsAndDeletes"]];
                BOOL trackChanges = [RCTConvert BOOL:cachedFetchResult.originalFetchParams[@"trackChanges"]];
                
                NSMutableArray *removedLocalIdentifiers = (NSMutableArray *)[NSNull null];
                NSArray *removedIndexes = (NSArray *)[NSNull null];
                
                NSMutableArray *insertedObjects = (NSMutableArray *)[NSNull null];
                NSArray *insertedIndexes = (NSArray *)[NSNull null];
                
                if(trackInsertsAndDeletes) {
                    removedLocalIdentifiers = [NSMutableArray arrayWithCapacity:changeDetails.removedObjects.count];
                    removedIndexes = [self indexSetToReturnableArray:changeDetails.removedIndexes];
                    for(int i = 0; i < [changeDetails.removedObjects count];i++) {
                        PHObject *object = (PHObject *)[changeDetails.removedObjects objectAtIndex:i];
                        if(object) {
                            [removedLocalIdentifiers addObject:@{
                                                                 @"index" : [removedIndexes objectAtIndex:i],
                                                                 @"localIdentifier" : [object localIdentifier]
                                                                 }];
                        }
                    }
                    
                    
                    insertedObjects = [NSMutableArray arrayWithCapacity:changeDetails.insertedObjects.count];
                    insertedIndexes = [self indexSetToReturnableArray:changeDetails.insertedIndexes];
                    for(int i = 0; i < [changeDetails.insertedIndexes count];i++) {
                        PHObject *object = (PHObject *)[changeDetails.insertedObjects objectAtIndex:i];
                        if([object isKindOfClass:[PHCollection class]]) {
                            PHCollection *collection = (PHCollection *)object;
                            NSMutableDictionary *insertedObject = [[[PHCollectionService generateAlbumsResponseFromParams:cachedFetchResult.originalFetchParams andAlbums:(PHFetchResult *)@[collection] andCacheAssets:NO] objectForKey:@"albums"]
                                                                   objectAtIndex:0];
                            [insertedObjects addObject:@{
                                                         @"index" : [insertedIndexes objectAtIndex:i],
                                                         @"obj" : insertedObject
                                                         }];
                        }
                        
                        if([object isKindOfClass:[PHAsset class]]) {
                            BOOL includeMetadata = [RCTConvert BOOL:cachedFetchResult.originalFetchParams[@"includeMetadata"]];
                            BOOL includeResourcesMetadata = [RCTConvert BOOL:cachedFetchResult.originalFetchParams[@"includeResourcesMetadata"]];
                            
                            NSDictionary *insertedObject = [[PHAssetsService assetsArrayToUriArray:@[object] andincludeMetadata:includeMetadata andIncludeAssetResourcesMetadata:includeResourcesMetadata] objectAtIndex:0];
                            NSNumber *collectionIndex = [insertedIndexes objectAtIndex:i];
                            NSMutableDictionary *mutableInsertedDict = [insertedObject mutableCopy];
                            [mutableInsertedDict setObject:collectionIndex forKey:@"collectionIndex"];
                            [insertedObjects addObject:@{
                                                         @"index" : collectionIndex,
                                                         @"obj" : mutableInsertedDict
                                                         }];
                        }
                    }
                }
                
                NSMutableArray *changedObjects = (NSMutableArray *)[NSNull null];
                NSArray *changedIndexes = (NSArray *)[NSNull null];
                if(trackChanges) {
                    changedObjects = [NSMutableArray arrayWithCapacity:changeDetails.changedObjects.count];
                    changedIndexes = [self indexSetToReturnableArray:changeDetails.changedIndexes];
                    
                    for(int i = 0; i < [changeDetails.changedObjects count];i++) {
                        PHObject *object = (PHObject *)[changeDetails.changedObjects objectAtIndex:i];
                        if([object isKindOfClass:[PHCollection class]]) {
                            PHCollection *collection = (PHCollection *)object;
                            NSMutableDictionary *changedObject = [[[PHCollectionService generateAlbumsResponseFromParams:cachedFetchResult.originalFetchParams andAlbums:(PHFetchResult *)@[collection] andCacheAssets:NO] objectForKey:@"albums"] objectAtIndex:0];
                            [changedObjects addObject:@{
                                                        @"index" : [changedIndexes objectAtIndex:i],
                                                        @"obj" : changedObject
                                                        }];
                            
                        }
                        
                        if([object isKindOfClass:[PHAsset class]]) {
                            
                            BOOL includeMetadata = [RCTConvert BOOL:cachedFetchResult.originalFetchParams[@"includeMetadata"]];
                            BOOL includeResourcesMetadata = [RCTConvert BOOL:cachedFetchResult.originalFetchParams[@"includeResourcesMetadata"]];
                            NSDictionary *changedObject = [[PHAssetsService assetsArrayToUriArray:@[object] andincludeMetadata:includeMetadata andIncludeAssetResourcesMetadata:includeResourcesMetadata] objectAtIndex:0];
                            NSNumber *collectionIndex = [changedIndexes objectAtIndex:i];
                            NSMutableDictionary *mutableChangedDict = [changedObject mutableCopy];
                            [mutableChangedDict setObject:collectionIndex forKey:@"collectionIndex"];
                            [changedObjects addObject:@{
                                                        @"index" : collectionIndex,
                                                        @"obj" : mutableChangedDict
                                                        }];
                        }
                        
                    }
                }
                
                if(trackInsertsAndDeletes || trackChanges) {
                    NSMutableArray *moves = (NSMutableArray *)[NSNull null];
                    if(changeDetails.hasMoves) {
                        moves = [NSMutableArray new];
                        [changeDetails enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                            [moves addObject:@(fromIndex)];
                            [moves addObject:@(toIndex)];
                        }];
                    }
                    
                    BOOL hasMoves = ![moves isEqual:[NSNull null]] && moves.count != 0;
                    
                    BOOL shouldNotifyForInsertOrDelete = ((
                                                           (![insertedIndexes isEqual:[NSNull null]] && insertedIndexes.count != 0) ||
                                                           (![removedIndexes isEqual:[NSNull null]] && removedIndexes.count != 0) ||
                                                           hasMoves) && trackInsertsAndDeletes);
                    
                    BOOL shouldNotifyForChange = ((
                                                   (![changedIndexes isEqual:[NSNull null]] && changedIndexes.count != 0) ||
                                                   hasMoves) && trackChanges);
                    
                    if(shouldNotifyForInsertOrDelete || shouldNotifyForChange){
                        if(self.eventEmitter) {
                            [self.eventEmitter sendEventWithName:@"onObjectChange"
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
                        }

                        cachedFetchResult.fetchResult = [changeDetails fetchResultAfterChanges];
                    }
                }

            }
        }];
        
        [self.eventEmitter sendEventWithName:@"onLibraryChange"
                                                body:@{}];
    }

}

-(NSArray *)indexSetToReturnableArray:(NSIndexSet *)inputIndexSet {
    NSMutableArray *indexArray = (NSMutableArray *)[NSNull null];
    if(inputIndexSet) {
        indexArray = [NSMutableArray arrayWithCapacity:inputIndexSet.count];
        [inputIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [indexArray addObject:@(idx)];
        }];
    }
    return indexArray;
}



@end
