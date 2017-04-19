#import "PHVideoExporter.h"
#import <React/RCTConvert.h>
@implementation PHVideoExporter

-(void (^_Nonnull)()) exportVideoWithAsset:(AVAsset *_Nonnull)avasset andDir:(NSString *)dir andFileName:(NSString *_Nonnull)fileName andPostProcessParams:(NSDictionary *_Nullable)params andProgressBlock:(videoExporterProgressBlock _Nonnull )progressBlock andCompletionBlock:(videoExporterCompleteBlock _Nonnull )completeBlock {
    
    __block NSString *fullFileName = [dir stringByAppendingPathComponent:fileName];
    __block NSString *tempFileName = [dir stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    __block NSURL *tempUrl = [NSURL fileURLWithPath:tempFileName];

    if(params == nil) {
        params = [NSDictionary new];
    }
    self.progressBlock = progressBlock;
    
    NSString *outputFileType = [RCTConvert NSString:params[@"outputFileType"]];
    if(outputFileType == nil) {
        outputFileType = AVFileTypeMPEG4;
    }
    
    NSString *codecKey = [RCTConvert NSString:params[@"codecKey"]];
    if(codecKey == nil) {
        codecKey = AVVideoCodecH264;
    }
    
    NSString *profileLevelKey = [RCTConvert NSString:params[@"profileLevelKey"]];
    if(profileLevelKey == nil) {
        profileLevelKey = AVVideoProfileLevelH264HighAutoLevel;
    }
    
    
    AVAssetTrack *track = [[avasset tracksWithMediaType:AVMediaTypeVideo] firstObject];

    int width = [RCTConvert int:params[@"width"]];
    int height = [RCTConvert int:params[@"height"]];

    if(width < 0.1 || height < 0.1) {
        CGSize dimensions = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
        width = (int)dimensions.width;
        height = (int)dimensions.height;
    }
    
    
    float bitrateMultiplier = [RCTConvert float:params[@"bitrateMultiplier"]];
    float minimumBitrate = [RCTConvert float:params[@"minimumBitrate"]];

    if(bitrateMultiplier < 0.01) {
        bitrateMultiplier = 1;
    }
    float bps = track.estimatedDataRate;

    float averageBitrate = bps / bitrateMultiplier;
    if (minimumBitrate > 0.01) {
        if (averageBitrate < minimumBitrate) {
            averageBitrate = minimumBitrate;
        }
        if (bps < minimumBitrate) {
            averageBitrate = bps;
        }
    }

    self.encoder = [SDAVAssetExportSession.alloc initWithAsset:avasset];
    
    [_encoder addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    
    _encoder.outputFileType = outputFileType;
    _encoder.outputURL = tempUrl;
    _encoder.shouldOptimizeForNetworkUse = YES;

    _encoder.videoSettings = @
    {
    AVVideoCodecKey: codecKey,
    AVVideoWidthKey: @(width),
    AVVideoHeightKey: @(height),
    AVVideoCompressionPropertiesKey: @
        {
        AVVideoAverageBitRateKey: @(averageBitrate),
        AVVideoProfileLevelKey: profileLevelKey,
        },
    };
    _encoder.audioSettings = @
    {
    AVFormatIDKey: @(kAudioFormatMPEG4AAC),
    AVNumberOfChannelsKey: @2,
    AVSampleRateKey: @44100,
    AVEncoderBitRateKey: @128000,
    };
    
    @try {
        [_encoder exportAsynchronouslyWithCompletionHandler:^
         {
             if (_encoder.status == AVAssetExportSessionStatusCompleted)
             {
                 NSError *error;
                 if ([[NSFileManager defaultManager] fileExistsAtPath:fullFileName] && [[NSFileManager defaultManager] isDeletableFileAtPath:fullFileName]) {
                     BOOL success = [[NSFileManager defaultManager] removeItemAtPath:fullFileName error:&error];
                     if (!success) {
                         NSLog(@"Error removing file at path: %@", error.localizedDescription);
                     }
                 }
                 
                 [[NSFileManager defaultManager] moveItemAtPath:tempFileName toPath:fullFileName error:&error];
                 
                 if(error != nil) {
                    completeBlock(NO, error, nil);

                 }else {
                     completeBlock(YES, nil, [NSURL URLWithString:fullFileName]);
                 }
             }
             else if (_encoder.status == AVAssetExportSessionStatusCancelled)
             {
                 completeBlock(NO, nil, nil);
             }
             else
             {
                 completeBlock(NO, _encoder.error, nil);
             }
             [_encoder removeObserver:self forKeyPath:@"progress"];

    }];
    } @catch (NSException *exception) {
        completeBlock(NO, nil, nil);
        [_encoder removeObserver:self forKeyPath:@"progress"];

    }

    return ^{
        [_encoder cancelExport];
    };
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"progress"]){
        NSNumber * newValue = [change objectForKey:NSKeyValueChangeNewKey];
        if(self.progressBlock) {
            self.progressBlock(newValue.floatValue);
        }
    }
}
@end
