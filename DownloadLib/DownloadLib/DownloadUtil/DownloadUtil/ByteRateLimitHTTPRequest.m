//
//  ByteRateLimitHTTPRequest.m
//  DownloadUtil
//
//  Created by DLL on 14-4-23.
//  Copyright (c) 2014年 DLL. All rights reserved.
//

#import "ByteRateLimitHTTPRequest.h"


@implementation ByteRateLimitHTTPRequest

@synthesize byteRateLimit = _byteRateLimit;


- (void)handleBytesAvailable
{
	if (![self responseHeaders]) {
		[self readResponseHeaders];
	}
	
	// If we've cancelled the load part way through (for example, after deciding to use a cached version)
	if ([self complete]) {
		return;
	}
	
	// In certain (presumably very rare) circumstances, handleBytesAvailable seems to be called when there isn't actually any data available
	// We'll check that there is actually data available to prevent blocking on CFReadStreamRead()
	// So far, I've only seen this in the stress tests, so it might never happen in real-world situations.
	if (!CFReadStreamHasBytesAvailable((CFReadStreamRef)[self readStream])) {
		return;
	}
    
	long long bufferSize = 16384;
	if (contentLength > 262144) {
		bufferSize = 262144;
	} else if (contentLength > 65536) {
		bufferSize = 65536;
	}
	
	// Reduce the buffer size if we're receiving data too quickly when bandwidth throttling is active
	// This just augments the throttling done in measureBandwidthUsage to reduce the amount we go over the limit
	
    if (_byteRateLimit && bufferSize > _byteRateLimit) {
        bufferSize = _byteRateLimit;
    }
	
	
    UInt8 buffer[bufferSize];
    NSInteger bytesRead = [[self readStream] read:buffer maxLength:sizeof(buffer)];
    
    // Less than zero is an error
    if (bytesRead < 0) {
        [self handleStreamError];
		
        // If zero bytes were read, wait for the EOF to come.
    } else if (bytesRead) {
        
		// If we are inflating the response on the fly
		NSData *inflatedData = nil;
		if ([self isResponseCompressed] && ![self shouldWaitToInflateCompressedResponses]) {
			if (![self dataDecompressor]) {
				[self setDataDecompressor:[ASIDataDecompressor decompressor]];
			}
			NSError *err = nil;
			inflatedData = [[self dataDecompressor] uncompressBytes:buffer length:bytesRead error:&err];
			if (err) {
				[self failWithError:err];
				return;
			}
		}
		
		[self setTotalBytesRead:[self totalBytesRead]+bytesRead];
		[self setLastActivityTime:[NSDate date]];
        
		// For bandwidth measurement / throttling
		[ASIHTTPRequest incrementBandwidthUsedInLastSecond:bytesRead];
		
		// If we need to redirect, and have automatic redirect on, and might be resuming a download, let's do nothing with the content
		if ([self needsRedirect] && [self shouldRedirect] && [self allowResumeForFileDownloads]) {
			return;
		}
		
		BOOL dataWillBeHandledExternally = NO;
		if ([[self delegate] respondsToSelector:[self didReceiveDataSelector]]) {
			dataWillBeHandledExternally = YES;
		}
#if NS_BLOCKS_AVAILABLE
		if (dataReceivedBlock) {
			dataWillBeHandledExternally = YES;
		}
#endif
		// Does the delegate want to handle the data manually?
		if (dataWillBeHandledExternally) {
            
			NSData *data = nil;
			if ([self isResponseCompressed] && ![self shouldWaitToInflateCompressedResponses]) {
				data = inflatedData;
			} else {
				data = [NSData dataWithBytes:buffer length:bytesRead];
			}
			[self performSelector:@selector(passOnReceivedData:) withObject:data];
			
            // Are we downloading to a file?
		} else if ([self downloadDestinationPath]) {
			BOOL append = NO;
			if (![self fileDownloadOutputStream]) {
				if (![self temporaryFileDownloadPath]) {
					[self setTemporaryFileDownloadPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]]];
				} else if ([self allowResumeForFileDownloads] && [[self requestHeaders] objectForKey:@"Range"]) {
					if ([[self responseHeaders] objectForKey:@"Content-Range"]) {
						append = YES;
					} else {
						[self incrementDownloadSizeBy:-[self partialDownloadSize]];
						[self setPartialDownloadSize:0];
					}
				}
                
				[self setFileDownloadOutputStream:[[[NSOutputStream alloc] initToFileAtPath:[self temporaryFileDownloadPath] append:append] autorelease]];
				[[self fileDownloadOutputStream] open];
                
			}
			[[self fileDownloadOutputStream] write:buffer maxLength:bytesRead];
            
			if ([self isResponseCompressed] && ![self shouldWaitToInflateCompressedResponses]) {
				
				if (![self inflatedFileDownloadOutputStream]) {
					if (![self temporaryUncompressedDataDownloadPath]) {
						[self setTemporaryUncompressedDataDownloadPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]]];
					}
					
					[self setInflatedFileDownloadOutputStream:[[[NSOutputStream alloc] initToFileAtPath:[self temporaryUncompressedDataDownloadPath] append:append] autorelease]];
					[[self inflatedFileDownloadOutputStream] open];
				}
                
				[[self inflatedFileDownloadOutputStream] write:[inflatedData bytes] maxLength:[inflatedData length]];
			}
            
			
            //Otherwise, let's add the data to our in-memory store
		} else {
			if ([self isResponseCompressed] && ![self shouldWaitToInflateCompressedResponses]) {
				[rawResponseData appendData:inflatedData];
			} else {
				[rawResponseData appendBytes:buffer length:bytesRead];
			}
		}
    }
}

- (void)startSynchronous
{
    [self retain];
    [super startSynchronous];
    [self retain];
}

- (void)performThrottling
{

}

- (void)requestFinished
{
#if DEBUG_REQUEST_STATUS || DEBUG_THROTTLING
	NSLog(@"Request finished: %@",self);
#endif
	if ([self error] || [self mainRequest]) {
		return;
	}
	[self performSelector:@selector(reportFinished) withObject:nil];
}

@end
