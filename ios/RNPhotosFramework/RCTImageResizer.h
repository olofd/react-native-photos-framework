#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageResizer : NSObject
+(void) createResizedImage:(UIImage *)image
                     width:(float)width
                    height:(float)height
                    format:(NSString *)format
                   quality:(float)quality
                  rotation:(float)rotation
                outputPath:(NSString *)outputPath
                  fileName:(NSString *)fileName
          andCompleteBLock:(void(^)(NSString *error, NSString *path))completeBlock;
@end
