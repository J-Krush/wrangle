#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "claude-logo" asset catalog image resource.
static NSString * const ACImageNameClaudeLogo AC_SWIFT_PRIVATE = @"claude-logo";

/// The "google-g-logo" asset catalog image resource.
static NSString * const ACImageNameGoogleGLogo AC_SWIFT_PRIVATE = @"google-g-logo";

#undef AC_SWIFT_PRIVATE
