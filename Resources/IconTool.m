// SPDX-License-Identifier: BSD-3-Clause
#import <Cocoa/Cocoa.h>

int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc != 2) return 1;
        NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(512, 512)];
        [image lockFocus];
        [[NSColor colorWithSRGBRed:.10 green:.30 blue:.25 alpha:1] setFill];
        [[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(16,16,480,480) xRadius:100 yRadius:100] fill];
        NSDictionary *attributes = @{NSFontAttributeName:[NSFont boldSystemFontOfSize:145], NSForegroundColorAttributeName:NSColor.whiteColor};
        [@"LKK" drawAtPoint:NSMakePoint(84,165) withAttributes:attributes];
        [image unlockFocus];
        NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:image.TIFFRepresentation];
        NSData *data = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        return [data writeToFile:[NSString stringWithUTF8String:argv[1]] atomically:YES] ? 0 : 1;
    }
}
