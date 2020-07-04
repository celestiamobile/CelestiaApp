//
// LocalizationSwizzling.m
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "LocalizationSwizzling.h"
#import <objc/runtime.h>
#import <objc/message.h>

// Modified from https://gist.github.com/steipete/1d308fad786399b58875cd12e4b9bba2

OBJC_EXPORT id objc_msgSendSuper2(struct objc_super *super, SEL op, ...);
OBJC_EXPORT void objc_msgSendSuper2_stret(struct objc_super *super, SEL op,...);

// http://defagos.github.io/yet_another_article_about_method_swizzling/ (Thank you!!)
// Returns the original implementation
static _Nullable IMP custom_swizzleSelector(Class clazz, SEL selector, IMP newImplementation) {
    NSCParameterAssert(clazz);
    NSCParameterAssert(selector);
    NSCParameterAssert(newImplementation);

    // If the method does not exist for this class, do nothing.
    const Method method = class_getInstanceMethod(clazz, selector);
    if (!method) {
        NSLog(@"%@ doesn't exist in %@.", NSStringFromSelector(selector), NSStringFromClass(clazz));
        // Cannot swizzle methods which are not implemented by the class or one of its parents.
        return NULL;
    }

    // Make sure the class implements the method. If this is not the case, inject an implementation, only calling 'super'.
    const char *types = method_getTypeEncoding(method);

    @synchronized(clazz) {
// class_addMethod will simply return NO if the method is already implemented.
#if !defined(__arm64__)
        // Sufficiently large struct
        typedef struct LargeStruct_ { char dummy[16]; } LargeStruct;

        NSUInteger retSize = 0;
        NSGetSizeAndAlignment(types, &retSize, NULL);

        // Large structs on 32-bit architectures
        // TODO: This is incorrect for some structs on some architectures. Needs to be hardcoded, this cannot be safely inferred at runtime.
        // https://twitter.com/gparker/status/1028564412339113984
        if (sizeof(void *) == 4 && types[0] == _C_STRUCT_B && retSize != 1 && retSize != 2 && retSize != 4 && retSize != 8) {
            class_addMethod(clazz, selector, imp_implementationWithBlock(^(__unsafe_unretained id self, va_list argp) {
                struct objc_super super = {self, clazz};
                return ((LargeStruct(*)(struct objc_super *, SEL, va_list))objc_msgSendSuper2_stret)(&super, selector, argp);
            }), types);
        }
        // All other cases
        else {
#endif
            class_addMethod(clazz, selector, imp_implementationWithBlock(^(__unsafe_unretained id self, va_list argp) {
                struct objc_super super = {self, clazz};
                return ((id(*)(struct objc_super *, SEL, va_list))objc_msgSendSuper2)(&super, selector, argp);
            }), types);
#if !defined(__arm64__)
        }
#endif
        // Swizzling
        return class_replaceMethod(clazz, selector, newImplementation, types);
    }
}

_Nullable IMP custom_swizzleSelectorWithBlock(Class clazz, SEL selector, id newImplementationBlock) {
    const IMP newImplementation = imp_implementationWithBlock(newImplementationBlock);
    return custom_swizzleSelector(clazz, selector, newImplementation);
}

void SwizzleLocalizableClass(Class cls)
{
    if (![cls instancesRespondToSelector:NSSelectorFromString(@"awakeFromNib")]) {
        NSLog(@"Trying to swizzle unsupported class %@.", NSStringFromClass(cls));
        return;
    }
    custom_swizzleSelectorWithBlock(cls, NSSelectorFromString(@"awakeFromNib"), ^(id<IBLocalizable> self) {
        [self localize];
    });
}
