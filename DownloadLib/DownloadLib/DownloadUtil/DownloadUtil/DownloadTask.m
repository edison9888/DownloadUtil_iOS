//
//  downloadTask.m
//  DownloadUtil
//
//  Created by DLL on 14-4-22.
//  Copyright (c) 2014年 DLL. All rights reserved.
//

#import "DownloadTask.h"
#import "DownloadManager.h"

#define DEFAULT_TIMEOUT_INTERVAL 20

NSString* DataPath(NSString* name, NSString* folder)
{
	NSArray	*documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *doc = [documentPaths objectAtIndex:0];
	NSString *folderPath = [doc stringByAppendingPathComponent:folder];
	return [folderPath stringByAppendingPathComponent:name];
}

BOOL IsFileExistAt(NSString *filepath)
{
	if(filepath == nil)
        return NO;
	return [[NSFileManager defaultManager] fileExistsAtPath:filepath];
}

@interface DownloadTask()
@end


@implementation DownloadTask


@synthesize downloadManager = _downloadManager;
@synthesize fileName = _fileName;
@synthesize uuid = _uuid;
@synthesize targetURL = _targetURL;
@synthesize totalByteLength = _totalByteLength;
@synthesize loadedByteLength = _loadedByteLength;
@synthesize isDownloading = _isDownloading;
@synthesize progress = _progress;
@synthesize downloadRateLimit = _downloadRateLimit;
@synthesize filePath = _filePath;
@synthesize memoryCacheSize = _memoryCacheSize;
@synthesize tag = _tag;
@synthesize tempFilePath = _tempFilePath;
@synthesize timeoutInterval = _timeoutInterval;

#pragma mark - life cycle
- (id)init
{
    self = [super init];
    if (self) {
        self.loadedByteLength = 0;
        self.totalByteLength = 0;
        self.filePath = nil;
        self.memoryCacheSize = 100;
        _isDownloading = NO;
    }
    return self;
}

- (id)initWithTargetURL:(NSString *)targetURL
{
    self = [self init];
    if (self) {
        self.targetURL = targetURL;
    }
    return self;
}

- (id)initWithDictInfo:(NSDictionary *)dictInfo
{
    self = [self init];
    if (self) {
        self.loadedByteLength = [[dictInfo objectForKey:@"loadedBytes"] longValue];
		self.totalByteLength = [[dictInfo objectForKey:@"totalBytes"] longValue];
		self.uuid = [dictInfo objectForKey:@"uuid"];
		self.targetURL = [dictInfo objectForKey:@"targetURL"];
		self.fileName = [dictInfo objectForKey:@"name"];
		self.filePath = [dictInfo objectForKey:@"path"];
        self.downloadRateLimit = [[dictInfo objectForKey:@"downloadRateLimit"] unsignedIntegerValue];
        self.memoryCacheSize = [[dictInfo objectForKey:@"memoryCacheSize"] unsignedIntegerValue];
        self.tag = [[dictInfo objectForKey:@"tag"] integerValue];
    }
    return self;
}

- (void)dealloc
{
    self.filePath = nil;
    self.fileName = nil;
    self.uuid = nil;
    self.targetURL = nil;
    
    [_downloadThread cancel], [_downloadThread release], _downloadThread = nil;
    [_request clearDelegatesAndCancel], [_request release], _request = nil;
    [_data release], _data = nil;
    [_tempFilePath release], _tempFilePath = nil;
    
    _isDownloading = NO;
    
    _downloadManager = nil;
    
    [super dealloc];
}


#pragma mark - downloadTask method

- (NSDictionary *)dictInfo
{
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: self.uuid,@"uuid", self.targetURL,@"targetURL", [NSNumber numberWithLong:self.loadedByteLength], @"loadedBytes", [NSNumber numberWithLong:self.totalByteLength], @"totalBytes", [NSNumber numberWithUnsignedInteger:self.downloadRateLimit], @"downloadRateLimit", [NSNumber numberWithUnsignedInteger:self.memoryCacheSize], @"memoryCacheSize", [NSNumber numberWithInteger:self.tag], @"tag", self.filePath, @"path", self.fileName, @"name", nil];
	return info;
}

- (void)startDownload
{
    if (_isDownloading || !self.targetURL || (self.loadedByteLength == self.totalByteLength && self.totalByteLength > 0)) {
        return;
    }
    _isDownloading = YES;
    
    [_downloadThread cancel];
    [_downloadThread release];
    _downloadThread = [[NSThread alloc] initWithTarget:self selector:@selector(startRequestInBackGround:) object:_request];
    [_downloadThread start];
    
}

