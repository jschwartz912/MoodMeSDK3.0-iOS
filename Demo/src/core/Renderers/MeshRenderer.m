//
//  SkinRenderer.m
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

#import "MeshRenderer.h"
#import <MoodMeSDK/SDK.h>

#import <OpenGLES/ES2/glext.h>
#import "PointShader.h"


static float greenColor[] = { 0.0, 1.0, 0.0, 1.0 };
static float yellowColor[] = { 1.0, 1.0, 0.0, 1.0 };


unsigned short _skinIndices[] = {
    20, 21,  23,
    21, 22,  23,
    0,  1,   36,
    15, 16,  45,
    36, 17,  0,
    16, 26,  45,
    37, 18,  17,
    44, 26,  25,
    17, 36,  37,
    26, 44,  45,
    38, 19,  18,
    43, 25,  24,
    18, 37,  38,
    25, 43,  44,
    20, 19,  38,
    43, 24,  23,
    39, 21,  20,
    42, 23,  22,
    20, 38,  39,
    23, 42,  43,
    27, 22,  21,
    27, 21,  39,
    27, 42,  22,
    27, 28,  42,
    28, 27,  39,
    28, 47,  42,
    28, 39,  40,
    1,  41,  36,
    15, 45,  46,
    1,  2,   41,
    14, 15,  46,
    29, 28,  40,
    28, 29,  47,
    2,  40,  41,
    14, 46,  47,
    2,  29,  40,
    29, 14,  47,
    2,  3,   29,
    13, 14,  29,
    31, 30,  29,
    29, 30,  35,
    3,  31,  29,
    13, 29,  35,
    30, 32,  33,
    30, 33,  34,
    30, 31,  32,
    30, 34,  35,
    3,  4,   31,
    12, 13,  35,
    4,  5,   48,
    11, 12,  54,
    5,  6,   48,
    10, 11,  54,
    6,  59,  48,
    10, 54,  55,
    6,  7,   59,
    9,  10,  55,
    7,  58,  59,
    9,  55,  56,
    8,  57,  58,
    8,  56,  57,
    7,  8,   58,
    8,  9,   56,
    4,  48,  31,
    12, 35,  54,
    31, 48,  49,
    35, 53,  54,
    31, 49,  50,
    35, 52,  53,
    50, 32,  31,
    52, 35,  34,
    50, 33,  32,
    52, 34,  33,
    33, 50,  51,
    33, 51,  52,
    48, 60,  49,
    49, 60,  50,
    50, 60,  61,
    50, 61,  51,
    51, 61,  52,
    61, 62,  52,
    62, 53,  52,
    62, 54,  53,
    55, 54,  63,
    56, 55,  63,
    56, 63,  64,
    64, 57,  56,
    64, 65,  57,
    58, 57,  65,
    58, 65,  59,
    65, 48,  59
};




@interface MeshRenderer () {

    GLuint _vertexBuffer;
    GLuint _indexBuffer;

    GLKMatrix4 _modelView;
    GLKMatrix4 _projection;

    PointShader *_pointShader;
}

@end


@implementation MeshRenderer


- (instancetype)init
{
    self = [super init];
    if ( self )
    {
        [self setupGL];
    }
    return self;
}


- (void)dealloc
{
    glDeleteBuffers( 1, &_vertexBuffer );
    glDeleteBuffers( 1, &_indexBuffer );
}


- (void)setupGL
{
    _pointShader = [PointShader new];

    glGenBuffers( 1, &_vertexBuffer );
    glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer );
    glBufferData( GL_ARRAY_BUFFER, DM.verticesNumber * DM.verticesStride, (GLvoid *)DM.vertices, GL_DYNAMIC_DRAW );

    glGenBuffers( 1, &_indexBuffer );
    glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indexBuffer );
    glBufferData( GL_ELEMENT_ARRAY_BUFFER, sizeof( _skinIndices ), (GLvoid *)_skinIndices, GL_STATIC_DRAW );
}


- (void)setProjection:(GLKMatrix4)projection
{
    _projection = projection;
}


- (void)update
{
    if ( DM.faceTracked )
    {
        _modelView = DM.modelView;
        glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer );
        glBufferData( GL_ARRAY_BUFFER, DM.verticesNumber * DM.verticesStride, (GLvoid *)DM.vertices, GL_DYNAMIC_DRAW );
    }
}


- (void)render
{
    if ( DM.faceTracked )
    {
        GLKMatrix4 mvp = GLKMatrix4Multiply( _projection, _modelView );
        [_pointShader use];
        [_pointShader setModelViewProjection:mvp.m];
        [_pointShader setPointColor:greenColor];
        [_pointShader setPointSize:6.];

        glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer );
        glEnableVertexAttribArray( GLKVertexAttribPosition );
        glVertexAttribPointer( GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, DM.verticesStride, (const GLvoid *)0 );
        glDrawArrays( GL_POINTS, 0, DM.verticesNumber );

        [_pointShader setPointColor:yellowColor];
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, _indexBuffer );
        for ( int i = 0; i < DM.indicesNumber / 3; i++ )
        {
            glDrawElements( GL_LINE_STRIP, 3, GL_UNSIGNED_SHORT, (void *)(i * 3 * sizeof( unsigned short )) );
        }

        [_pointShader unuse];
    }
}


@end
