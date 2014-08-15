//
//  ByteRateLimitHTTPRequest.h
//  DownloadUtil
//
//  Created by DLL on 14-4-23.
//  Copyright (c) 2014年 DLL. All rights reserved.
//

#import "DLLHTTPUtil.h"

@interface ByteRateLimitHTTPRequest : ASIHTTPRequest {
}

@property (nonatomic, assign) NSUInteger byteRateLimit; // unit: byte

- (void)unscheduleReadStream;
- (void)scheduleReadStream;


@end
