/*
Copyright (c) 2012, Yahoo! Inc.  All rights reserved.
Copyrights licensed under the New BSD License. See the accompanying LICENSE
file for terms.
*/
// [AUTO_HEADER]

#import <Cocoa/Cocoa.h>
#import "TakaoSettings.h"

/*!
	@header TakaoUpdate
*/

/*
	@class TakaoUpdate
	@abstract The controller to handle checking for updates
	and download the newer version.	
*/

@interface TakaoUpdate : NSObject <NSURLSessionDownloadDelegate>
{
	IBOutlet id _checkProgressIndicator;
	IBOutlet id _currentVersionTextField;
	IBOutlet id _latestVersionTextField;
	IBOutlet id _latestCheckTextField;
	IBOutlet id _window;
    NSButton *_downloadButton;
    NSButton *_checkButton;
    NSTextField *_downloadStatus;
    NSDictionary *_manifest;
    NSURLSession *_downloadSession;
    BOOL _checking;
    BOOL _downloading;
}

/*!
	@method checkUpdateNow:
	@abstract To check for updates.
	@param sender The sender object.
*/
- (IBAction)checkUpdateNow:(id)sender;
@end
