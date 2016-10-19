//
//  PHCachingImageManagerInstance.h
//  Gotlandskartan
//
//  Created by Olof Dahlbom on 2016-10-18.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Photos;

@interface PHCachingImageManagerInstance : NSObject {
}

+ (PHCachingImageManager *)sharedCachingManager;

@end


