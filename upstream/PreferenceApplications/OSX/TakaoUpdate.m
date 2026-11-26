/*
Copyright (c) 2012, Yahoo! Inc.  All rights reserved.
Copyrights licensed under the New BSD License. See the accompanying LICENSE
file for terms.
*/
// [AUTO_HEADER]

#import "TakaoUpdate.h"
#import "TakaoHelper.h"
#import "../../Loaders/OSX-IMK/LKKUpdateManifest.h"
#import <CommonCrypto/CommonDigest.h>


@implementation TakaoUpdate

- (NSString *)currentVersion
{
    NSString *path = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    path = [path stringByDeletingLastPathComponent];
    return [[NSBundle bundleWithPath:path] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"0.1.0";
}

- (void)refreshManifest:(NSDictionary *)manifest
{
    if (_manifest != manifest) {
        [_manifest release];
        _manifest = [manifest retain];
    }
    NSString *latest = [_manifest objectForKey:@"version"];
    NSString *current = [self currentVersion];
    [_currentVersionTextField setStringValue:current];
    [_latestVersionTextField setStringValue:latest ?: @""];
    NSDate *checked = [_manifest objectForKey:@"checked"];
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [_latestCheckTextField setStringValue:checked ? [formatter stringFromDate:checked] : @""];
    BOOL available = LKKValidVersion(latest) && [latest compare:current options:NSNumericSearch] == NSOrderedDescending;
    [_downloadButton setHidden:(!available && !_downloading)];
    [_downloadButton setEnabled:available && !_downloading && !_checking];
}

- (void)refreshCachedManifest:(NSNotification *)notification
{
    if (!_checking && !_downloading)
        [self refreshManifest:[NSDictionary dictionaryWithContentsOfFile:LKKUpdateCachePath()]];
}

- (void)awakeFromNib
{
    NSView *view = [_checkProgressIndicator superview];
    for (NSView *child in [view subviews]) {
        if ([child isKindOfClass:[NSButton class]] && [(NSButton *)child action] == @selector(checkUpdateNow:)) {
            _checkButton = (NSButton *)child;
            break;
        }
    }
    NSRect frame = [_checkButton frame];
    _downloadButton = [[[NSButton alloc] initWithFrame:NSMakeRect(NSMaxX(frame) + 2, frame.origin.y, 100, frame.size.height)] autorelease];
    [_downloadButton setBezelStyle:NSBezelStyleRounded];
    [_downloadButton setTitle:LFLSTR(@"Download Update")];
    [_downloadButton setTarget:self];
    [_downloadButton setAction:@selector(downloadUpdate:)];
    [view addSubview:_downloadButton];
    _downloadStatus = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, 0, 440, 16)] autorelease];
    [_downloadStatus setEditable:NO];
    [_downloadStatus setSelectable:NO];
    [_downloadStatus setBordered:NO];
    [_downloadStatus setDrawsBackground:NO];
    [view addSubview:_downloadStatus];
    NSRect checkFrame = [_latestCheckTextField frame];
    checkFrame.size.width = 260;
    [_latestCheckTextField setFrame:checkFrame];
    [_checkProgressIndicator setHidden:YES];
    [self refreshCachedManifest:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshCachedManifest:) name:NSApplicationDidBecomeActiveNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_manifest release];
    [_downloadSession invalidateAndCancel];
    [_downloadSession release];
    [super dealloc];
}

- (IBAction)checkUpdateNow:(id)sender
{
    if (_checking || _downloading) return;
    _checking = YES;
    [_checkButton setEnabled:NO];
    [_downloadButton setEnabled:NO];
    [_downloadButton setHidden:YES];
    [_checkProgressIndicator setHidden:NO];
    [_checkProgressIndicator startAnimation:self];
    LKKFetchUpdateManifest(^(NSDictionary *manifest) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _checking = NO;
            [_checkProgressIndicator stopAnimation:self];
            [_checkProgressIndicator setHidden:YES];
            [_checkButton setEnabled:YES];
            if (manifest) {
                [self refreshManifest:manifest];
                [_downloadStatus setStringValue:[_downloadButton isHidden] ? LFLSTR(@"You are now using the newest version.") : LFLSTR(@"New version available")];
            } else {
                [self refreshCachedManifest:nil];
                [_downloadStatus setStringValue:LFLSTR(@"Unable to check for update via the Internet.")];
            }
        });
    });
}

