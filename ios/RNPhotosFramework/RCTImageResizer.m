#include "RCTImageResizer.h"
#include "ImageHelpers.h"
#import <React/RCTImageLoader.h>

@implementation ImageResizer


bool saveImage(NSString * fullPath, UIImage * image, NSString * format, float quality)
{
    NSData* data = nil;
    if ([format isEqualToString:@"JPEG"]) {
        data = UIImageJPEGRepresentation(image, quality / 100.0);
    } else if ([format isEqualToString:@"PNG"]) {
        data = UIImagePNGRepresentation(image);
    }
    
    if (data == nil) {
        return NO;
    }
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    [fileManager createFileAtPath:fullPath contents:data attributes:nil];
    return YES;
}

NSString * generateFilePath(NSString * ext, NSString * outputPath)
{
    NSString* directory;

    if ([outputPath length] == 0) {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        directory = [paths firstObject];
    } else {
        directory = outputPath;
    }

    NSString* name = [[NSUUID UUID] UUIDString];
    NSString* fullName = [NSString stringWithFormat:@"%@.%@", name, ext];
    NSString* fullPath = [directory stringByAppendingPathComponent:fullName];

    return fullPath;
}

UIImage * rotateImage(UIImage *inputImage, float rotationDegrees)
{

    // We want only fixed 0, 90, 180, 270 degree rotations.
    const int rotDiv90 = (int)round(rotationDegrees / 90);
    const int rotQuadrant = rotDiv90 % 4;
    const int rotQuadrantAbs = (rotQuadrant < 0) ? rotQuadrant + 4 : rotQuadrant;
    
    // Return the input image if no rotation specified.
    if (0 == rotQuadrantAbs) {
        return inputImage;
    } else {
        // Rotate the image by 80, 180, 270.
        UIImageOrientation orientation = UIImageOrientationUp;
        
        switch(rotQuadrantAbs) {
            case 1:
                orientation = UIImageOrientationRight; // 90 deg CW
                break;
            case 2:
                orientation = UIImageOrientationDown; // 180 deg rotation
                break;
            default:
                orientation = UIImageOrientationLeft; // 90 deg CCW
                break;
        }
        
        return [[UIImage alloc] initWithCGImage: inputImage.CGImage
                                                  scale: 1.0
                                                  orientation: orientation];
    }
}

+(void) createResizedImage:(UIImage *)image
                  width:(float)width
                  height:(float)height
                  format:(NSString *)format
                  quality:(float)quality
                  rotation:(float)rotation
                  outputPath:(NSString *)outputPath
                  andCompleteBLock:(void(^)(NSString *error, NSString *path))completeBlock

{
    CGSize newSize = CGSizeMake(width, height);
    NSString* fullPath = generateFilePath(@"jpg", outputPath);

        // Rotate image if rotation is specified.
        if (0 != (int)rotation) {
            image = rotateImage(image, rotation);
            if (image == nil) {
                completeBlock(@"Can't rotate the image.", @"");
                return;
            }
        }

        // Do the resizing
        UIImage * scaledImage = [image scaleToSize:newSize];
        if (scaledImage == nil) {
            completeBlock(@"Can't resize the image.", @"");
            return;
        }

        // Compress and save the image
        if (!saveImage(fullPath, scaledImage, format, quality)) {
            completeBlock(@"Can't save the image. Check your compression format.", @"");
            return;
        }
        
        completeBlock(nil, fullPath);
}

@end
