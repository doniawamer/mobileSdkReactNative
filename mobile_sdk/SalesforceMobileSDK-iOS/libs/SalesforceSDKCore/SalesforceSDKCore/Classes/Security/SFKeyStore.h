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

#import <Foundation/Foundation.h>
#import "SFKeyStoreKey.h"
#import <SalesforceSDKCore/SalesforceSDKConstants.h>

NS_ASSUME_NONNULL_BEGIN

/** For internal use. 
 */
@interface SFKeyStore : NSObject

/**
 The key store key, used for encrypting and decrypting the key store.
 */
@property (nonatomic, copy, nullable) SFKeyStoreKey *keyStoreKey;

/**
 The dictionary that holds the key store data.
 */
@property (nonatomic, strong, nullable) NSDictionary *keyStoreDictionary;

/**
 Whether or not the key store is currently available for exchanging keys.
 */
@property (nonatomic, readonly) BOOL keyStoreAvailable;

/**
 Whether or not the key store is enabled for use, i.e. whether or not this will be used at all for
 key storage and retrieval.
 */
@property (nonatomic, readonly) BOOL keyStoreEnabled;

/**
 Returns a key label unique to this key store, based on the input key label.
 @param baseKeyLabel the input key label to make unique.
 @return A unique key label to this store.
 */
- (NSString *)keyLabelForString:(NSString *)baseKeyLabel;

@end

NS_ASSUME_NONNULL_END
