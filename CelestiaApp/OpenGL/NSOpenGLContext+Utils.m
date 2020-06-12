//
// NSOpenGLContext+Utils.m
//
// Copyright © 2020 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

#import "NSOpenGLContext+Utils.h"
#import <OpenGL/gl.h>

@implementation NSOpenGLContext (Utils)

- (void)enable:(GLenum)value {
    glEnable(value);
}

- (void)disable:(GLenum)value {
    glDisable(value);
}

@end
