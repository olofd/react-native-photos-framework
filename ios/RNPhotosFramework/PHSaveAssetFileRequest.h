#import <Foundation/Foundation.h>
@import Photos;

@interface PHSaveAssetFileRequest : NSObject
@property (strong, nonatomic) NSURLRequest *uri;
@property (strong, nonatomic) NSString *uriString;

@property (strong, nonatomic) NSString *localIdentifier;
@property (strong, nonatomic) NSString *mediaType;

@property (strong, nonatomic) NSString *fileName;
@property (strong, nonatomic) NSString *dir;

@property (strong, nonatomic) NSDictionary *loadOptions;
@property (strong, nonatomic) NSDictionary *postProcessOptions;



//Only used for videos:
@property (strong, nonatomic) PHVideoRequestOptions* videoRequestOptions;

@end
