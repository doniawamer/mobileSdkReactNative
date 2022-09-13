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

#import "SFSDKAILTNTransform.h"
#import "SFSDKAnalyticsLogger.h"
#import "SFSDKAnalyticsManager.h"
#import "SFSDKDeviceAppAttributes.h"
#import "SFSDKEventStoreManager.h"
#import "SFSDKInstrumentationEvent.h"
#import "SFSDKInstrumentationEventBuilder.h"
#import "SFSDKTransform.h"
#import "SalesforceAnalytics.h"

FOUNDATION_EXPORT double SalesforceAnalyticsVersionNumber;
FOUNDATION_EXPORT const unsigned char SalesforceAnalyticsVersionString[];

