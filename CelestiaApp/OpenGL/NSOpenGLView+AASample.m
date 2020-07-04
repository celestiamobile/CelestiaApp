//
// NSOpenGLView+AASample.m
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "NSOpenGLView+AASample.h"
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/CGLTypes.h>

@implementation NSOpenGLView (AASample)

- (void)setAASamples:(GLint)aaSamples {
    if (aaSamples > 1)
    {
        const char *glRenderer = (const char *) glGetString(GL_RENDERER);

        if (strstr(glRenderer, "ATI"))
        {
            [[self openGLContext] setValues: &aaSamples
                               forParameter: 510];
        }
        else
        {
            NSOpenGLPixelFormat *pixFmt;
            NSOpenGLContext *context;

            NSOpenGLPixelFormatAttribute fsaaAttrs[] =
            {
                NSOpenGLPFADoubleBuffer,
                NSOpenGLPFADepthSize,
                (NSOpenGLPixelFormatAttribute)32,
                NSOpenGLPFASampleBuffers,
                (NSOpenGLPixelFormatAttribute)1,
                NSOpenGLPFASamples,
                (NSOpenGLPixelFormatAttribute)1,
                0
            };

            fsaaAttrs[6] = aaSamples;

            pixFmt =
            [[NSOpenGLPixelFormat alloc] initWithAttributes: fsaaAttrs];

            if (pixFmt)
            {
                context = [[NSOpenGLContext alloc] initWithFormat: pixFmt
                                                     shareContext: nil];

                if (context)
                {
                    // The following silently fails if not supported
                    CGLEnable([context CGLContextObj], 313);

                    GLint swapInterval = 1;
                    [context setValues: &swapInterval
                          forParameter: NSOpenGLCPSwapInterval];
                    [self setOpenGLContext: context];
                    [context setView: self];
                    [context makeCurrentContext];

                    glEnable(GL_MULTISAMPLE_ARB);
                    // GL_NICEST enables Quincunx on supported NVIDIA cards,
                    // but smears text.
                    //                    glHint(GL_MULTISAMPLE_FILTER_HINT_NV, GL_NICEST);
                }
            }
        }
    }
}

@end
