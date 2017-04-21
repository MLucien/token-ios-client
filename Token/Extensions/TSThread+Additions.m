#import "TSThread+Additions.h"
#import <objc/runtime.h>

@implementation TSThread (Additions)
@dynamic cachedContactIdentifier;
static char _internalPropertyKey;

- (NSArray<TSMessage *> *)messages {
    NSMutableArray *visible = [NSMutableArray array];

    for (TSInteraction *interaction in self.allInteractions) {
        if ([interaction isKindOfClass:[TSMessage class]]) {
            NSString *body = ((TSMessage *)interaction).body;
            // We use hard-coded strings here since the constants for them are declared inside a swift enum
            // hence inaccessible through Objective C. Since we only use it here, I left them as literals.g
            if ([body hasPrefix:@"SOFA::Message:"] || [body hasPrefix:@"SOFA::PaymentRequest:"]) {
                [visible addObject:interaction];
            }
        }
    }

    return visible;
}

- (void)setCachedContactIdentifier:(NSString *)value {
    objc_setAssociatedObject(self, &_internalPropertyKey, value, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)cachedContactIdentifier {
    NSString *identifier = (NSString* )objc_getAssociatedObject(self, &_internalPropertyKey);
    if (identifier == nil) {
        return [self name];
    }

    return identifier;
}

@end
