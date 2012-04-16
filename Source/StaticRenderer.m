/*
    File: StaticRenderer.m
    
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

#import "StaticRenderer.h"
#import "URLProtocol.h"


@interface WebView (Private)
- (void) setScriptDebugDelegate:(id)delegate;
@end


@implementation StaticRenderer {
    WebView  *_webView;
    NSString *_outputFile;
    id        _options;
}


#pragma mark -
#pragma mark Class Methods

+ (BOOL) isSelectorExcludedFromWebScript:(SEL)aSelector
{
    if (aSelector == @selector(save) ||
        aSelector == @selector(log:))
    {
        return NO;
    }
    
    return YES;
}


+ (BOOL) isKeyExcludedFromWebScript:(const char *)name
{
    NSString *keyName = [NSString stringWithUTF8String:name];
    return ![keyName isEqualToString:@"options"];
}


+ (NSString *)webScriptNameForKey:(const char *)name
{
    NSString *keyName = [NSString stringWithUTF8String:name];

    if ([keyName isEqualToString:@"_options"]) {
        return @"options";
    }

    return nil;
}


#pragma mark -
#pragma mark Lifecycle

- (id) init
{
    if (self = [super init]) {
        NSRect frame = NSMakeRect(0, 0, 800.0, 600.0);

        WebPreferences *preferences = [WebPreferences standardPreferences];

        [preferences setLoadsImagesAutomatically:NO];
        [preferences setUserStyleSheetEnabled:NO];
        [preferences setPrivateBrowsingEnabled:YES];
        [preferences setPlugInsEnabled:NO];
        [preferences setJavaScriptEnabled:YES];

        _webView = [[WebView alloc] initWithFrame:frame frameName:nil groupName:nil];
        [_webView setPreferences:preferences];
        [_webView setFrameLoadDelegate:self];
        [_webView setResourceLoadDelegate:self];
        [_webView setPolicyDelegate:self];
        [_webView setUIDelegate:self];
        
        if ([_webView respondsToSelector:@selector(setScriptDebugDelegate:)]) {
            [(id)_webView setScriptDebugDelegate:self];
        }
    }
    
    return self;
}


- (void) dealloc
{
    [_webView setFrameLoadDelegate:nil];
    [_webView setResourceLoadDelegate:nil];
    [_webView setPolicyDelegate:nil];
    [_webView setUIDelegate:nil];

    if ([_webView respondsToSelector:@selector(setScriptDebugDelegate:)]) {
        [(id)_webView setScriptDebugDelegate:nil];
    }
}


#pragma mark -
#pragma mark Public Methods

- (void) renderInputFile: (NSString *) inputFile
              outputFile: (NSString *) outputFile
                     url: (NSURL *) url
                 options: (id) options;
{
    _outputFile = [outputFile copy];
    _options    = [options copy];

    NSData *data = [NSData dataWithContentsOfFile:inputFile];
    [[_webView mainFrame] loadData:data MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:url];

    CFRunLoopRun();
}


- (void) log:(NSString *)string
{
    NSLog(@"%@", string);
}


- (void) save
{
    DOMElement *element = [[[_webView mainFrame] DOMDocument] documentElement];
    NSString *html = nil;

    if ([element respondsToSelector:@selector(outerHTML)]) {
        html = [(id)element outerHTML];
    }

    NSError *error;
    if (html && ![html writeToFile:_outputFile atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        NSLog(@"Could not write to \"%@\": %@", _outputFile, error);
    }

    CFRunLoopStop(CFRunLoopGetMain());
}


#pragma mark -
#pragma mark Web View Delegate Methods

- (void) webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
    [windowObject setValue:self forKey:@"StaticRenderer"];
}


- (NSURLRequest *) webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
    if ([[[request URL] scheme] isEqualToString:[URLProtocol scheme]]) {
        return request;
    }
    
    return nil;
}


- (void) webView:(WebView *)webView failedToParseSource: (NSString *) source
                                         baseLineNumber: (NSUInteger) lineNumber
                                                fromURL: (NSURL *) url
                                              withError: (NSError *) error
                                            forWebFrame: (WebFrame *) webFrame
{
    NSLog(@"Error: Could not parse source: %@:%ld", url, (long)lineNumber);
    CFRunLoopStop(CFRunLoopGetMain());
}


- (void) webView:(WebView *)webView exceptionWasRaised: (id) frame
                                            hasHandler: (BOOL) hasHandler
                                              sourceId: (intptr_t) sid
                                                  line: (int)lineno
                                           forWebFrame: (WebFrame *) webFrame
{
    NSLog(@"Error: JavaScript exception raised: %@", frame);
    CFRunLoopStop(CFRunLoopGetMain());
}


@end
