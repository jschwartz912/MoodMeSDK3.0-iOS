//
//  MainViewController.m
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

#import "MainViewController.h"
#import "CamXGLViewController.h"
#import <MoodMeSDK/SDK.h>


#define kGLViewController @"GLViewController"



@interface MainViewController () {

    CamXGLViewController *_glViewController;

    UIView *_launchImageView;
    UIView *_topAnimationView;
}

@end


@implementation MainViewController


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    _glViewController.fpsLabel = self.fpsLabel;

    NSString *launchScreenStoryboard = [[NSBundle mainBundle] infoDictionary][@"UILaunchStoryboardName"];
    if ( launchScreenStoryboard )
    {
        _topAnimationView = [[UIView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:_topAnimationView];
        UINib *nib = [UINib nibWithNibName:launchScreenStoryboard bundle:nil];
        NSArray *views = [nib instantiateWithOwner:nil options:nil];
        _launchImageView = views[0];
        _launchImageView.frame = self.view.bounds;
        [self.view addSubview:_launchImageView];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    static dispatch_once_t onceToken;
    dispatch_once( &onceToken, ^{
        [self startupAnimation];
    } );
}


- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    [_topAnimationView removeFromSuperview];
}


#pragma mark - Actions


- (IBAction)onSwapCamera:(id)sender
{
    [_glViewController onSwapCamera:sender];
}


- (IBAction)useCLM2:(id)sender
{
    BOOL use = ((UISwitch *)sender).isOn;
    DM.useCLM2 = use;
    NSLog(@"UseCLM2: %@", use ? @"ON" : @"OFF");
}


#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqual:kGLViewController] )
    {
        _glViewController = segue.destinationViewController;
    }
}


- (void)startupAnimation
{
    CATransition *shutterAnimation = [CATransition animation];

    [shutterAnimation setDelegate:(id<CAAnimationDelegate>)self];
    [shutterAnimation setDuration:1.];

    shutterAnimation.timingFunction = UIViewAnimationCurveEaseInOut;
    [shutterAnimation setType:@"cameraIris"];
    [shutterAnimation setValue:@"cameraIris" forKey:@"cameraIris"];
    CALayer *cameraShutter = [[CALayer alloc]init];
    [cameraShutter setBounds:CGRectMake( 0.0, 0.0, 320.0, 425.0 )];
    [shutterAnimation setStartProgress:.5];
    [_topAnimationView.layer addSublayer:cameraShutter];
    [_topAnimationView.layer addAnimation:shutterAnimation forKey:@"cameraIris"];
    [_launchImageView removeFromSuperview];
}


@end
