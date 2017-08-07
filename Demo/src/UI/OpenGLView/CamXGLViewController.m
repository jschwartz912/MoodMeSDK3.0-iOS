//
//  CamXGLViewController.m
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

#import "CamXGLViewController.h"
#import "MainViewController.h"
#import "GLScene.h"


@interface CamXGLViewController () <GLKViewDelegate> {

    GLScene *_scene;
    CADisplayLink *_displayLink;

}

@end


@implementation CamXGLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _scene = [[GLScene alloc] initWithView:(GLKView *)self.glkView];

    [[NSNotificationCenter defaultCenter]
     addObserver:self
        selector:@selector(onApplicationWillResignActive:)
            name:UIApplicationWillResignActiveNotification
          object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
        selector:@selector(onApplicationDidBecomeActive:)
            name:UIApplicationDidBecomeActiveNotification
          object:nil];


    _glkView.enableSetNeedsDisplay = NO;
    _glkView.delegate = self;

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapGesture];

    [Camera setupAVCaptureWithCamera:AVCaptureDevicePositionFront];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ( !_displayLink )
    {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
        _displayLink.frameInterval = 60 / FRAMERATE;
        //[_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_scene setupWithView:(GLKView *)self.glkView];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ( _displayLink )
    {
        //[_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [_displayLink invalidate];
        _displayLink = nil;
    }
}


- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
               name:UIApplicationWillResignActiveNotification
             object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
               name:UIApplicationDidBecomeActiveNotification
             object:nil];
    [super viewDidUnload];
}


- (void)onApplicationWillResignActive:(NSDictionary *)userInfo
{
    if ( _displayLink )
    {
        //[_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [_displayLink invalidate];
        _displayLink = nil;
    }
}


- (void)onApplicationDidBecomeActive:(NSDictionary *)userInfo
{
    if ( !_displayLink )
    {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
        _displayLink.frameInterval = 60 / FRAMERATE;
        //[_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}


- (IBAction)onSwapCamera:(id)sender
{
    [Camera swapCamera:sender];
}


- (void)reset
{
    [_scene reset];
}


#pragma mark - GLKView and GLKViewController delegate methods


- (void)update
{
    static int fpsCounter = 0;
    static CFTimeInterval lastTime = 0;

    fpsCounter++;
    CFTimeInterval currTime = CACurrentMediaTime();
    if ( currTime >= lastTime + 1. )
    {
        __block int tt = fpsCounter;
        dispatch_async( dispatch_get_main_queue(), ^() {
            self.fpsLabel.text = [NSString stringWithFormat:@"%d fps", tt];
        } );
        fpsCounter = 0;
        lastTime = currTime;
    }
}


- (void)render:(CADisplayLink *)displayLink
{
    dispatch_async( dispatch_get_main_queue(), ^() {
        [self update];
    } );
    [_scene update];
    [_glkView display];
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    void (^renderBlock)( BOOL, float ) = ^( BOOL flipped, float scale ){
        [_scene render];
    };

    renderBlock( NO, view.contentScaleFactor );
}


#pragma mark - Gestures


- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    if ( sender.state == UIGestureRecognizerStateRecognized )
    {
        [_scene reset];
    }
}


@end
