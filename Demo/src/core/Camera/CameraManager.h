//
//  CameraManager.h
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

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import "GLSLShader.h"


#define YUV_CAMERA 0
#define METADATA   0
#define FRAMERATE  60


#define Camera     CameraManager.sharedInstance



@protocol CameraManagerDelegate <NSObject>

- (void)processImageBuffer:(CVImageBufferRef)frame;

@end


@interface CameraManager:NSObject {
    
    AVCaptureSession *_session;
    AVCaptureConnection *_videoConnection;
    AVCaptureVideoDataOutput *_videoOutput;
    
    /**
     * Reference to the previously captured and cached texture. Released whenever a new frame is
     * captured by the camera.
     */
    CVOpenGLESTextureRef _cvTexture0;
    CVOpenGLESTextureRef _cvTexture1;
    
    /**
     * Automatically takes care of creating enough textures for cached textures of the captured
     * camera images.
     */
    CVOpenGLESTextureCacheRef _cvTextureCache;
    
    dispatch_queue_t _serialMetadataQueue;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _texCoordsBuffer;
}

@property (nonatomic) dispatch_queue_t serialSessionQueue;

@property (assign, nonatomic) BOOL initialized;
@property (assign, nonatomic) GLKMatrix4 projection;
@property (nonatomic, strong) GLSLShader *videoShader;
@property (nonatomic, strong) AVCaptureDevice *camera;

@property (nonatomic, assign) CVOpenGLESTextureRef cvTexture0;
@property (nonatomic, weak) id<CameraManagerDelegate> delegate;

+ (CameraManager *)sharedInstance;

- (CGSize)frameSize;

- (void)setupAVCaptureWithCamera:(AVCaptureDevicePosition)position;
- (void)stopAVCapture;
- (IBAction)swapCamera:(id)sender;

@end
