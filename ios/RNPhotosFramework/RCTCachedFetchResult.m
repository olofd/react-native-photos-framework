//
//  RCTCachedFetchResult.m
//  RNPhotosFramework
//
//  Created by Olof Dahlbom on 2016-10-24.
//  Copyright © 2016 Olof Dahlbom. All rights reserved.
//

#import "RCTCachedFetchResult.h"

@implementation RCTCachedFetchResult
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
