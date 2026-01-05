#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "github-logo" asset catalog image resource.
static NSString * const ACImageNameGithubLogo AC_SWIFT_PRIVATE = @"github-logo";

#undef AC_SWIFT_PRIVATE
