#include "RCTImageResizer.h"
#include "ImageHelpers.h"
#import <React/RCTImageLoader.h>

@implementation RNPFImageResizer


bool RNPFsaveImage(NSString * fullPath, UIImage * image, NSString * format, float quality, NSError ** errorPtr)
{
    NSData* data = nil;
    if ([format isEqualToString:@"JPEG"]) {
        data = UIImageJPEGRepresentation(image, quality / 100.0);
    } else if ([format isEqualToString:@"PNG"]) {
        data = UIImagePNGRepresentation(image);
    }
    
    if (data == nil) {
        return NO; // TODO set &errorPtr
    }
    
    return [data writeToFile:fullPath options:NSDataWritingAtomic error:errorPtr];
}

NSString * RNPFgenerateFilePath(NSString * ext, NSString *name, NSString * outputPath)
{
    NSString* directory;

    if ([outputPath length] == 0) {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        directory = [paths firstObject];
    } else {
        directory = outputPath;
    }
    if(name == nil) {
        name = [[NSUUID UUID] UUIDString];
    }
    name = [[name lastPathComponent] stringByDeletingPathExtension];
    NSString* fullName = [NSString stringWithFormat:@"%@.%@", name, ext];
    NSString* fullPath = [directory stringByAppendingPathComponent:fullName];

    return fullPath;
}

UIImage * RNPFrotateImage(UIImage *inputImage, float rotationDegrees)
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
                  fileName:(NSString *)fileName
                  andCompleteBLock:(void(^)(NSString *path, NSError *error))completeBlock

{
    CGSize newSize = CGSizeMake(width, height);
    NSString* fullPath = RNPFgenerateFilePath(@"jpg", fileName, outputPath);

        // Rotate image if rotation is specified.
        if (0 != (int)rotation) {
            image = RNPFrotateImage(image, rotation);
            if (image == nil) {
                completeBlock(nil, nil); // TODO "Can't rotate the image."
                return;
            }
        }

        // Do the resizing
        UIImage * scaledImage = [image scaleToSize:newSize];
        if (scaledImage == nil) {
            completeBlock(nil, nil); // TODO "Can't resize the image."
            return;
        }

        // Compress and save the image
        NSError * error;
        if (!RNPFsaveImage(fullPath, scaledImage, format, quality, &error)) {
            completeBlock(nil, error);
            return;
        }
        
        completeBlock(fullPath, nil);
}

@end
