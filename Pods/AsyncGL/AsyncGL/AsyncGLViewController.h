//
//  Copyright (c) Levin Li. All rights reserved.
//  Licensed under the MIT License.
//

#import <TargetConditionals.h>

#if TARGET_OS_IOS
@import UIKit;
#else
@import Cocoa;
#endif

@class AsyncGLView;

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_IOS
@interface AsyncGLViewController : UIViewController
#else
@interface AsyncGLViewController : NSViewController
#endif

@property (nonatomic) BOOL pauseOnWillResignActive;
@property (nonatomic) BOOL resumeOnDidBecomeActive;
@property (nonatomic, getter=isPaused) BOOL paused;
@property (nonatomic, nullable) AsyncGLView *glView;

- (instancetype)initWithMSAAEnabled:(BOOL)msaaEnabled;

- (void)prepareGL:(CGSize)size;
- (void)drawGL:(CGSize)size;
- (void)clearGL;
- (void)makeRenderContextCurrent;

#if TARGET_OS_IOS
- (void)setPreferredFramesPerSecond:(NSInteger)preferredFramesPerSecond API_AVAILABLE(ios(10.0), tvos(10.0));
- (void)setScreen:(UIScreen *)screen;
#endif

@end

NS_ASSUME_NONNULL_END
