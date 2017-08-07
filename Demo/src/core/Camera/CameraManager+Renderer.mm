//
//  CameraManager+Renderer.m
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

#import "CameraManager+Renderer.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "YUVShader.h"


static float _CameraVertices[ 18 ];
static float _CameraTexCoords[ 12 ];



@implementation CameraManager (Renderer)


- (void)tearDown
{
    if ( _cvTexture0 )
    {
        CFRelease( _cvTexture0 );
        _cvTexture0 = NULL;
    }
    
    if ( _cvTexture1 )
    {
        CFRelease( _cvTexture1 );
        _cvTexture1 = NULL;
    }
    
    if ( _cvTextureCache )
    {
        CFRelease( _cvTextureCache );
        _cvTextureCache = NULL;
    }
    
    glDeleteBuffers( 1, &_vertexBuffer );
    glDeleteBuffers( 1, &_texCoordsBuffer );
    
    self.initialized = NO;
}


- (void)initialize:(int)cameraFrameWidth cameraFrameHeight:(int)cameraFrameHeight
{
    EAGLContext *eaglContext = [EAGLContext currentContext];
    CVReturn err = CVOpenGLESTextureCacheCreate( kCFAllocatorDefault, NULL, eaglContext, NULL, &_cvTextureCache );
    if ( err != kCVReturnSuccess )
    {
        NSLog( @"Failed to create Core Video texture cache" );
        return;
    }

#if defined YUV_CAMERA && YUV_CAMERA > 0
    self.videoShader = [YUVShader new];
    [self.videoShader set];
    [(YUVShader *)self.videoShader setYUniform:0];
    [(YUVShader *)self.videoShader setUVUniform:1];
#else
    self.videoShader = [GLSLShader new];
#endif
    
    float vertices[] = {
        0.0f,                    (float)cameraFrameHeight,                    0.0f,
        (float)cameraFrameWidth, (float)cameraFrameHeight,                    0.0f,
        0.0f,                    0.0f,                                        0.0f,
        (float)cameraFrameWidth, 0.0f,                                        0.0f,
        0.0f,                    0.0f,                                        0.0f,
        (float)cameraFrameWidth, (float)cameraFrameHeight,                    0.0f
    };
    memcpy( _CameraVertices, vertices, sizeof(vertices));
    
    float texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f, 1.0f
    };
    memcpy( _CameraTexCoords, texCoords, sizeof(texCoords));
    
    glGenBuffers( 1, &_vertexBuffer );
    glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer );
    glBufferData( GL_ARRAY_BUFFER, sizeof( _CameraVertices ), (GLvoid *)_CameraVertices, GL_STATIC_DRAW );
    
    glGenBuffers( 1, &_texCoordsBuffer );
    glBindBuffer( GL_ARRAY_BUFFER, _texCoordsBuffer );
    glBufferData( GL_ARRAY_BUFFER, sizeof(_CameraTexCoords), (GLvoid *)_CameraTexCoords, GL_STATIC_DRAW );
    
    self.initialized = YES;
}


- (void)updateFrame:(CVImageBufferRef)imgBuffer
{
    GLsizei frameWidth = (GLsizei)CVPixelBufferGetWidth( imgBuffer );
    GLsizei frameHeight = (GLsizei)CVPixelBufferGetHeight( imgBuffer );
    
    if ( !self.initialized )
    {
        [self initialize:frameWidth cameraFrameHeight:frameHeight];
    }
    
    if ( !_cvTextureCache )
    {
        NSLog( @"Core Video texture cache not created, cannot upload texture" );
        return;
    }
    
    // A new frame was captured, so release the previously cached texture since we won't use it
    // anymore
    if ( _cvTexture0 )
    {
        CFRelease( _cvTexture0 );
        _cvTexture0 = NULL;
    }
    
    // And instruct the cache to clean it up
    CVOpenGLESTextureCacheFlush( _cvTextureCache, 0 );
    
    CVReturn err;
    CVOpenGLESTextureRef texture0 = NULL;
    
#if defined YUV_CAMERA && YUV_CAMERA > 0
    if ( _cvTexture1 )
    {
        CFRelease( _cvTexture1 );
        _cvTexture1 = NULL;
    }
    CVOpenGLESTextureRef texture1 = NULL;
    
    // Y-plane
    glActiveTexture( GL_TEXTURE0 );
    err = CVOpenGLESTextureCacheCreateTextureFromImage( kCFAllocatorDefault,
                                                       _cvTextureCache,
                                                       imgBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RED_EXT,
                                                       frameWidth,
                                                       frameHeight,
                                                       GL_RED_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &texture0 );
    if ( err )
    {
        NSLog( @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err );
    }
    
    // UV-plane
    glActiveTexture( GL_TEXTURE1 );
    err = CVOpenGLESTextureCacheCreateTextureFromImage( kCFAllocatorDefault,
                                                       _cvTextureCache,
                                                       imgBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RG_EXT,
                                                       frameWidth / 2,
                                                       frameHeight / 2,
                                                       GL_RG_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       1,
                                                       &texture1 );
    if ( err )
    {
        NSLog( @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err );
    }
    
    _cvTexture1 = texture1;
#else
    
    glActiveTexture( GL_TEXTURE0 );
    err = CVOpenGLESTextureCacheCreateTextureFromImage( kCFAllocatorDefault,
                                                       _cvTextureCache,
                                                       imgBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       frameWidth,
                                                       frameHeight,
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &texture0 );
    if ( err )
    {
        NSLog( @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err );
    }
    
    
#endif /* if defined YUV_CAMERA && YUV_CAMERA > 0 */
    self.cvTexture0 = texture0;
}


/**
 * Renders the current camera image
 */
- (void)render
{
    if ( !self.initialized )
    {
        return;
    }
    
    [self.videoShader use];
    [self.videoShader setModelViewProjection:self.projection.m];
    
    glActiveTexture( GL_TEXTURE0 );
    glBindTexture( CVOpenGLESTextureGetTarget( self.cvTexture0 ), CVOpenGLESTextureGetName( self.cvTexture0 ) );
        
    
    GLenum target = CVOpenGLESTextureGetTarget( self.cvTexture0 );
    glBindTexture( target, CVOpenGLESTextureGetName( self.cvTexture0 ) );
    glTexParameteri( target, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( target, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    
    
#if defined YUV_CAMERA && YUV_CAMERA > 0
    glActiveTexture( GL_TEXTURE1 );
    glBindTexture( CVOpenGLESTextureGetTarget( _cvTexture1 ), CVOpenGLESTextureGetName( _cvTexture1 ) );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
#endif
    
    glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer );
    glEnableVertexAttribArray( GLKVertexAttribPosition );
    glVertexAttribPointer( GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (const GLvoid *)0 );
    glBindBuffer( GL_ARRAY_BUFFER, _texCoordsBuffer );
    glEnableVertexAttribArray( GLKVertexAttribTexCoord0 );
    glVertexAttribPointer( GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof( float ), (const GLvoid *)0 );
    
    glDrawArrays( GL_TRIANGLES, 0, 6 );
    
#if DEBUG
    GLint err = glGetError();
    if ( err != GL_NO_ERROR )
    {
        NSLog( @"GLError: 0x%x", err );
    }
#endif
    
    [self.videoShader unuse];
}


@end
