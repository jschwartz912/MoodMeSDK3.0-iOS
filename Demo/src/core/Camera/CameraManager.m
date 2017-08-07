//
//  CameraManager.m
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


#import "CameraManager.h"
#import "CameraManager+Renderer.h"

#import <GLKit/GLKit.h>
#import <sys/utsname.h>


BOOL _highPerformanceDevice = YES;


@interface CameraManager () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate> {

    dispatch_group_t _group;

}
@end



@implementation CameraManager


#pragma mark - Singleton

+ (CameraManager *)sharedInstance
{
    static CameraManager *_sharedInstance;

    if ( !_sharedInstance )
    {
        _sharedInstance = [CameraManager new];
    }
    return _sharedInstance;
}


- (instancetype)init
{
    self = [super init];
    if ( self )
    {
        struct utsname systemInfo;

        uname( &systemInfo );
        NSLog( @"Device model: %s", systemInfo.machine );

        if ( !strncmp( systemInfo.machine, "iPhone", 6 ) )
        {
            int version = systemInfo.machine[ 6 ] - 48;
            if ( version <= 5 )
            {
                _highPerformanceDevice = NO;
            }
        }
        if ( !strncmp( systemInfo.machine, "iPad", 4 ) )
        {
            int version = systemInfo.machine[ 4 ] - 48;
            if ( version <= 2 )
            {
                _highPerformanceDevice = NO;
            }
        }

        _serialMetadataQueue = dispatch_queue_create( "com.nga.GLFace.serialMetadataQueue", DISPATCH_QUEUE_SERIAL );
        _serialSessionQueue = dispatch_queue_create( "com.nga.GLFace.serialSessionQueue", DISPATCH_QUEUE_SERIAL );
        dispatch_queue_t high = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0 );
        dispatch_set_target_queue( _serialSessionQueue, high );
        _group = dispatch_group_create();
        _projection = GLKMatrix4Identity;
    }
    return self;
}


- (void)dealloc
{
    [self tearDown];
    [self stopAVCapture];
}


- (IBAction)swapCamera:(id)sender
{
    if ( _session.inputs.count )
    {
        AVCaptureDeviceInput *oldInput = _session.inputs[ 0 ];
        AVCaptureDevicePosition position = oldInput.device.position;
        [self setupAVCaptureWithCamera:position == AVCaptureDevicePositionFront ? AVCaptureDevicePositionBack:AVCaptureDevicePositionFront];
    }
}


#pragma mark Camera setup


- (AVCaptureDevice *)cameraByPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    AVCaptureDevice *device = nil;

    for ( AVCaptureDevice *dev in devices )
    {
        if ( [dev position] == position )
        {
            device = dev;
            break;
        }
    }
    if ( device )
    {
        if ( [device.activeFormat videoSupportedFrameRateRanges] )
        {
            [self attemptToConfigureCamera:device toFPS:FRAMERATE];
        }

        if ( [ device lockForConfiguration:nil] )
        {
            if ( device.focusPointOfInterestSupported )
            {
                device.focusPointOfInterest = CGPointMake( .5, .5 );     // CENTER
            }
            if ( device.isLowLightBoostSupported )
            {
                device.automaticallyEnablesLowLightBoostWhenAvailable = YES;
            }
            if ( [device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance] )
            {
                [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
            }
            [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            [device setVideoZoomFactor:1];
            [device unlockForConfiguration];
        }
    }
    return device;
}


- (void)stopAVCapture
{
    dispatch_async( _serialSessionQueue, ^() {
        if ( _session.isRunning )
        {
            [_session stopRunning];
        }
        _session = nil;
        [self tearDown];
    } );
}


- (CGSize)frameSize
{
    return CGSizeMake( 288, 352 );
    // return CGSizeMake( 480, 640 );
}


- (void)setupAVCaptureWithCamera:(AVCaptureDevicePosition)position
{
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    [_session setSessionPreset:AVCaptureSessionPreset352x288];
    // [_session setSessionPreset:AVCaptureSessionPreset640x480];

    AVCaptureDevice *videoDevice = [self cameraByPosition:position];
    if ( videoDevice == nil )
    {
        return;
    }

    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if ( error )
    {
        return;
    }

    [_session addInput:input];

    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoOutput setAlwaysDiscardsLateVideoFrames:YES];

#if defined YUV_CAMERA && YUV_CAMERA > 0
    [_videoOutput setVideoSettings:@{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) }];
