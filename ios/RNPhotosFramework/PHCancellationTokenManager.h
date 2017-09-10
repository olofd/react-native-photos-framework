//
//  PHCancellationTokenManager.h
//  RNPhotosFramework
//
//  Created by Olof Dahlbom on 2017-09-03.
//  Copyright © 2017 Olof Dahlbom. All rights reserved.
//

#import "PHCancellationToken.h";
#import <Foundation/Foundation.h>

@interface PHCancellationTokenManager : NSObject

@property (strong, nonatomic) NSArray<PHCancellationToken *> * CancellationTokens;
@end
