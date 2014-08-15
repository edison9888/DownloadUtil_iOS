//
//  DownloadUtil.h
//  DownloadUtil
//
//  Created by DLL on 14-4-22.
//  Copyright (c) 2014年 DLL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadTask.h"



@interface DownloadManager : NSObject {
    @protected NSMutableArray *_downloaders;
}

@property (nonatomic, readonly) NSMutableArray *downloaders;
@property (nonatomic, assign) id<DownloadManagerDelegate> delegate;

+ (DownloadManager *)sharedQueueManager;

- (void)onDownloaderReceivedData:(DownloadTask *)downloadTask;
- (void)onDownloaderFinished:(DownloadTask *)downloadTask;
- (void)onDownloader:(DownloadTask *)downloadTask stopedWithError:(NSError *)error;
- (void)onDownloaderStart:(DownloadTask *)downloadTask;

- (void)addDownloader:(DownloadTask *)downloadTask;
- (void)stopDownloader:(DownloadTask *)downloadTask;

- (BOOL)resume; // 继续之前未完成的任务
- (void)stop;   // 终止当前任务
@end
