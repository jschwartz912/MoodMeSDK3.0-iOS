//
//  MDMTrackerManager.h
//  MoodMeSDK
//
// Copyright (c) 2015 MoodMe (http://www.mood-me.it)
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

/*!
 * @header
 * @copyright Copyright 2015-2016 MoodMe (@link http://www.mood-me.it @/link)
 * @meta http-equiv="Content-Type" content="text/html; charset=UTF-8"
 * @framework MDMTrackerManager
 * @abstract
 * @discussion MDMTrackerManager Framework provides the APIs and support for
 * Realtime Human Face Tracking and 3D modelling
 * @author L.Y.Mesentsev
 * @version 1.2
 * @encoding utf-8
 * @frameworkcopyright Copyright (c) 2015-2016 MoodMe (@link http://www.mood-me.it @/link)
 */


#ifdef TARGET_IOS
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif // if TARGET_IOS

#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>



/*!
 * @brief Singletone convenient shortcut
 */
#define DM MDMTrackerManager.sharedInstance


/*!
 * @protocol UpdatableScene
 * @abstract Informal protocol that defines the optional methods implemented by delegates of
 * MDMTrackerManager objects.
 */
@protocol UpdatableScene <NSObject>

/*!
 * @brief Will be called by MDMTrackerManager after successful tracking
 */
- (void)update;

@end


@class MDMModelManager;

/*!
 * @class MDMTrackerManager
 * @brief MoodMe Tracker Object
 * @discussion You can instantiate it as singletone or multiple instances to use separately.
 * MDMTrackerManager is the main tracker object that takes in input an image and returns 
 * tracked data:  landmarks, vertices and transformation matrix
 */
@interface MDMTrackerManager : NSObject {
    
@private
    void *_faceDetector;
    MDMModelManager *_model;
    double _scale;
}


/*!
 * @brief Simple mesh vertices
 */
@property (nonatomic) MDMModelManager *model;


/*!
 * @brief Simple mesh vertices
 */
@property (nonatomic, readonly) float *vertices;


/*!
 * @brief Simple mesh vertices number
 */
@property (nonatomic, readonly) int   verticesNumber;


/*!
 * @brief Simple mesh vertices stride
 */
@property (nonatomic, readonly) int   verticesStride;


/*!
 * @brief Simple mesh texCoords
 */
@property (nonatomic, readonly) float *texCoords;


/*!
 * @brief Simple mesh texCoords number
 */
@property (nonatomic, readonly) int   texCoordsNumber;


/*!
 * @brief Simple mesh texCoords stride
 */
@property (nonatomic, readonly) int   texCoordsStride;


/*!
 * @brief Simple mesh indices
 */
@property (nonatomic, readonly) unsigned short *indices;


/*!
 * @brief Simple mesh indices numer
 */
@property (nonatomic, readonly) int indicesNumber;


/*!
 * @brief ModelView scale
 * @discussion Use this values to create ModelView matrix
 */
@property (nonatomic, readonly) float mvScale;

/*!
 * @brief ModelView translations
 * @discussion Use this values to create ModelView matrix
 */
@property (nonatomic, readonly) GLKVector3 mvTranslations;


/*!
 * @brief ModelView rotations
 * @discussion Use this values to create ModelView matrix
 */
@property (nonatomic, readonly) GLKVector3 mvRotations;



/*!
 * @brief ModelView transformation matrix
 * @discussion Use this matrix to apply on 3D mesh
 */
@property (nonatomic, readonly) GLKMatrix4 modelView;


/*!
 * @brief Delegate to be called after successful tracking
 * @see UpdatableScene
 */
@property (nonatomic) id<UpdatableScene> delegate;


/*!
 * @brief Boolean flag indicating if last tracking was successful
 */
@property (nonatomic, readonly) BOOL  faceTracked;


/*!
 * @brief Use CLAHE equalization
 * @discussion Set this flag On to use CLAHE algorithm. CLAHE will equalize 
 * scene lights in order to improve tracking precision, but will reduce 
 * tracking performance.
 * @remark Setting On can cause performance loss on some devices
 */
@property (nonatomic) BOOL useCLAHE;


/*!
 * @brief Use CLM2
 * @discussion Set this flag On to use CLM2 algorithm. 
 * @remark Setting On can cause performance loss on some devices
 */
@property (nonatomic) BOOL useCLM2;


/*!
 * @brief Use Prediction
 * @discussion Set this flag On for Prediction. It will improve
 * tracking precision, but will reduce tracking performance.
 * @remark Setting On can cause performance loss on some devices
 */
@property (nonatomic) BOOL usePrediction;


/*!
 * @brief Pyramid scale value
 * @discussion Use this property to reduce input image for performance reasons,
 * for example, 0.5 will reduce input image by half,  default: 1.0 (not scaled)
 */
@property (nonatomic) double scale;


/*!
 * @brief Mouth opening value
 * @discussion Value 0..1 means mouth opening range
 */
@property (nonatomic, readonly) float mouthValue;


/*!
 * @brief Barycentric Points
 * @discussion Array of 66 3D vertices
 */
@property (nonatomic, readonly) float *barycentricPoints;


/*!
 * @brief 2D Landmarks
 * @discussion Array of 66 pairs of floats (x,y)
 */
@property (nonatomic, readonly) float *landmarks;


/*!
 * @brief Singleton instance
 */
+ (MDMTrackerManager *)sharedInstance;


#ifdef TARGET_IOS
/*!
 * @brief IOS version of processing static image method
 * @discussion Call this method for detecting static images
 * @param UIImage *image - static image to process
 */
- (void)processImage:(UIImage *)image;

/*!
 * @brief IOS version of preview
 * @discussion This is a service method to control the tracker's input image
 * @return preview image
 */
- (UIImage *)previewImage;
#else

/*!
 * @brief OSX version of processing static image method
 * @discussion Call this method for detecting static images
 * @param image - static image to process
 */
- (void)processImage:(NSImage *)image;

/*!
 * @brief OSX version of preview
 * @discussion This is a service method to control the tracker's input image
 * @return preview image
 */
- (NSImage *)previewImage;
#endif // if TARGET_IOS


/*!
 * @brief Processing video frame method
 * @discussion Call this method for detecting on video frames
 * @param frame - video frame to process
 */
- (void)processImageBuffer:(CVImageBufferRef)frame;


/*!
 * @brief Reset tracker
 * @discussion Call this method in order to re-init tracker
 */
- (void)reset;

@end
