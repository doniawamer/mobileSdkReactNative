/*
 Copyright (c) 2015-present, salesforce.com, inc. All rights reserved.
 
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
#import <MobileSync/SFSyncTarget.h>

extern NSString * _Nonnull const kSFSyncUpTargetCreateFieldlist;
extern NSString * _Nonnull const kSFSyncUpTargetUpdateFieldlist;
extern NSString * _Nonnull const kSFSyncUpTargetExternalIdFieldName;

NS_ASSUME_NONNULL_BEGIN

@class SFMobileSyncSyncManager;

/**
 Enumeration of types of server targets.
 */
typedef NS_ENUM(NSUInteger, SFSyncUpTargetType) {
    /**
     The default server target, which uses standard REST requests to post updates.
     */
    SFSyncUpTargetTypeRestStandard NS_SWIFT_NAME(standard),
    
    /**
     Server target is a custom target, that manages its own server update logic.
     */
    SFSyncUpTargetTypeCustom NS_SWIFT_NAME(custom),
    
} NS_SWIFT_NAME(SyncUpTarget.TargetType);

/**
 Enumeration of the types of actions that can be executed against the server target.
 */
typedef NS_ENUM(NSUInteger, SFSyncUpTargetAction) {
    /**
     No action should be taken against the server.
     */
    SFSyncUpTargetActionNone,
    
    /**
     Created data will be posted to the server.
     */
    SFSyncUpTargetActionCreate,
    
    /**
     Updated data will be posted to the server.
     */
    SFSyncUpTargetActionUpdate,
    
    /**
     Data will be deleted from the server.
     */
    SFSyncUpTargetActionDelete
} NS_SWIFT_NAME(SyncUpTarget.Action);

/**
 Block definition for returning whether a record changed on server.
 */
typedef void (^SFSyncUpRecordNewerThanServerBlock)(BOOL isNewerThanServer) NS_SWIFT_NAME(RecordNewerThanServerBlock);

/**
 Block definition for returning whether records changed on server.
 */
typedef void (^SFSyncUpRecordsNewerThanServerBlock)(NSDictionary* areNewerThanServer) NS_SWIFT_NAME(RecordsNewerThanServerBlock);

/**
 Block definition for calling a sync up completion block.
 */
typedef void (^SFSyncUpTargetCompleteBlock)(NSDictionary * _Nullable syncUpResult) NS_SWIFT_NAME(SyncUpcompletionBlock);

/**
 Block definition for calling a sync up failure block.
 */
typedef void (^SFSyncUpTargetErrorBlock)(NSError *error) NS_SWIFT_NAME(SyncUpErrorBlock);

/**
 Helper class for isNewerThanServer
 */
NS_SWIFT_NAME(RecordModDate)
@interface SFRecordModDate : NSObject

@property (nonatomic, strong) NSDate*  timestamp;   // time stamp - can be nil if unknown
@property (nonatomic, assign) BOOL isDeleted;       // YES if record was deleted

- (instancetype)initWithTimestamp:(nullable NSString*)timestamp isDeleted:(BOOL)isDeleted;
@end

/**
 Base class for a server target, used to manage sync ups to the configured service.
 */
NS_SWIFT_NAME(SyncUpTarget)
@interface SFSyncUpTarget : SFSyncTarget

/**
 The type of server target represented by this instance.
 */
@property (nonatomic, assign) SFSyncUpTargetType targetType;


/**
 Create field list (optional)
 */
@property (nonatomic, strong, readonly) NSArray<NSString*>*  createFieldlist;

/**
 Update field list (optional)
 */
@property (nonatomic, strong, readonly) NSArray<NSString*>*  updateFieldlist;

/**
 External id field name (optional)
 */
@property (nonatomic, copy) NSString *externalIdFieldName;

/**
 Creates a new instance of a server target from a serialized dictionary.
 @param dict The dictionary with the serialized server target.
 */
+ (nullable instancetype)newFromDict:(nullable NSDictionary *)dict NS_SWIFT_NAME(build(dict:));

/**
 Converts a string representation of a target type into its target type.
 @param targetType The string representation of the target type.
 @return The target type value.
 */
+ (SFSyncUpTargetType)targetTypeFromString:(NSString*)targetType;

/**
 Gives the string representation of a target type.
 @param targetType The target type to display.
 @return The string representation of the target type.
 */
