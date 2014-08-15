//
//  TestAppDelegate.m
//  Test
//
//  Created by DLL on 14-4-30.
//  Copyright (c) 2014年 DLL. All rights reserved.
//

#import "TestAppDelegate.h"
#import "DownloadLib/DownloadLib.h"

@implementation TestAppDelegate

#pragma mark - app delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] ;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [startButton setTitle:@"开始" forState:UIControlStateNormal];
    startButton.frame = CGRectMake(110, 100, 100, 50);
    [startButton addTarget:self action:@selector(startDownload) forControlEvents:UIControlEventTouchUpInside];
    [self.window addSubview:startButton];
    
    
    UIButton *pauseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [pauseButton setTitle:@"暂停" forState:UIControlStateNormal];
    pauseButton.frame = CGRectMake(110, 200, 100, 50);
    [pauseButton addTarget:[DownloadManager sharedQueueManager] action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    [self.window addSubview:pauseButton];
    
    UIButton *resumeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [resumeButton setTitle:@"继续" forState:UIControlStateNormal];
    resumeButton.frame = CGRectMake(110, 300, 100, 50);
    [resumeButton addTarget:[DownloadManager sharedQueueManager] action:@selector(resume) forControlEvents:UIControlEventTouchUpInside];
    [self.window addSubview:resumeButton];
    return YES;
}


- (void)startDownload
{
    DownloadTask* downloadTask = [[DownloadTask alloc] initWithTargetURL:@"http://pic15.nipic.com/20110815/6989242_213231426121_2.jpg"];
    downloadTask.memoryCacheSize = 50;  // 设置缓冲区大小
    downloadTask.downloadRateLimit = 1; // 限制下载速度
    downloadTask.tag = 1;
    [[DownloadManager sharedQueueManager] addDownloader:downloadTask];  // 加入到下载队列

    DownloadTask* downloader2 = [[DownloadTask alloc] initWithTargetURL:@"http://pic3.nipic.com/20090604/497344_093404078_2.jpg"];
    downloader2.memoryCacheSize = 50;
    downloader2.downloadRateLimit = 5;
    downloader2.tag = 2;
    [[DownloadManager sharedQueueManager] addDownloader:downloader2];
    
    
    DownloadTask* downloader3 = [[DownloadTask alloc] initWithTargetURL:@"http://pic23.nipic.com/20120819/6787991_103140683159_2.jpg"];
    downloader3.memoryCacheSize = 50;
    downloader3.downloadRateLimit = 50;
    downloader3.tag = 3;
    [[DownloadManager sharedQueueManager] addDownloader:downloader3];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
