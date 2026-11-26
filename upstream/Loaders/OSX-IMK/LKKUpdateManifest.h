#ifndef LKK_UPDATE_MANIFEST_H
#define LKK_UPDATE_MANIFEST_H

#import <Foundation/Foundation.h>

static NSString *LKKUpdateSettingsPath(NSString *name)
{
    return [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences"] stringByAppendingPathComponent:name];
}

static NSString *LKKUpdateCachePath(void)
{
    return LKKUpdateSettingsPath(@"io.github.wing.lkkime.UpdateCheck.plist");
}

static BOOL LKKValidVersion(NSString *version)
{
    if (![version isKindOfClass:[NSString class]]) return NO;
    NSRange match = [version rangeOfString:@"^[0-9]{1,6}\\.[0-9]{1,6}\\.[0-9]{1,6}$" options:NSRegularExpressionSearch];
    return match.location == 0 && match.length == [version length];
}

static NSDictionary *LKKParseUpdateManifest(NSData *data)
{
    if (!data || [data length] > 16384) return nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (![json isKindOfClass:[NSDictionary class]]) return nil;
    NSString *version = [json objectForKey:@"version"];
    NSString *sha = [json objectForKey:@"sha256"];
    if (!LKKValidVersion(version) || ![sha isKindOfClass:[NSString class]] || [sha length] != 64 || [sha rangeOfString:@"^[a-fA-F0-9]{64}$" options:NSRegularExpressionSearch].location == NSNotFound) return nil;
    return @{ @"version": version, @"sha256": [sha lowercaseString], @"checked": [NSDate date] };
}

static NSURL *LKKReleasePage(void)
{
    return [NSURL URLWithString:@"https://github.com/Wing/LKK-IME/releases"];
}

static NSURL *LKKPackageURL(NSString *version)
{
    if (!LKKValidVersion(version)) return nil;
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/Wing/LKK-IME/releases/download/v%@/LKK-IME-arm64.pkg", version]];
}

static BOOL LKKCheckOnLaunchEnabled(void)
{
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:LKKUpdateSettingsPath(@"io.github.wing.lkkime.plist")];
    return [[settings objectForKey:@"ShouldCheckUpdateOnLaunch"] isEqual:@"true"];
}

static void LKKFetchUpdateManifest(void (^completion)(NSDictionary *))
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.timeoutIntervalForRequest = 20;
    configuration.timeoutIntervalForResource = 30;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURL *url = [NSURL URLWithString:@"https://raw.githubusercontent.com/Wing/LKK-IME/main/version.json"];
    [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *manifest = nil;
        if (!error && [response isKindOfClass:[NSHTTPURLResponse class]] && [(NSHTTPURLResponse *)response statusCode] == 200 && [[[response URL] scheme] isEqualToString:@"https"]) {
            manifest = LKKParseUpdateManifest(data);
            if (manifest) [manifest writeToFile:LKKUpdateCachePath() atomically:YES];
        }
        if (completion) completion(manifest);
        [session finishTasksAndInvalidate];
    }] resume];
}
#endif
