#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NSUserDefaults+SFAdditions.h"
#import "SFDefaultLogger.h"
#import "SFFileProtectionHelper.h"
#import "SFJsonUtils.h"
#import "SFLogger.h"
#import "SFPathUtil.h"
#import "SFSDKDatasharingHelper.h"
#import "SFSDKReachability.h"
#import "SFSDKSafeMutableArray.h"
#import "SFSDKSafeMutableDictionary.h"
#import "SFSDKSafeMutableSet.h"
#import "SFSwiftDetectUtil.h"
#import "SFTestContext.h"
#import "SalesforceSDKCommon.h"

FOUNDATION_EXPORT double SalesforceSDKCommonVersionNumber;
FOUNDATION_EXPORT const unsigned char SalesforceSDKCommonVersionString[];

