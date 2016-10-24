#import "PHFetchOptionsService.h"
#import "RCTConvert.h"
#import "RCTConvert+RNPhotosFramework.h"
@import Photos;
@implementation PHFetchOptionsService

+(PHFetchOptions *)getFetchOptionsFromParams:(NSDictionary *)params {
    if(params == nil) {
        return nil;
    }
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.includeAssetSourceTypes = [RCTConvert PHAssetSourceTypes:params[@"sourceTypes"]];
    options.includeHiddenAssets = [RCTConvert BOOL:params[@"includeHiddenAssets"]];
    options.includeAllBurstAssets = [RCTConvert BOOL:params[@"includeAllBurstAssets"]];
    options.fetchLimit = [RCTConvert int:params[@"fetchLimit"]];
    options.wantsIncrementalChangeDetails = [RCTConvert BOOL:params[@"wantsIncrementalChangeDetails"]];
    options.predicate = [PHFetchOptionsService getPredicate:params];
    
    BOOL sortAscending = [RCTConvert BOOL:params[@"sortAscending"]];
    NSString *sortDescriptorKey = [RCTConvert NSString:params[@"sortDescriptorKey"]];
    if(sortDescriptorKey != nil) {
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:sortDescriptorKey ascending:sortAscending]];
    }
    return options;
}

+(NSPredicate *) getPredicate:(NSDictionary *)params  {
    NSPredicate *mediaTypePredicate = [PHFetchOptionsService getMediaTypePredicate:params];
    
    NSPredicate *subTypePredicate = [PHFetchOptionsService getMediaSubTypePredicate:params];
    if(mediaTypePredicate && subTypePredicate) {
        return [NSCompoundPredicate andPredicateWithSubpredicates:@[mediaTypePredicate, subTypePredicate]];
    }
    return mediaTypePredicate != nil ? mediaTypePredicate : subTypePredicate;
}

+(NSPredicate *) getMediaTypePredicate:(NSDictionary *)params {
    NSMutableArray * mediaTypes = [RCTConvert PHAssetMediaTypes:params[@"mediaTypes"]];
    if(mediaTypes == nil) {
        return nil;
    }
    return [NSPredicate predicateWithFormat:@"mediaType in %@", mediaTypes];
}

+(NSPredicate *) getMediaSubTypePredicate:(NSDictionary *)params {
    NSMutableArray * mediaSubTypes = [RCTConvert PHAssetMediaSubtypes:params[@"mediaSubTypes"]];
    if(mediaSubTypes == nil) {
        return nil;
    }
    NSMutableArray *arrayWithPredicates = [NSMutableArray arrayWithCapacity:mediaSubTypes.count];
    
    for(int i = 0; i < mediaSubTypes.count;i++) {
        PHAssetMediaSubtype mediaSubType = [[mediaSubTypes objectAtIndex:i] intValue];
        [arrayWithPredicates addObject:[NSPredicate predicateWithFormat:@"((mediaSubtype & %d) == %d)", mediaSubType, mediaSubType]];
    }
    
    return [NSCompoundPredicate orPredicateWithSubpredicates:arrayWithPredicates];
}


@end
