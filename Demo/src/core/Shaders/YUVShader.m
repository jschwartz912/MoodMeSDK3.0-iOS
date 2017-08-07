//
//  YUVShader.m
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

#import "YUVShader.h"


#define kSamplerYUniform   "SamplerY"
#define kSamplerUVUniform  "SamplerUV"


#define kDefaultShaderFragment @"uniform sampler2D SamplerY; \
uniform sampler2D SamplerUV; \
varying highp vec2 texCoordsVarying; \
void main() \
{ \
mediump vec3 yuv; \
lowp vec3 rgb; \
yuv.x = texture2D(SamplerY, texCoordsVarying).r; \
yuv.yz = texture2D(SamplerUV, texCoordsVarying).rg - vec2(0.5, 0.5); \
rgb = mat3(      1,       1,      1, \
0, -.18732, 1.8556, \
1.57481, -.46813,      0) * yuv; \
gl_FragColor = vec4(rgb, 1); \
}"

@interface YUVShader () {
    
    GLint yUniform;
    GLint uvUniform;
}

@end


@implementation YUVShader


- (instancetype)init
{
    self = [super initWithFragment:kDefaultShaderFragment];
    if (self) {
        
        yUniform =  glGetUniformLocation( self.program, kSamplerYUniform );
        uvUniform = glGetUniformLocation( self.program, kSamplerUVUniform );
        
    }
    return self;
}


- (void)setYUniform:(int)value
{
    glUniform1i( yUniform, value );
}

- (void)setUVUniform:(int)value
{
    glUniform1i( uvUniform, value );
}


@end
