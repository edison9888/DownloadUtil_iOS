//
//  DownloadQueueManager.m
//  DownloadUtil
//
//  Created by DLL on 14-4-28.
//  Copyright (c) 2014年 DLL. All rights reserved.
//

#import "DownloadQueueManager.h"


#define DOWNLOAD_QUEUE_FILE_NAME @"DownloadQueueManager.plist"


@implementation DownloadQueueManager

- (BOOL)resume
{
    @synchronized (self) {
        if (self.downloaders != nil && _downloaders.count) {
            [self startNextDownload];
            return YES;
        } else if (IsFileExistAt(DataPath(DOWNLOAD_QUEUE_FILE_NAME, @""))) {
            NSArray *infos = [NSArray arrayWithContentsOfFile:DataPath(DOWNLOAD_QUEUE_FILE_NAME, @"")];
            for (NSDictionary *info in infos) {
                DownloadTask *downloadTask = [[DownloadTask alloc] initWithDictInfo:info];
                [self addDownloader:downloadTask];
                [downloadTask release];
            }
            if ([infos count] > 0) {
                return YES;
            }
        }
        return NO;
    }
}

- (void)writeDownloadersToFile
{
    @synchronized (self) {
        NSMutableArray *info = [NSMutableArray arrayWithCapacity:_downloaders.count];
        for (DownloadTask *downloadTask in _downloaders) {
            [info addObject:[downloadTask dictInfo]];
        }
        [info writeToFile:DataPath(DOWNLOAD_QUEUE_FILE_NAME, @"") atomically:YES];
    }
}


- (BOOL)startNextDownload
{
    @synchronized (self) {
        if (_downloaders.count && ![[_downloaders firstObject] isDownloading]) {
            [[_downloaders firstObject] startDownload];
            return YES;
        }
        return NO;
    }
}

- (void)stop
{
    @synchronized(self) {
        if (self.downloaders == nil) {
            return;
        }
        [[_downloaders firstObject] pause];
    }
}

- (void)stopDownloader:(DownloadTask *)downloadTask
{
    @synchronized (self) {
        [downloadTask performSelector:@selector(pause)];
        [_downloaders removeObject:downloadTask];
    }
}

- (void)addDownloader:(DownloadTask *)downloadTask{
    @synchronized (self) {
        if (self.downloaders == nil) {
            _downloaders = [NSMutableArray new];
        }
        [_downloaders addObject:downloadTask];
        downloadTask.downloadManager = self;
        [self startNextDownload];
    }
}
@end
