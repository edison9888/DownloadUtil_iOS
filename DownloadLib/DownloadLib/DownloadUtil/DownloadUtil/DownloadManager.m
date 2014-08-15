//
//  DownloadUtil.m
//  DownloadUtil
//
//  Created by DLL on 14-4-22.
//  Copyright (c) 2014年 DLL. All rights reserved.
//

#import "DownloadManager.h"
#import "DownloadQueueManager.h"


@implementation DownloadManager {
    
}

@synthesize downloaders = _downloaders;

static DownloadManager *sharedDownloadManager = nil;

#pragma mark - single instance & life cycle
+ (DownloadManager *)sharedQueueManager
{
	if (sharedDownloadManager == nil) {
		sharedDownloadManager = [DownloadQueueManager new];
	}
	return sharedDownloadManager;
}

- (void)dealloc
{
    [_downloaders release], _downloaders = nil;
    [super dealloc];
}

#pragma mark - call back
- (void)onDownloaderReceivedData:(DownloadTask *)downloadTask
{
    [self writeDownloadersToFile];
	if ([_delegate respondsToSelector:@selector(downloaderDidReceiveData:)]) {
        [(NSObject *)_delegate performSelectorOnMainThread:@selector(downloaderDidReceiveData:) withObject:downloadTask waitUntilDone:YES];
	}
}

- (void)onDownloaderFinished:(DownloadTask *)downloadTask
{
    NSLog(@"tag %ld download finish", (long)downloadTask.tag);
    [self stopDownloader:downloadTask];
    [self writeDownloadersToFile];
    [self performSelectorOnMainThread:@selector(startNextDownload) withObject:nil waitUntilDone:YES];
    if ([_delegate respondsToSelector:@selector(downloaderDidFinishDownload:)]) {
        [(NSObject *)_delegate performSelectorOnMainThread:@selector(downloaderDidFinishDownload:) withObject:downloadTask waitUntilDone:YES];
    }
}

- (void)onDownloaderStart:(DownloadTask *)downloadTask
{
    NSLog(@"tag %ld download start", (long)downloadTask.tag);
    if ([_delegate respondsToSelector:@selector(downloaderDidStart:)]) {
        [(NSObject *)_delegate performSelectorOnMainThread:@selector(downloaderDidStart:) withObject:downloadTask waitUntilDone:YES];
    }
}

- (void)onDownloader:(DownloadTask *)downloadTask stopedWithError:(NSError *)error
{
    NSLog(@"tag %ld download stop with error: %@", (long)downloadTask.tag, error.description);
    [self writeDownloadersToFile];
    if ([_delegate respondsToSelector:@selector(downloadTask:didFailedWithError:)] && error && downloadTask) {
        [self performSelectorOnMainThread:@selector(downloaderDidFailedWithDate:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:downloadTask, @"downloadTask", error, @"error", nil] waitUntilDone:YES];
    }
}

- (void)downloaderDidFailedWithDate:(NSDictionary *)dictData
{
    [_delegate downloadTask:[dictData objectForKey:@"downloadTask"] didFailedWithError:[dictData objectForKey:@"error"]];
}


#pragma mark - download manager
- (void)addDownloader:(DownloadTask *)downloadTask
{
    // implement this method in subclass
}

- (BOOL)startNextDownload
{
    // implement this method in subclass
    return NO;
}

- (void)stopDownloader:(DownloadTask *)downloadTask
{
    // implement this method in subclass
}

- (void)writeDownloadersToFile
{
    // implement this method in subclass
}

- (BOOL)resume
{
    // implement this method in subclass
    return NO;
}

- (void)stop
{
    // implement this method in subclass
}

@end
