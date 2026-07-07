//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<dotlottie_flutter/DotLottieFlutterPlugin.h>)
#import <dotlottie_flutter/DotLottieFlutterPlugin.h>
#else
@import dotlottie_flutter;
#endif

#if __has_include(<sqflite_darwin/SqflitePlugin.h>)
#import <sqflite_darwin/SqflitePlugin.h>
#else
@import sqflite_darwin;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [DotLottieFlutterPlugin registerWithRegistrar:[registry registrarForPlugin:@"DotLottieFlutterPlugin"]];
  [SqflitePlugin registerWithRegistrar:[registry registrarForPlugin:@"SqflitePlugin"]];
}

@end
