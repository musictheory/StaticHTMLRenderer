/*
    File: URLProtocol.m
    
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


#import "URLProtocol.h"

static NSString *sRoot = nil;


@implementation URLProtocol

+ (void) setRootPath:(NSString *)path
{
    sRoot = path;
}


+ (NSString *) scheme
{
    return @"staticrenderer";
}


+ (BOOL) canInitWithRequest:(NSURLRequest *)request
{
    return [[[request URL] scheme] isEqualToString:[self scheme]];
}


+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}


+ (BOOL) requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return NO;
}


- (void) startLoading
{
    NSURLRequest *request = [self request];
    id<NSURLProtocolClient> client = [self client];

    NSString *path = [[request URL] path];
    NSString *extension = [path pathExtension];
    
    BOOL canAffectStaticHTML = YES;
    NSData *data = nil;
    
    if ([extension isEqualToString:@"css"] ||
        [extension isEqualToString:@"png"] || 
        [extension isEqualToString:@"jpg"] || 
        [extension isEqualToString:@"jpeg"] || 
        [extension isEqualToString:@"gif"])
    {
        canAffectStaticHTML = NO;
    }

    if (canAffectStaticHTML) {
        NSString *localFile = [[sRoot stringByAppendingString:path] stringByStandardizingPath];
        data = [[NSData alloc] initWithContentsOfFile:localFile];
    }
    
    if (data) {
        [client URLProtocol:self didLoadData:data];
        [client URLProtocolDidFinishLoading:self];
    } else {
        if (canAffectStaticHTML) {
            NSLog(@"No data for: %@", request);
        }

        [client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"URLProtocol" code:-1 userInfo:nil]];
    }
    
}


- (void) stopLoading { }


@end