#else
    [_videoOutput setVideoSettings:@{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) }];
#endif

    _videoOutput.alwaysDiscardsLateVideoFrames = YES;

    [_videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [_session addOutput:_videoOutput];

    // set portrait orientation
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    [_videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    _videoConnection.automaticallyAdjustsVideoMirroring = NO;
    if ( _videoConnection.supportsVideoMirroring )
    {
        _videoConnection.videoMirrored = position == AVCaptureDevicePositionFront;
    }

#if defined METADATA && METADATA > 0
    // Metadata output
    AVCaptureMetadataOutput *metadataOutput = [AVCaptureMetadataOutput new];
    [metadataOutput setMetadataObjectsDelegate:self queue:_serialMetadataQueue];
    if ( [_session canAddOutput:metadataOutput] )
    {
        [_session addOutput:metadataOutput];
        metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    }
#endif

    dispatch_async( _serialSessionQueue, ^() {
        [_session commitConfiguration];
        [_session startRunning];
    } );
}


#pragma mark Video capture

#define FourCC2Str( code ) (char[5]) { (code >> 24) & 0xFF, (code >> 16) & 0xFF, (code >> 8) & 0xFF, code & 0xFF, 0 }

- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
    fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer( sampleBuffer );

    // BACKGROUND FRAME PROCESSING
    
    [self updateFrame:pixelBuffer];
    if ( !dispatch_group_wait( _group, DISPATCH_TIME_NOW ) )
    {
        CVBufferRetain( pixelBuffer );
        dispatch_group_async( _group, _serialSessionQueue, ^{
            [_delegate processImageBuffer:pixelBuffer];
            CVBufferRelease( pixelBuffer );
        } );
    }

    // MAIN THREAD PROCESSING EXAMPLE
    
    //static int counter = 0;
    //if ( _highPerformanceDevice || ++counter % 2 )
    //{
    //     [_delegate processImageBuffer:pixelBuffer];
    //}
}


#pragma mark Metadata capture


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    CGRect faceBounds = CGRectZero;

    if ( metadataObjects.count )
    {
        if ( [[(AVMetadataObject *)metadataObjects[ 0 ] type] isEqual:AVMetadataObjectTypeFace] )
        {
            AVMetadataFaceObject *face = metadataObjects[ 0 ];
            faceBounds  = [captureOutput rectForMetadataOutputRectOfInterest:face.bounds];
        }
    }
}


#pragma mark - Utilities

- (void)attemptToConfigureCamera:(AVCaptureDevice *)device toFPS:(int)desiredFrameRate
{
    NSError *error;

    if ( ![device lockForConfiguration:&error] )
    {
        NSLog( @"Could not lock device %@ for configuration: %@", device, error );
        return;
    }

    AVCaptureDeviceFormat *format = device.activeFormat;
    double epsilon = 0.00000001;

    for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges )
    {

        if ( range.minFrameRate <= (desiredFrameRate + epsilon) &&
             range.maxFrameRate >= (desiredFrameRate - epsilon))
        {
            device.activeVideoMaxFrameDuration = (CMTime) {
                .value = 1,
                .timescale = desiredFrameRate,
                .flags = kCMTimeFlags_Valid,
                .epoch = 0,
            };
            device.activeVideoMinFrameDuration = (CMTime) {
                .value = 1,
                .timescale = desiredFrameRate,
                .flags = kCMTimeFlags_Valid,
                .epoch = 0,
            };
            break;
        }
    }

    [device unlockForConfiguration];
}


@end
