//
//  GLSLShader.m
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

#import "GLSLShader.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <GLKit/GLKit.h>


#define kVertexAttribute       "position"
#define kTexCoordAttribute     "texCoords"
#define kMatrixUniform         "modelViewProjectionMatrix"
#define kAlphaUniform          "alpha"


#define kDefaultVertexShader   @"attribute vec4 position; \
attribute vec2 texCoords; \
varying lowp vec2 texCoordsVarying; \
uniform mat4 modelViewProjectionMatrix; \
uniform lowp float alpha; \
varying lowp float _alpha; \
void main() \
{ \
texCoordsVarying = texCoords; \
gl_Position = modelViewProjectionMatrix * position; \
_alpha = alpha; \
}"


#define kDefaultShaderFragment @"precision mediump float; \
varying highp vec2 texCoordsVarying; \
uniform sampler2D texture; \
varying lowp float _alpha; \
void main() \
{ \
vec4 color = texture2D(texture, texCoordsVarying); \
if ( color.a > _alpha && _alpha > .0 ) { \
color.a = _alpha; \
} \
gl_FragColor = color;\
}"




@interface GLSLShader () {

    GLuint _program;
    GLint _modelViewMatrixUniform, _alpha;
}


@end




@implementation GLSLShader


@synthesize program = _program;



- (instancetype)init
{
    self = [super init];
    if ( self )
    {
        [self loadWithFragment:kDefaultShaderFragment];
    }
    return self;
}


- (instancetype)initWithFragment:(NSString *)fragmentShader
{
    self = [super init];
    if ( self )
    {
        [self loadWithFragment:fragmentShader];
    }
    return self;
}


- (instancetype)initWithVertexShader:(NSString *)vertexShader andFragmentShader:(NSString *)fragmentShader
{
    self = [super init];
    if ( self )
    {
        [self loadWithVertex:vertexShader andFragment:fragmentShader];
    }
    return self;
}


- (void)dealloc
{
    if ( _program )
    {
        glDeleteProgram( _program );
        _program = 0;
    }
}


- (void)use
{
    glUseProgram( _program );
}


- (void)unuse
{
    glUseProgram( 0 );
}


- (void)setAlpha:(float)alpha
{
    glUniform1f( _alpha, alpha );
}


- (void)setModelViewProjection:(float[16])matrix
{
    glUniformMatrix4fv( _modelViewMatrixUniform, 1, 0, matrix );
}


#pragma mark -  OpenGL ES 2 shader compilation


- (BOOL)loadWithFragment:(NSString *)fragmentShader
{
    return [self loadWithVertex:kDefaultVertexShader andFragment:fragmentShader];
}


- (BOOL)loadWithVertex:(NSString *)vertexShader andFragment:(NSString *)fragmentShader
{
    GLuint vertShader, fragShader;

    // Create shader program.
    _program = glCreateProgram();

    // Create and compile vertex shader.
    if ( ![self compileShader:&vertShader type:GL_VERTEX_SHADER source:vertexShader] )
    {
        NSLog( @"Failed to compile vertex shader" );
        return NO;
    }

    // Create and compile fragment shader.
    if ( ![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:fragmentShader] )
    {
        NSLog( @"Failed to compile fragment shader" );
        return NO;
    }

    // Attach vertex shader to program.
    glAttachShader( _program, vertShader );

    // Attach fragment shader to program.
    glAttachShader( _program, fragShader );

    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation( _program, GLKVertexAttribPosition,  kVertexAttribute );
    glBindAttribLocation( _program, GLKVertexAttribTexCoord0, kTexCoordAttribute );

    // Link program.
    if ( ![self linkProgram:_program] )
    {
        NSLog( @"Failed to link program: %d", _program );

        if ( vertShader )
        {
            glDeleteShader( vertShader );
            vertShader = 0;
        }
        if ( fragShader )
        {
            glDeleteShader( fragShader );
            fragShader = 0;
        }
        if ( _program )
        {
            glDeleteProgram( _program );
            _program = 0;
        }

        return NO;
    }

    // Get uniform locations.
    _modelViewMatrixUniform = glGetUniformLocation( _program, kMatrixUniform );
    _alpha = glGetUniformLocation( _program, kAlphaUniform );

    // Release vertex and fragment shaders.
    if ( vertShader )
    {
        glDetachShader( _program, vertShader );
        glDeleteShader( vertShader );
    }
    if ( fragShader )
    {
        glDetachShader( _program, fragShader );
        glDeleteShader( fragShader );
    }

    return YES;

}


- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)sourceCode
{
    GLint status;
    const GLchar *source;

    source = (GLchar *)sourceCode.UTF8String;
    if ( !source )
    {
        NSLog( @"Failed to load vertex shader" );
        return NO;
    }

    *shader = glCreateShader( type );
    glShaderSource( *shader, 1, &source, NULL );
    glCompileShader( *shader );

#ifdef DEBUG
    GLint logLength;
    glGetShaderiv( *shader, GL_INFO_LOG_LENGTH, &logLength );
    if ( logLength > 0 )
    {
        GLchar *log = (GLchar *)malloc( logLength );
        glGetShaderInfoLog( *shader, logLength, &logLength, log );
        NSLog( @"Shader compile log:\n%s", log );
        free( log );
    }
#endif

    glGetShaderiv( *shader, GL_COMPILE_STATUS, &status );
    if ( status == 0 )
    {
        glDeleteShader( *shader );
        return NO;
    }

    return YES;
}


- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;

    glLinkProgram( prog );

#ifdef DEBUG
    GLint logLength;
    glGetProgramiv( prog, GL_INFO_LOG_LENGTH, &logLength );
    if ( logLength > 0 )
    {
        GLchar *log = (GLchar *)malloc( logLength );
        glGetProgramInfoLog( prog, logLength, &logLength, log );
        NSLog( @"Program link log:\n%s", log );
        free( log );
    }
#endif

    glGetProgramiv( prog, GL_LINK_STATUS, &status );
    if ( status == 0 )
    {
        return NO;
    }

    return YES;
}


- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;

    glValidateProgram( prog );
    glGetProgramiv( prog, GL_INFO_LOG_LENGTH, &logLength );
    if ( logLength > 0 )
    {
        GLchar *log = (GLchar *)malloc( logLength );
        glGetProgramInfoLog( prog, logLength, &logLength, log );
        NSLog( @"Program validate log:\n%s", log );
        free( log );
    }

    glGetProgramiv( prog, GL_VALIDATE_STATUS, &status );
    if ( status == 0 )
    {
        return NO;
    }

    return YES;
}


@end
