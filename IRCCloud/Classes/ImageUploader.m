//
//  ImageUploader.m
//
//  Copyright (C) 2014 IRCCloud, Ltd.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "ImageUploader.h"
#import "NSData+Base64.h"
#import "config.h"

@implementation ImageUploader

-(void)upload:(UIImage *)img {
#ifdef EXTENSION
#ifdef ENTERPRISE
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
#else
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
#endif
    self->_image = img;
    if([d objectForKey:@"imgur_access_token"])
        [self performSelectorOnMainThread:@selector(_authorize) withObject:nil waitUntilDone:NO];
    else
        [self performSelectorInBackground:@selector(_upload:) withObject:img];
}

-(void)_authorize {
    NSUserDefaults *d;
#ifdef ENTERPRISE
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif

#ifdef IMGUR_KEY
    NSUserDefaults *d2 = [NSUserDefaults standardUserDefaults];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.imgur.com/oauth2/token"]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"refresh_token=%@&client_id=%@&client_secret=%@&grant_type=refresh_token", [d objectForKey:@"imgur_refresh_token"], @IMGUR_KEY, @IMGUR_SECRET] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error renewing token. Error %li : %@", (long)error.code, error.userInfo);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self->_delegate imageUploadDidFail];
            }];
        } else {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if([dict objectForKey:@"access_token"]) {
                for(NSString *key in dict.allKeys) {
                    if([[dict objectForKey:key] isKindOfClass:[NSString class]]) {
                        [d setObject:[dict objectForKey:key] forKey:[NSString stringWithFormat:@"imgur_%@", key]];
                        [d2 setObject:[dict objectForKey:key] forKey:[NSString stringWithFormat:@"imgur_%@", key]];
                    }
                }
                [d synchronize];
                [d2 synchronize];
                [self performSelectorInBackground:@selector(_upload:) withObject:self->_image];
            } else {
                [self->_delegate performSelector:@selector(imageUploadNotAuthorized) withObject:nil afterDelay:0.25];
            }
        }
    }];
#else
    [self->_delegate performSelector:@selector(imageUploadNotAuthorized) withObject:nil afterDelay:0.25];
#endif
}

//http://stackoverflow.com/a/19697172
- (UIImage *)image:(UIImage *)image scaledCopyOfSize:(CGSize)newSize {
    if(image.size.width <= newSize.width && image.size.height <= newSize.height)
        return image;

    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > newSize.width || height > newSize.height) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = newSize.width;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = newSize.height;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

-(void)_upload:(UIImage *)img {
    self->_response = [[NSMutableData alloc] init];
    NSUserDefaults *d;
#ifdef ENTERPRISE
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    int size = [[d objectForKey:@"photoSize"] intValue];
    NSData *data = UIImageJPEGRepresentation((size != -1)?[self image:img scaledCopyOfSize:CGSizeMake(size,size)]:img, 0.8);
    CFStringRef data_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[data base64EncodedString], NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
    
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
#ifdef MASHAPE_KEY
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://imgur-apiv3.p.mashape.com/3/image"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setValue:@MASHAPE_KEY forHTTPHeaderField:@"X-Mashape-Authorization"];
#else
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.imgur.com/3/image"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
#endif
    [request setHTTPShouldHandleCookies:NO];
#ifdef IMGUR_KEY
    if([d objectForKey:@"imgur_access_token"]) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", [d objectForKey:@"imgur_access_token"]] forHTTPHeaderField:@"Authorization"];
    } else {
        [request setValue:[NSString stringWithFormat:@"Client-ID %@", @IMGUR_KEY] forHTTPHeaderField:@"Authorization"];
    }
#endif
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"image=%@", data_escaped] dataUsingEncoding:NSUTF8StringEncoding]];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"backgroundUploads"]) {
        NSURLSession *session;
        NSURLSessionConfiguration *config;
        config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"com.irccloud.share.image.%li", time(NULL)]];
#ifdef ENTERPRISE
        config.sharedContainerIdentifier = @"group.com.irccloud.enterprise.share";
#else
        config.sharedContainerIdentifier = @"group.com.irccloud.share";