- (void)startRequestInBackGround:(NSURL *)URL
{
    @autoreleasepool {
        if (_request) {
            [_request clearDelegatesAndCancel];
            [_request release];
        }
        
        [_data release];
        _data = [[NSMutableData alloc] init];
        _request = [[ByteRateLimitHTTPRequest alloc] initWithURL:[NSURL URLWithString:self.targetURL]];
        _request.cachePolicy = ASIDoNotReadFromCacheCachePolicy | ASIDoNotWriteToCacheCachePolicy;
        _request.delegate = self;
        _request.timeOutSeconds = _timeoutInterval ? _timeoutInterval : DEFAULT_TIMEOUT_INTERVAL;
        _request.byteRateLimit = self.downloadRateLimit << 10;
        if (_loadedByteLength > 0) {
            [_request addRequestHeader:@"Range" value:[NSString stringWithFormat:@"bytes=%lu-", (unsigned long)self.loadedByteLength]];
        } else {
            [self guessFileName];
            NSString *parentFolder = [self.filePath stringByDeletingLastPathComponent];
            if (!IsFileExistAt(parentFolder)) {
                [[NSFileManager defaultManager] createDirectoryAtPath:parentFolder withIntermediateDirectories:YES attributes:nil error:NULL];
            } else {
                [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:NULL];
                [[NSFileManager defaultManager] removeItemAtPath:self.tempFilePath error:NULL];
            }
        }
        _timeStart = [[NSDate date] timeIntervalSince1970];
        _deltaByteLength = 0;
        _sleepTime = 0;
        [_downloadManager onDownloaderStart:self];
        [_request startSynchronous];
    }
}

- (void)pause
{
    if (_isDownloading) {
        _isDownloading = NO;
    }
}


- (void)writeCache{
    @synchronized (self) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        if ([_data length] > 0) {
            NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:self.tempFilePath];
            if (file) {
                [file seekToEndOfFile];
                [file writeData:_data];
                [file closeFile];
            }else {
                [_data writeToFile:self.tempFilePath atomically:YES];
            }
            self.loadedByteLength += [_data length];
            [_data setLength:0];
            if (_downloadManager) {
                [_downloadManager onDownloaderReceivedData:self];
            }
        }
        NSLog(@"%ld write cache to file", (long)self.tag);
        [pool drain];
    }
}

- (CGFloat)progress{
	if (self.totalByteLength > 0) {
		return self.loadedByteLength * 1.0f / self.totalByteLength;
	}
	return 0;
}


#define SLEEP_TIME_DELTA 0.2
- (void)limitRate:(NSUInteger)byteLength
{
    if (!_downloadRateLimit) {
        return;
    }
    NSLog(@"%ld receive: %lu", (long)self.tag, (unsigned long)byteLength);
    _deltaByteLength += byteLength;
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval passedTime = currentTime - _timeStart;
    if (passedTime > 0) {
        NSUInteger currentRate = _deltaByteLength / passedTime;
        if (passedTime >= 5) {
            _timeStart = currentTime;
            _deltaByteLength = 0;
        }
        if (currentRate > (_downloadRateLimit << 10)) {
            _sleepTime += SLEEP_TIME_DELTA;
        } else {
            if (_sleepTime >= SLEEP_TIME_DELTA) {
                _sleepTime -= SLEEP_TIME_DELTA;
            }
        }
        [_request unscheduleReadStream];
        [NSThread sleepForTimeInterval:_sleepTime];
        [_request scheduleReadStream];
    }
}


#pragma mark - property method
- (void)guessFileName
{
    if (_fileName) {
		return;
	}
	NSString *last = [self.targetURL lastPathComponent];
	NSInteger loc = [last rangeOfString:@"?"].location;
	if (loc != NSNotFound) {
		last = [last substringToIndex:loc];
	}
	if ([last length] > 4) {
		self.fileName = last;
	} else {
		self.fileName = [self.uuid stringByAppendingString:last];
	}
}

- (NSString *)tempFilePath
{
    if (!_tempFilePath) {
        _tempFilePath = [[NSString stringWithFormat:@"%@.dl", self.filePath] retain];
    }
    return _tempFilePath;
}

- (NSString *)uuid
{
    if (!_uuid) {
        CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
        NSString *uuidStr = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject) autorelease];
        CFRelease(uuidObject);
        self.uuid = uuidStr;
    }
    return _uuid;
}

- (NSString *)fileName
{
    if (!_fileName) {
        [self guessFileName];
    }
    return _fileName;
}

- (NSString *)filePath
{
    if (!_filePath) {
        self.filePath = DataPath(self.fileName, @"Cache");
    }
    return _filePath;
}

#pragma mark - asi http delegate
- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders
{
    if (self.totalByteLength == 0) {
        self.totalByteLength= (NSUInteger)[[responseHeaders objectForKey:@"Content-Length"] longLongValue];
    }
}


- (void)request:(ASIHTTPRequest *)request didReceiveData:(NSData *)data
{
    @autoreleasepool {
        
        
        if (!_isDownloading) {
            [_request clearDelegatesAndCancel];
            [_request release];
            _request = nil;
            [self writeCache];
            return;
        }
        
        [_data appendData:data];
        if ([_data length] >= (self.memoryCacheSize << 10)) {
            [self writeCache];
        }
        [self limitRate:data.length];
    }
}


- (void)requestFailed:(ASIHTTPRequest *)request
{
    _isDownloading = NO;
    [self writeCache];
    if (_downloadManager) {
        [_downloadManager onDownloader:self stopedWithError:request.error];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    [self writeCache];
    [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:NULL];
    [[NSFileManager defaultManager] moveItemAtPath:self.tempFilePath toPath:self.filePath error:NULL];
	_isDownloading = NO;
	if (_downloadManager) {
		[_downloadManager onDownloaderFinished:self];
	}
}

@end
