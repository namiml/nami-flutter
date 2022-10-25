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

#import "FlutterNamiSdkPlugin.h"

FOUNDATION_EXPORT double nami_flutterVersionNumber;
FOUNDATION_EXPORT const unsigned char nami_flutterVersionString[];

