#import <Foundation/Foundation.h>

@interface RNPFFileDownloader : NSObject<NSURLSessionDownloadDelegate>

typedef void (^fileDownloadCompleteBlock)(NSURL *downloadUrl);
typedef void (^fileDownloadProgressBlock)(int64_t progress, int64_t total);
typedef void (^fileDownloadErrorBlock)(NSError *error);

- (void)startDownload:(NSURL *)url andSaveWithExtension:(NSString *)extension andProgressBlock:(fileDownloadProgressBlock)progressBlock andCompletionBlock:(fileDownloadCompleteBlock)completeBlock andErrorBlock:(fileDownloadErrorBlock)errorBlock;

@property (nonatomic, copy) fileDownloadCompleteBlock completeBlock;
@property (nonatomic, copy) fileDownloadProgressBlock progressBlock;
@property (nonatomic, copy) fileDownloadErrorBlock errorBlock;
@property (nonatomic, strong) NSString *extension;
@end
