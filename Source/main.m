/*
    File: main.m
    
    License: The MIT License

    Copyright (c) 2011-2012 musictheory.net, LLC
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/


#import <Cocoa/Cocoa.h>
#import "StaticRenderer.h"
#import "URLProtocol.h"


#define bail(...) {   \
    err(__VA_ARGS__); \
    exit(1);          \
}


static void NS_FORMAT_FUNCTION(1,2) err(NSString *format, ...) 
{
    va_list v;
    va_start(v, format);

    NSString *s = [[NSString alloc] initWithFormat:format arguments:v];
    if (s) fprintf(stderr, "%s\n", [s UTF8String]);

    va_end(v);
}


int main(int argc, char *argv[]) { @autoreleasepool
{
    BOOL multi = NO;

    if (argc == 2) {
        NSString *argsFilePath   = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        NSString *argsFileString = [NSString stringWithContentsOfFile:argsFilePath encoding:NSUTF8StringEncoding error:nil];
        NSArray  *args           = [argsFileString componentsSeparatedByString:@"\n"];
        
        char *oldArgV0 = argv[0];
        argv = calloc(1, sizeof(void *) * ([args count] + 2));
        argv[0] = oldArgV0;

        int i = 1;
        for (NSString *arg in args) {
            argv[i++] = (char *)[arg UTF8String];
        }

        argc = [args count] + 1;
        
    }

    if (argc < 6 || (argc > 6 && (argc % 4 != 2))) {
        err(@"Usage: StaticHTMLRenderer root input_file output_file url [options]");
        err(@"");
        err(@"root        - The location on disk to use as the server's root.");
        err(@"input_file  - The path of the input HTML file.");
        err(@"output_file - The path of the output HTML file.");
        err(@"url         - A string to use as the working URL of the document.");
        err(@"options     - An optional JSON file, accessible in JavaScript via window.StaticRenderer.options");
        err(@"");
        err(@"Multiple pairs of (input_file/output_file/url/options) may be used:");
        err(@"");
        err(@"StaticHTMLRenderer root \\");
        err(@"                   input_file  output_file  url  options  \\");
        err(@"                   input_file2 output_file2 url2 options2 \\");
        err(@"                   input_file3 output_file3 url3 options3 \\");
        err(@"                   ...");
        bail(@"");
    }

    if (argc > 6) {
        multi = YES;
    }

    [NSURLProtocol registerClass:[URLProtocol class]];

    int i = 1;

    NSString *rootString = [[NSString alloc] initWithCString:argv[i++] encoding:NSUTF8StringEncoding];

    StaticRenderer *renderer = [[StaticRenderer alloc] init];

    while (i < argc) {
    @autoreleasepool {
        NSString *inputFile   = [NSString stringWithCString:argv[i++] encoding:NSUTF8StringEncoding];
        NSString *outputFile  = [NSString stringWithCString:argv[i++] encoding:NSUTF8StringEncoding];
        NSString *urlString   = [NSString stringWithCString:argv[i++] encoding:NSUTF8StringEncoding];
        id        options     = nil;

        if (i < argc) {
            NSString *optionsFile = [NSString stringWithCString:argv[i++] encoding:NSUTF8StringEncoding];

            if ([optionsFile length]) {
                NSData *jsonData = [NSData dataWithContentsOfFile:optionsFile];
                
                if (jsonData) {
                    NSError *error = nil;
                    options = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
                    if (!options) bail(@"Could not parse JSON: %@: %@", optionsFile, error);

                } else {
                    bail(@"Could not read file: %@", optionsFile);
                }
            }
        }

        if ([urlString hasPrefix:@"http://"]) {
            urlString = [urlString stringByReplacingCharactersInRange:NSMakeRange(0, 7) withString:@"staticrenderer://"];
        }
        
        NSURL *url = [NSURL URLWithString:urlString];
        if (!url) bail(@"Could not parse URL: %@", urlString);

        [URLProtocol setRootPath:rootString];
        [renderer renderInputFile:inputFile outputFile:outputFile url:url options:options];
        if (multi) { fprintf(stdout, "."); fflush(stdout); }
    } }


    if (multi) { fprintf(stdout, "\n"); fflush(stdout); }
}

    // Avoid CFNetwork cache & cooking-saving
    _Exit(0);

    return 0;
}
