//
//  NSOpenGLView+AASample.h
//  CelestiaApp
//
//  Created by 李林峰 on 2019/8/10.
//  Copyright © 2019 李林峰. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSOpenGLView (AASample)

- (void)setAASamples:(GLint)aaSamples;

@end

NS_ASSUME_NONNULL_END
