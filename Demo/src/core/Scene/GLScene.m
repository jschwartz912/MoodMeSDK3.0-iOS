//
//  FSMScene.m
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

#import "GLScene.h"
#import <AVFoundation/AVFoundation.h>

#import <MoodMeSDK/SDK.h>
#import "CameraManager+Renderer.h"
#import "SilhouetteRenderer.h"

#import "MeshRenderer.h"


@interface GLScene () {

    EAGLContext *_context;

    SilhouetteRenderer *_silhouette;
    MeshRenderer *_meshRenderer;

    GLKMatrix4 _projectionMatrix;
}

@end


@implementation GLScene


#pragma mark -
#pragma mark Lifecycle


- (instancetype)initWithView:(GLKView *)view
{
    self = [super init];
    if ( self )
    {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if ( !_context )
        {
            NSLog( @"Failed to create ES context" );
        }
        [self setupWithView:view];
        Camera.delegate = (id < CameraManagerDelegate >)DM;

        DM.useCLM2 = YES;
        DM.scale = .5;
        DM.delegate = (id<UpdatableScene>)self;

        _silhouette = [SilhouetteRenderer new];
        _meshRenderer = [MeshRenderer new];
    }
    return self;
}


- (void)setupWithView:(GLKView *)view
{
    [EAGLContext setCurrentContext:_context];
    view.context = _context;

    float width  = Camera.frameSize.width;
    float height = Camera.frameSize.height;
    _projectionMatrix = GLKMatrix4MakeOrtho( 0, width, height, 0, 400, -400 );

    [Camera setProjection:_projectionMatrix];
    [_meshRenderer setProjection:_projectionMatrix];

    glEnable( GL_BLEND );
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
//    glEnable( GL_CULL_FACE );
//    glCullFace( GL_FRONT_AND_BACK );
}


- (void)dealloc
{
    [self tearDown];
}


#pragma mark -
#pragma mark Cleanup


- (void)tearDown
{
    [EAGLContext setCurrentContext:_context];
    [Camera stopAVCapture];
    [_silhouette tearDown];
    if ( [EAGLContext currentContext] == _context )
    {
        [EAGLContext setCurrentContext:nil];
    }
}


- (void)reset
{
    [DM reset];
}


#pragma mark -
#pragma mark Rendering


- (void)update
{
    [_meshRenderer update];
}


- (void)render
{
    [EAGLContext setCurrentContext:_context];
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    [Camera render];

    if ( DM.faceTracked )
    {
        [_meshRenderer render];
    }
    else
    {
        [_silhouette render];
    }
}


@end
