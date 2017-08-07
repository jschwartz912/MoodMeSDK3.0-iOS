//
//  SilhouetteRenderer.m
//  Demo
//
//  Created by Leonid Mesentsev on 07/12/15.
//  Copyright © 2015 Leo Mesentsev. All rights reserved.
//

#import "SilhouetteRenderer.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>



typedef struct
{
    GLKVector3 positionCoords;
    GLKVector2 textureCoords;
}
SceneVertex;



@interface SilhouetteRenderer () {

    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _texCoordsBuffer;

    GLKBaseEffect *_baseEffect;
    GLKTextureInfo *_texture;

    SceneVertex _gVertexData[4];
}

@end


@implementation SilhouetteRenderer


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
    [self tearDown];
}


- (void)setupGL
{
    _baseEffect = [GLKBaseEffect new];
    _baseEffect.useConstantColor = GL_TRUE;
    _baseEffect.constantColor = GLKVector4Make( 1.0f, 1.0f, 1.0f, 1.0f );

    _gVertexData[ 0 ].positionCoords.x = -1.0f;
    _gVertexData[ 0 ].positionCoords.y = -1.0f;
    _gVertexData[ 0 ].textureCoords.x  = 0.0f;
    _gVertexData[ 0 ].textureCoords.y  = 0.0f;

    _gVertexData[ 1 ].positionCoords.x = 1.0f;
    _gVertexData[ 1 ].positionCoords.y = -1.0f;
    _gVertexData[ 1 ].textureCoords.x  = 1.0f;
    _gVertexData[ 1 ].textureCoords.y  = 0.0f;

    _gVertexData[ 2 ].positionCoords.x = -1.0f;
    _gVertexData[ 2 ].positionCoords.y = 1.0f;
    _gVertexData[ 2 ].textureCoords.x  = 0.0f;
    _gVertexData[ 2 ].textureCoords.y  = 1.0f;

    _gVertexData[ 3 ].positionCoords.x = 1.0f;
    _gVertexData[ 3 ].positionCoords.y = 1.0f;
    _gVertexData[ 3 ].textureCoords.x  = 1.0f;
    _gVertexData[ 3 ].textureCoords.y  = 1.0f;

    glGenVertexArraysOES( 1, &_vertexArray );
    glBindVertexArrayOES( _vertexArray );

    glGenBuffers( 1, &_vertexBuffer );
    glBindBuffer( GL_ARRAY_BUFFER, _vertexBuffer );
    glBufferData( GL_ARRAY_BUFFER, sizeof( _gVertexData ), _gVertexData, GL_STATIC_DRAW );
    glEnableVertexAttribArray( GLKVertexAttribPosition );
    glVertexAttribPointer( GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, sizeof( SceneVertex ), NULL + offsetof( SceneVertex, positionCoords ));

    glGenBuffers( 1, &_texCoordsBuffer );
    glBindBuffer( GL_ARRAY_BUFFER, _texCoordsBuffer );
    glBufferData( GL_ARRAY_BUFFER, sizeof( _gVertexData ), _gVertexData, GL_STATIC_DRAW );
    glEnableVertexAttribArray( GLKVertexAttribTexCoord0 );
    glVertexAttribPointer( GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof( SceneVertex ), NULL + offsetof( SceneVertex, textureCoords ));

    glBindVertexArrayOES( 0 );

    NSError *error;
    UIImage *img = [UIImage imageNamed:@"silhouette"];
    _texture = [GLKTextureLoader textureWithCGImage:img.CGImage options:@{ GLKTextureLoaderOriginBottomLeft : @NO } error:&error];
    NSAssert( _texture, @"Error loading texture: %@", [error localizedDescription] );
    _baseEffect.texture2d0.name = _texture.name;
    _baseEffect.texture2d0.target = _texture.target;
}


- (void)setProjection:(GLKMatrix4)projection
{
    _baseEffect.transform.projectionMatrix = projection;
}


- (void)tearDown
{
    glDeleteBuffers( 1, &_texCoordsBuffer );
    glDeleteBuffers( 1, &_vertexBuffer );
    glDeleteVertexArraysOES( 1, &_vertexArray );
}


- (void)render
{
    glBindVertexArrayOES( _vertexArray );

    [_baseEffect prepareToDraw];

    glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );
#if DEBUG
    GLint err = glGetError();
    if ( err != GL_NO_ERROR )
    {
        NSLog( @"GLError: 0x%x", err );
    }
#endif
    glBindVertexArrayOES( 0 );
}


@end
