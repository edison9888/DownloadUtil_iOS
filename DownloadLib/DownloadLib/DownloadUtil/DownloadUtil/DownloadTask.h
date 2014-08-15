//
//  downloadTask.h
//  DownloadUtil
//
//  Created by DLL on 14-4-22.
//  Copyright (c) 2014年 DLL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ByteRateLimitHTTPRequest.h"

@class DownloadManager;
@class DownloadTask;


NSString* DataPath(NSString* name, NSString* folder);
BOOL IsFileExistAt(NSString *filepath);

#pragma mark - downloadTask delegate
@protocol DownloadManagerDelegate <NSObject>
@optional
// 下列方法全部会在主线程中调用
- (void)downloaderDidReceiveData:(DownloadTask *)downloadTask;
- (void)downloaderDidFinishDownload:(DownloadTask *)downloadTask;
- (void)downloadTask:(DownloadTask *)downloadTask didFailedWithError:(NSError *)error;
- (void)downloaderDidStart:(DownloadTask *)downloadTask;
@end


#pragma mark - downloadTask
@interface DownloadTask : NSObject  <ASIHTTPRequestDelegate> {
    ByteRateLimitHTTPRequest* _request;
    NSMutableData* _data;
    NSThread* _downloadThread;
    NSTimeInterval _timeStart;
    NSUInteger _deltaByteLength;
    NSTimeInterval _sleepTime;
}

@property (nonatomic, assign) DownloadManager* downloadManager;
@property (nonatomic, copy) NSString* fileName; // only file name, no path
@property (nonatomic, copy) NSString* filePath; // abslute file path, default value is file name in document/Cache folder
@property (nonatomic, copy) NSString* uuid; // default value is same as target url
@property (nonatomic, copy) NSString* targetURL;
@property (nonatomic, readonly) NSString* tempFilePath;
@property (nonatomic, assign) NSUInteger totalByteLength;   // unit: byte
@property (nonatomic, assign) NSUInteger loadedByteLength;  // unit: byte
@property (nonatomic, readonly) BOOL isDownloading;
@property (nonatomic, readonly) CGFloat progress;
@property (nonatomic, assign) NSUInteger downloadRateLimit;    // unit: kps
@property (nonatomic, assign) NSUInteger memoryCacheSize;   // unit: kb, default value is 100
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;



- (id)initWithDictInfo:(NSDictionary *)dictInfo;
- (NSDictionary *)dictInfo;
- (void)startDownload;
- (id)initWithTargetURL:(NSString *)targetURL;

@end
