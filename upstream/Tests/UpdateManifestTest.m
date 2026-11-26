#import <Foundation/Foundation.h>
#import "../Loaders/OSX-IMK/LKKUpdateManifest.h"

int main(void)
{
    @autoreleasepool {
        NSString *hash = [@"a" stringByPaddingToLength:64 withString:@"a" startingAtIndex:0];
        NSData *valid = [NSJSONSerialization dataWithJSONObject:@{ @"version": @"0.1.2", @"sha256": hash } options:0 error:NULL];
        NSDictionary *manifest = LKKParseUpdateManifest(valid);
        if (![[manifest objectForKey:@"version"] isEqual:@"0.1.2"] || ![[manifest objectForKey:@"sha256"] isEqual:hash]) return 1;
        if (![[LKKPackageURL(@"0.1.2") absoluteString] isEqual:@"https://github.com/Wing/LKK-IME/releases/download/v0.1.2/LKK-IME-arm64.pkg"]) return 2;
        if (LKKPackageURL(@"../0.1.2") || LKKValidVersion(@"0.1.2\nmalformed") || LKKValidVersion(@"0.1.2\n")) return 3;
        if (LKKParseUpdateManifest([@"[]" dataUsingEncoding:NSUTF8StringEncoding])) return 4;
        if (LKKParseUpdateManifest([@"{\"version\":\"0.1.2\",\"sha256\":\"bad\"}" dataUsingEncoding:NSUTF8StringEncoding])) return 5;
        puts("PASS: update manifest validation and fixed release URL");
    }
    return 0;
}
