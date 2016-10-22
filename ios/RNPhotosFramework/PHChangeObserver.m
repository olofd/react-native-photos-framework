//
//  PHChangeObserver.m
//  RNPhotosFramework
//
//  Created by Olof Dahlbom on 2016-10-22.
//  Copyright © 2016 Olof Dahlbom. All rights reserved.
//

#import "PHChangeObserver.h"

@implementation PHChangeObserver

-(void)registerChangeObserevr {
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}


- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    NSLog(@"Hello");
}

@end
