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

#import "SFKeyStore+Internal.h"
#import "SFCrypto.h"
#import "SFSDKCryptoUtils.h"
#import <SalesforceSDKCommon/SalesforceSDKCommon-Swift.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation SFKeyStore
#pragma clang diagnostic pop

- (NSDictionary *)keyStoreDictionary
{
    @synchronized (self) {
        return [self keyStoreDictionaryWithKey:self.keyStoreKey];
    }
}

- (NSDictionary *)keyStoreDictionaryWithKey:(SFKeyStoreKey *)storeKey
{
    @synchronized (self) {
        NSString *keychainId = self.storeKeychainIdentifier;
        
        SFSDKKeychainResult *result = [SFSDKKeychainHelper createIfNotPresentWithService:keychainId account:nil];
        NSData *keyStoreData = result.data;
        // NB: We will return an empty dictionary if one doesn't exist, and nil if an existing dictionary
        // couldn't be decrypted.  This allows us to differentiate between a non-existent key store dictionary
        // and one that can't be accessed.
        if (keyStoreData == nil) {
            return @{};
        } else {
            NSDictionary *keyStoreDict = [self decryptDictionaryData:keyStoreData withKey:storeKey];
            return keyStoreDict;
        }
    }
}

- (void)setKeyStoreDictionary:(NSDictionary *)keyStoreDictionary
{
    [self setKeyStoreDictionary:keyStoreDictionary withKey:self.keyStoreKey];
}

- (void)setKeyStoreDictionary:(NSDictionary *)keyStoreDictionary withKey:(SFKeyStoreKey *)storeKey
{
    @synchronized (self) {
        NSString *keychainId = self.storeKeychainIdentifier;
        SFSDKKeychainResult *result =  [SFSDKKeychainHelper createIfNotPresentWithService:keychainId account:nil];
        if (keyStoreDictionary == nil) {
            result = [SFSDKKeychainHelper resetWithService:keychainId account:nil];
            if (!result.success) {
                [SFSDKCoreLogger e:[self class] format:@"Error removing key %@ store from the keychain.", keychainId];
            }
        } else {
            NSData *keyStoreData = [self encryptDictionary:keyStoreDictionary withKey:storeKey];
            result = [SFSDKKeychainHelper writeWithService:keychainId data:keyStoreData account:nil];
            if (!result.success) {
                [SFSDKCoreLogger e:[self class] format:@"Error saving key %@store to the keychain.", keychainId];
            }
        }
    }
}

- (NSData *)encryptDictionary:(NSDictionary *)dictionary withKey:(SFKeyStoreKey *)storeKey
{
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
    [archiver encodeObject:dictionary forKey:self.storeDataArchiveKey];
    [archiver finishEncoding];
    NSData *dictionaryData = archiver.encodedData;

    NSData *encryptedData = dictionaryData;
    if (storeKey != nil) {
        encryptedData = [storeKey encryptData:dictionaryData];
    }
    
    return encryptedData;
}

- (NSDictionary *)decryptDictionaryData:(NSData *)dictionaryData withKey:(SFKeyStoreKey *)storeKey
{
    
    NSData *decryptedDictionaryData = dictionaryData;
    if (storeKey != nil) {
        decryptedDictionaryData = [storeKey decryptData:dictionaryData];
    }
    if (decryptedDictionaryData == nil)
        return nil;
    
    NSDictionary *keyStoreDict = nil;
    NSError* error = nil;
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:decryptedDictionaryData error:&error];
    unarchiver.requiresSecureCoding = NO;
    if (error) {
        [SFSDKCoreLogger e:[self class] format:@"Unable to init unarchiver for key store data. Key store is invalid: %@.", error];
    } else {
        keyStoreDict = [unarchiver decodeObjectForKey:self.storeDataArchiveKey];
        [unarchiver finishDecoding];
    }
    
    return keyStoreDict;
}

#pragma mark - Utils

- (NSString *)buildUniqueKeychainId:(NSString *)baseKeychainId
{
    NSString *baseAppId = [SFCrypto baseAppIdentifier];
    return [NSString stringWithFormat:@"%@_%@", baseKeychainId, baseAppId];
}

#pragma mark - Abstract properties and methods

- (NSString *)storeKeychainIdentifier
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString *)storeDataArchiveKey
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString *)encryptionKeyKeychainIdentifier
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString *)encryptionKeyDataArchiveKey
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (SFKeyStoreKey *)keyStoreKey
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)setKeyStoreKey:(SFKeyStoreKey *)keyStoreKey
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (BOOL)keyStoreAvailable
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (BOOL)keyStoreEnabled
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString *)keyLabelForString:(NSString *)baseKeyLabel
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
