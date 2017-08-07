//
//  PointShader.m
//  MoodMe
//
// Copyright (c) 2015 MoodMe (http://www.mood-me.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PointShader.h"


#define POINT_VERTEX   @" \
uniform mat4 modelViewProjectionMatrix; \
attribute vec2 texCoords; \
attribute vec4 position; \
uniform	float pointSize; \
void main (void) \
{ \
lowp vec2 tex = texCoords; \
gl_Position	= modelViewProjectionMatrix * position; \
gl_PointSize = pointSize; \
}"


#define POINT_FRAGMENT @" \
uniform	lowp vec4 pointColor; \
void main (void) \
{ \
gl_FragColor = pointColor; \
}"


@interface PointShader () {

    GLint _pointColorUniform;
    GLint _pointSizeUniform;
}

@end


@implementation PointShader


- (instancetype)init
{
    self = [super initWithVertexShader:POINT_VERTEX andFragmentShader:POINT_FRAGMENT];
    if ( self )
    {
        [self use];
        _pointColorUniform = glGetUniformLocation( self.program, "pointColor" );
        _pointSizeUniform  = glGetUniformLocation( self.program, "pointSize" );
        [self unuse];
    }
    return self;
}


- (void)setPointColor:(float[4])pointColor
{
    glUniform4f( _pointColorUniform, pointColor[0], pointColor[1], pointColor[2], pointColor[3] );
}


- (void)setPointSize:(float)pointSize
{
    glUniform1f( _pointSizeUniform, pointSize );
}


@end