- (void)downloadFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_downloading) return;
        _downloading = NO;
        [_checkButton setEnabled:YES];
        [self refreshManifest:_manifest];
        [_downloadStatus setStringValue:LFLSTR(@"Download failed; opening release page.")];
        [[NSWorkspace sharedWorkspace] openURL:LKKReleasePage()];
    });
}

- (IBAction)downloadUpdate:(id)sender
{
    if (_downloading || _checking) return;
    NSURL *url = LKKPackageURL([_manifest objectForKey:@"version"]);
    if (!url) return;
    _downloading = YES;
    [_checkButton setEnabled:NO];
    [_downloadButton setEnabled:NO];
    [_downloadStatus setStringValue:LFLSTR(@"Downloading update...")];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.timeoutIntervalForResource = 600;
    [_downloadSession release];
    _downloadSession = [[NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil] retain];
    [[_downloadSession downloadTaskWithURL:url] resume];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)task didWriteData:(int64_t)bytes totalBytesWritten:(int64_t)written totalBytesExpectedToWrite:(int64_t)expected
{
    if (written > 128 * 1024 * 1024) { [task cancel]; return; }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_downloading && expected > 0)
            [_downloadStatus setStringValue:[NSString stringWithFormat:@"%@ %.0f%%", LFLSTR(@"Downloading update..."), 100.0 * written / expected]];
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)task didFinishDownloadingToURL:(NSURL *)location
{
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)[task response];
    NSData *data = [NSData dataWithContentsOfURL:location options:NSDataReadingMappedIfSafe error:NULL];
    if (![response isKindOfClass:[NSHTTPURLResponse class]] || [response statusCode] != 200 || ![[[response URL] scheme] isEqualToString:@"https"] || !data || [data length] > 128 * 1024 * 1024) { [self downloadFailed]; return; }
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([data bytes], (CC_LONG)[data length], digest);
    NSMutableString *hash = [NSMutableString string];
    for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; ++index) [hash appendFormat:@"%02x", digest[index]];
    if (![hash isEqualToString:[_manifest objectForKey:@"sha256"]]) { [self downloadFailed]; return; }
    NSURL *downloads = [[[NSFileManager defaultManager] URLsForDirectory:NSDownloadsDirectory inDomains:NSUserDomainMask] firstObject];
    if (!downloads) { [self downloadFailed]; return; }
    NSString *name = [NSString stringWithFormat:@"LKK-IME-%@-%@.pkg", [_manifest objectForKey:@"version"], [[NSUUID UUID] UUIDString]];
    NSURL *destination = [downloads URLByAppendingPathComponent:name];
    if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:destination error:NULL]) { [self downloadFailed]; return; }
    // Never automatically launch a package that fails the system trust assessment.
    NSTask *assessment = [[[NSTask alloc] init] autorelease];
    [assessment setLaunchPath:@"/usr/sbin/spctl"];
    [assessment setArguments:@[@"--assess", @"--type", @"install", [destination path]]];
    [assessment setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [assessment setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    BOOL trusted = NO;
    @try { [assessment launch]; [assessment waitUntilExit]; trusted = [assessment terminationStatus] == 0; } @catch (NSException *exception) {}
    dispatch_async(dispatch_get_main_queue(), ^{
        _downloading = NO;
        [_checkButton setEnabled:YES];
        [self refreshManifest:_manifest];
        if (trusted) {
            [_downloadStatus setStringValue:LFLSTR(@"Download complete")];
            [[NSWorkspace sharedWorkspace] openURL:destination];
        } else {
            [_downloadStatus setStringValue:LFLSTR(@"Installer is not trusted by macOS; opening release page.")];
            [[NSWorkspace sharedWorkspace] openURL:LKKReleasePage()];
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) [self downloadFailed];
    [session finishTasksAndInvalidate];
}
@end