+ (NSString *)targetTypeToString:(SFSyncUpTargetType)targetType;

/**
 * Constructor
 */
- (instancetype)initWithCreateFieldlist:(nullable NSArray<NSString*> *)createFieldlist
                        updateFieldlist:(nullable NSArray<NSString*> *)updateFieldlist;

/**
 Call resultBlock with YES if record is more recent than corresponding record on server
 NB: also call resultBlock true if both were deleted or if local mod date is missing
 Used to decide whether a record should be synced up or not when using merge mode leave-if-changed
 @param record The record
 @param resultBlock The block to execute
 */
- (void)isNewerThanServer:(SFMobileSyncSyncManager *)syncManager
                   record:(NSDictionary*)record
             resultBlock:(SFSyncUpRecordNewerThanServerBlock)resultBlock;


/**
 Return true if local mod date is greater than remote mod date
 NB: also return true if both were deleted or if local mod date is missing
*/
- (BOOL)isNewerThanServer:(nullable SFRecordModDate*)localModDate
            remoteModDate:(nullable SFRecordModDate*)remoteModDate;


/**
Same as isNewerThanServer but operating over a list of records
Return dictionary from record store id to boolean
 @param records The records
 @param resultBlock The block to execute
*/
 - (void)areNewerThanServer:(SFMobileSyncSyncManager *)syncManager
                   records:(NSArray<NSDictionary*>*)records
                resultBlock:(SFSyncUpRecordsNewerThanServerBlock)resultBlock;

/**
 Save locally created record back to server
 @param syncManager The sync manager doing the sync
 @param record The record being synced
 @param fieldlist List of fields to send to server
 @param completionBlock The block to execute after the server call completes.
 @param failBlock The block to execute if the server call fails.
 */
- (void)createOnServer:(SFMobileSyncSyncManager *)syncManager
                record:(NSDictionary*)record
             fieldlist:(NSArray*)fieldlist
       completionBlock:(SFSyncUpTargetCompleteBlock)completionBlock
             failBlock:(SFSyncUpTargetErrorBlock)failBlock NS_SWIFT_NAME(createOnServer(syncManager:record:fieldlist:onComplete:onFail:));

/**
 Save locally updated record back to server
 @param syncManager The sync manager doing the sync
 @param record The record being synced
 @param fieldlist List of fields to send to server
 @param completionBlock The block to execute after the server call completes.
 @param failBlock The block to execute if the server call fails.
 */
- (void)updateOnServer:(SFMobileSyncSyncManager *)syncManager
                record:(NSDictionary*)record
             fieldlist:(NSArray*)fieldlist
       completionBlock:(SFSyncUpTargetCompleteBlock)completionBlock
             failBlock:(SFSyncUpTargetErrorBlock)failBlock NS_SWIFT_NAME(updateOnServer(syncManager:record:fieldlist:onComplete:onFail:));

/**
 Delete locally deleted record from server
 @param syncManager The sync manager doing the sync
 @param record The record being synced
 @param completionBlock The block to execute after the server call completes.
 @param failBlock The block to execute if the server call fails.
 */
- (void)deleteOnServer:(SFMobileSyncSyncManager *)syncManager
                record:(NSDictionary*)record
       completionBlock:(SFSyncUpTargetCompleteBlock)completionBlock
             failBlock:(SFSyncUpTargetErrorBlock)failBlock NS_SWIFT_NAME(deleteOnServer(syncManager:record:onComplete:onFail:));


/**
 Return set of record ids (soup element ids) that need to be sent up to the server
 @param syncManager The sync manager running the sync.
 @param soupName The soup name to look into for records.
 */
- (NSArray *)getIdsOfRecordsToSyncUp:(SFMobileSyncSyncManager *)syncManager
                            soupName:(NSString *)soupName;
/**
 Save record with last error if any
 @param syncManager The sync manager doing the sync
 @param soupName the soup to save the record to
 @param record The record being synced
 */
- (void) saveRecordToLocalStoreWithLastError:(SFMobileSyncSyncManager*)syncManager
                                    soupName:(NSString*) soupName
                                      record:(NSDictionary*) record NS_SWIFT_NAME(saveRecordToLocalStoreWithLastError(syncManager:soupName:record:));

@end

NS_ASSUME_NONNULL_END
