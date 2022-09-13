/*
 Copyright (c) 2014-present, salesforce.com, inc. All rights reserved.
 
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

#import "SFSDKAppConfig.h"
#import "SFSDKResourceUtils.h"

// Config error constants
NSString * const SFSDKDefaultNativeAppConfigFilePath = @"/bootconfig.plist";
NSString * const SFSDKAppConfigErrorDomain = @"com.salesforce.mobilesdk.AppConfigErrorDomain";

static NSString* const kRemoteAccessConsumerKey = @"remoteAccessConsumerKey";
static NSString* const kOauthRedirectURI = @"oauthRedirectURI";
static NSString* const kOauthScopes = @"oauthScopes";
static NSString* const kShouldAuthenticate = @"shouldAuthenticate";
static BOOL const kDefaultShouldAuthenticate = YES;

@interface SFSDKAppConfig()
+ (void)createError:(NSError * _Nullable * _Nullable)error withCode:(NSInteger)errorCode message:(nonnull NSString *)message;
@end

@implementation SFSDKAppConfig

- (instancetype)init
{
    return [self initWithDict:nil];
}

- (instancetype)initWithDict:(NSDictionary *)configDict
{
    self = [super init];
    if (self) {
        if (configDict == nil) {
            self.configDict = [NSMutableDictionary dictionary];
        } else {
            self.configDict = [NSMutableDictionary dictionaryWithDictionary:configDict];
        }
        
        if ((self.configDict)[kShouldAuthenticate] == nil) {
            self.shouldAuthenticate = kDefaultShouldAuthenticate;
        }

        NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        self.configDict[kRemoteAccessConsumerKey] = [self.configDict[kRemoteAccessConsumerKey] stringByTrimmingCharactersInSet:whitespaceSet];
        self.configDict[kOauthRedirectURI] = [self.configDict[kOauthRedirectURI] stringByTrimmingCharactersInSet:whitespaceSet];
    }
    return self;
}

- (instancetype)initWithConfigFile:(NSString *)configFile {
    self = [super init];
    if (self) {
        NSString *fullPath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:configFile];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
            [SFSDKCoreLogger i:[self class] format:@"%@ Config file does not exist at path '%@'", NSStringFromSelector(_cmd), fullPath];
            return nil;
        }
        NSDictionary *configDict = [NSDictionary dictionaryWithContentsOfFile:fullPath];
        if (configDict == nil) {
            [SFSDKCoreLogger i:[self class] format:@"%@ Could not parse the config file at path '%@'.  Config file is not in a valid plist format.", NSStringFromSelector(_cmd), fullPath];
            return nil;
        }

        self = [self initWithDict:configDict];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p data: %@>", NSStringFromClass([self class]), self, [self.configDict description]];
}

- (BOOL)validate:(NSError **)error {
    if (self.remoteAccessConsumerKey.length == 0) {
        [[self class] createError:error withCode:SFSDKAppConfigErrorCodeNoConsumerKey message:[SFSDKResourceUtils localizedString:@"appConfigValidationErrorNoConsumerKey"]];
        return NO;
    }
    if (self.oauthRedirectURI.length == 0) {
        [[self class] createError:error withCode:SFSDKAppConfigErrorCodeNoRedirectURI message:[SFSDKResourceUtils localizedString:@"appConfigValidationErrorNoRedirectURI"]];
        return NO;
    }
    if (self.oauthScopes.count == 0) {
        [[self class] createError:error withCode:SFSDKAppConfigErrorCodeNoOAuthScopes message:[SFSDKResourceUtils localizedString:@"appConfigValidationErrorNoOAuthScopes"]];
        return NO;
    }
    
    return YES;
}

#pragma mark - Properties

- (NSString *)remoteAccessConsumerKey
{
    return (self.configDict)[kRemoteAccessConsumerKey];
}

- (void)setRemoteAccessConsumerKey:(NSString *)remoteAccessConsumerKey
{
    self.configDict[kRemoteAccessConsumerKey] = [remoteAccessConsumerKey copy];
}

- (NSString *)oauthRedirectURI
{
    return (self.configDict)[kOauthRedirectURI];
}

- (void)setOauthRedirectURI:(NSString *)oauthRedirectURI
{
    self.configDict[kOauthRedirectURI] = [oauthRedirectURI copy];
}

- (NSSet *)oauthScopes
{
    return [NSSet setWithArray:(self.configDict)[kOauthScopes]];
}

- (void)setOauthScopes:(NSSet *)oauthScopes
{
    self.configDict[kOauthScopes] = [oauthScopes allObjects];
}

- (BOOL)shouldAuthenticate
{
    return [(self.configDict)[kShouldAuthenticate] boolValue];
}

- (void)setShouldAuthenticate:(BOOL)shouldAuthenticate
{
    NSNumber *shouldAuthenticateNum = @(shouldAuthenticate);
    self.configDict[kShouldAuthenticate] = shouldAuthenticateNum;
}

#pragma mark - Load config methods

+ (instancetype)fromDefaultConfigFile
{
    return [self fromConfigFile:SFSDKDefaultNativeAppConfigFilePath];
}

+ (instancetype)fromConfigFile:(NSString *)configFilePath
{
    NSAssert(configFilePath.length > 0, @"Must specify a config file path.");
    return [[self alloc] initWithConfigFile:configFilePath];
}

#pragma mark - Helper Methods

+ (void)createError:(NSError **)error withCode:(NSInteger)errorCode message:(NSString *)message {
    if (error != nil) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: message };
        *error = [NSError errorWithDomain:SFSDKAppConfigErrorDomain code:errorCode userInfo:userInfo];
    }
}

@end
