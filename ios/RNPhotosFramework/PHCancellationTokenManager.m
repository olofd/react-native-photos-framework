//
//  PHCancellationTokenManager.m
//  RNPhotosFramework
//
//  Created by Olof Dahlbom on 2017-09-03.
//  Copyright © 2017 Olof Dahlbom. All rights reserved.
//

#import "PHCancellationTokenManager.h"

@implementation PHCancellationTokenManager


+(instancetype)sharedInstance {
    
    static PHCancellationTokenManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once( &onceToken, ^{
        _sharedInstance = [PHCancellationTokenManager new];
    });
    
    return _sharedInstance;
}

-(void) createToken {
    
}

@end
