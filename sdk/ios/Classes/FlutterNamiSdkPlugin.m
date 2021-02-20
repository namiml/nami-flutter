#import "FlutterNamiSdkPlugin.h"
#if __has_include(<nami_flutter/nami_flutter-Swift.h>)
#import <nami_flutter/nami_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "nami_flutter-Swift.h"
#endif

@implementation FlutterNamiSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterNamiSdkPlugin registerWithRegistrar:registrar];
}
@end