#endif
        config.HTTPCookieStorage = nil;
        config.URLCache = nil;
        config.requestCachePolicy = NSURLCacheStorageNotAllowed;
        config.discretionary = NO;
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        self->_body = [[NSString stringWithFormat:@"image=%@", data_escaped] dataUsingEncoding:NSUTF8StringEncoding];
        NSURLSessionTask *task = [session downloadTaskWithRequest:request];
        
        if(session.configuration.identifier) {
            NSMutableDictionary *tasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
            if(!tasks)
                tasks = [[NSMutableDictionary alloc] init];
            
            if(self->_msg)
                [tasks setObject:@{@"service":@"imgur", @"bid":@(self->_bid), @"msg":self->_msg} forKey:session.configuration.identifier];
            else
                [tasks setObject:@{@"service":@"imgur", @"bid":@(self->_bid)} forKey:session.configuration.identifier];

            [d setObject:tasks forKey:@"uploadtasks"];
            [d synchronize];
        }

        [task resume];
    } else {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self->_connection = [NSURLConnection connectionWithRequest:request delegate:self];
            [self->_connection start];
        }];
    }
    CFRelease(data_escaped);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if(self->_delegate)
        [self->_delegate imageUploadProgress:(float)totalBytesWritten / (float)totalBytesExpectedToWrite];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self->_response appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    [self->_delegate imageUploadDidFail];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
#ifdef EXTENSION
#ifdef ENTERPRISE
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
#else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    
    NSDictionary *d = [NSJSONSerialization JSONObjectWithData:self->_response options:kNilOptions error:nil];
    if(!d) {
        CLS_LOG(@"IMGUR: Invalid JSON response: %@", [[NSString alloc] initWithData:self->_response encoding:NSUTF8StringEncoding]);
    }
#ifdef IMGUR_KEY
    if([defaults objectForKey:@"imgur_access_token"] && [[d objectForKey:@"success"] intValue] == 0 && [[d objectForKey:@"status"] intValue] == 403) {
        [self _authorize];
        return;
    }
#endif
    [self->_delegate imageUploadDidFinish:d bid:self->_bid];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    [self connection:self->_connection didSendBodyData:(NSInteger)bytesSent totalBytesWritten:(NSInteger)totalBytesSent totalBytesExpectedToWrite:(NSInteger)_body.length];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    self->_response = [NSData dataWithContentsOfURL:location].mutableCopy;
    [[NSFileManager defaultManager] removeItemAtURL:location error:nil];
    [self connectionDidFinishLoading:self->_connection];
    NSUserDefaults *d;
#ifdef ENTERPRISE
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    NSMutableDictionary *uploadtasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
    [uploadtasks removeObjectForKey:session.configuration.identifier];
    [d setObject:uploadtasks forKey:@"uploadtasks"];
    [d synchronize];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSUserDefaults *d;
#ifdef ENTERPRISE
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    NSMutableDictionary *uploadtasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
    [uploadtasks removeObjectForKey:session.configuration.identifier];
    [d setObject:uploadtasks forKey:@"uploadtasks"];
    [d synchronize];

    if(error) {
#ifndef EXTENSION
        if([error.domain isEqualToString:NSURLErrorDomain]) {
            if(error.code == NSURLErrorUnknown || error.code == NSURLErrorBackgroundSessionWasDisconnected) {
                CLS_LOG(@"Lost connection to background upload service, retrying in-process");
#ifdef MASHAPE_KEY
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://imgur-apiv3.p.mashape.com/3/image"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
                [request setValue:@MASHAPE_KEY forHTTPHeaderField:@"X-Mashape-Authorization"];
#else
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.imgur.com/3/image"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
#endif
                [request setHTTPShouldHandleCookies:NO];
#ifdef IMGUR_KEY
                if([d objectForKey:@"imgur_access_token"]) {
                    [request setValue:[NSString stringWithFormat:@"Bearer %@", [d objectForKey:@"imgur_access_token"]] forHTTPHeaderField:@"Authorization"];
                } else {
                    [request setValue:[NSString stringWithFormat:@"Client-ID %@", @IMGUR_KEY] forHTTPHeaderField:@"Authorization"];
                }
#endif
                [request setHTTPMethod:@"POST"];
                [request setHTTPBody:self->_body];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    self->_connection = [NSURLConnection connectionWithRequest:request delegate:self];
                    [self->_connection start];
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                }];
                return;
            }
        }
#endif
        CLS_LOG(@"Upload error: %@", error);
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self->_delegate imageUploadDidFail];
        }];
    }
    [session finishTasksAndInvalidate];
}
@end
