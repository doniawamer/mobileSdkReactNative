/*
 Copyright (c) 2017-present, salesforce.com, inc. All rights reserved.

 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#import <WebKit/WebKit.h>
#import "SFSDKWebViewStateManager.h"
#import "SFUserAccountManager.h"
static NSString *const ERR_NO_DOMAIN_NAMES = @"No domain names given for deleting cookies.";

@implementation SFSDKWebViewStateManager

static WKProcessPool *_processPool = nil;
static BOOL _sessionCookieManagementDisabled = NO;

+ (void)removeSession {
    
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [SFSDKWebViewStateManager removeSession];
        });
        return;
    }
    
    self.sharedProcessPool = nil;
    
    if (_sessionCookieManagementDisabled) {
        [SFSDKCoreLogger d:self format:@"[%@ %@]: Cookie Management disabled. Will do nothing.", NSStringFromClass(self), NSStringFromSelector(_cmd)];
        return;
    }
    
    //reset WKWebView related state if any
    [self removeWKWebViewCookies:self.domains withCompletion:NULL];
  
}

+ (WKProcessPool *)sharedProcessPool {
    if (!_processPool) {
        [SFSDKCoreLogger i:self format:@"[%@ %@]: No process pool exists.  Creating new instance.", NSStringFromClass(self), NSStringFromSelector(_cmd)];
        _processPool = [[WKProcessPool alloc] init];
    }
    return _processPool;
}

+ (void)setSharedProcessPool:(WKProcessPool *)sharedProcessPool {
    if (sharedProcessPool != _processPool) {
        [SFSDKCoreLogger i:self format:@"[%@ %@]: changing from process pool %@ to %@", NSStringFromClass(self), NSStringFromSelector(_cmd), _processPool, sharedProcessPool];
        _processPool = sharedProcessPool;
    }
}

+ (void)setSessionCookieManagementDisabled:(BOOL)sessionCookieManagementDisabled {
    _sessionCookieManagementDisabled = sessionCookieManagementDisabled;
}


+(BOOL) isSessionCookieManagementDisabled {
    return _sessionCookieManagementDisabled;
}


#pragma mark Private helper methods

+ (void)removeWKWebViewCookies:(NSArray *)domainNames withCompletion:(nullable void(^)(void))completionBlock {
    if (_sessionCookieManagementDisabled) {
        [SFSDKCoreLogger d:self format:@"[%@ %@]: Cookie Management disabled. Will do nothing.", NSStringFromClass(self), NSStringFromSelector(_cmd)];
        return;
    }
    
    NSAssert(domainNames != nil && [domainNames count] > 0, ERR_NO_DOMAIN_NAMES);
    WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
    NSSet *websiteDataTypes = [NSSet setWithArray:@[ WKWebsiteDataTypeCookies]];
    [dataStore fetchDataRecordsOfTypes:websiteDataTypes
                     completionHandler:^(NSArray<WKWebsiteDataRecord *> *records) {
                         NSMutableArray<WKWebsiteDataRecord *> *deletedRecords = [NSMutableArray new];
                         for (WKWebsiteDataRecord * record in records) {
                             // Cookie record display names look like "salesforce.com", "force.com". Make
                             // them look like proper cookie domain suffixes, for comparison.
                             NSString *recordDisplayName = [NSString stringWithFormat:@".%@", record.displayName];
                             for(NSString *domainName in domainNames) {
                                 if ([domainName hasSuffix:recordDisplayName]) {
                                     [deletedRecords addObject:record];
                                 }
                             }
                         }
                         if (deletedRecords.count > 0) {
                             [dataStore removeDataOfTypes:websiteDataTypes
                                           forDataRecords:deletedRecords
                                        completionHandler:^{
                                            if (completionBlock)
                                                completionBlock();
                                        }];
                         } else {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 if (completionBlock) {
                                     completionBlock();
                                 }
                             });
                         }
                     }];
}

+ (NSArray<NSString *> *) domains {
    return @[@".salesforce.com", @".force.com", @".cloudforce.com"];
}

+ (void)resetSessionCookie
{
    if (_sessionCookieManagementDisabled) {
        [SFSDKCoreLogger d:self format:@"[%@ %@]: Cookie Management disabled. Will do nothing.", NSStringFromClass(self), NSStringFromSelector(_cmd)];
        return;
    }
    [self removeWKWebViewCookies:self.domains withCompletion:nil];
}

@end
