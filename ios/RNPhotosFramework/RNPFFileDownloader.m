#import "RNPFFileDownloader.h"

@implementation RNPFFileDownloader

- (void)startDownload:(NSURL *)url andSaveWithExtension:(NSString *)extension andProgressBlock:(fileDownloadProgressBlock)progressBlock andCompletionBlock:(fileDownloadCompleteBlock)completeBlock andErrorBlock:(fileDownloadErrorBlock)errorBlock
{
    self.extension = extension;
    self.progressBlock = progressBlock;
    self.completeBlock = completeBlock;
    self.errorBlock = errorBlock;
    NSURLSession *session = [self configureSession];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
    [task resume];
}

- (NSURLSession *) configureSession {
    NSURLSessionConfiguration *config =
    [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[@"react-native-photos-framework-" stringByAppendingString:[[NSUUID UUID] UUIDString]]];
    config.allowsCellularAccess = YES;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    return session;
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if(self.progressBlock) {
        self.progressBlock(totalBytesWritten, totalBytesExpectedToWrite);
    }
    
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    if(self.completeBlock) {
        if(self.extension) {
            NSFileManager *fileMan = [NSFileManager defaultManager];
            NSError *errorMov = nil;
            NSString *documentDir = NSTemporaryDirectory();
            NSString *newFilePath = [documentDir stringByAppendingPathComponent:[[[NSUUID UUID] UUIDString] stringByAppendingString:self.extension]];
            if (![fileMan moveItemAtPath:location.path toPath:newFilePath error:&errorMov])
            {
                if(self.errorBlock) {
                    return self.errorBlock(errorMov);
                }
            }
            return self.completeBlock([NSURL URLWithString:newFilePath]);
        }else {
            self.completeBlock(location);
        }
    }
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error != nil && self.errorBlock) {
        self.errorBlock(error);
    }
}

@end
