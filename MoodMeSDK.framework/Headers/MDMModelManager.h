//
//  MDMModelManager.h
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


@interface MDMModelManager : NSObject {
    
@private
    void *_modelManager;

}


@property (nonatomic, readonly) float *vertices;
@property (nonatomic, readonly) int   verticesNumber;
@property (nonatomic, readonly) int   verticesStride;
@property (nonatomic, readonly) float *texCoords;
@property (nonatomic, readonly) int   texCoordsNumber;
@property (nonatomic, readonly) int   texCoordsStride;
@property (nonatomic, readonly) unsigned short *indices;
@property (nonatomic, readonly) int   indicesNumber;
@property (nonatomic, readonly) float *barycentricPoints;
@property (nonatomic, readonly) float *meanShapeVertices;


/**
 * @brief Model texture path
 */
@property (nonatomic) NSString *texturePath;


- (instancetype)initWithInstance:(void *)instance;

- (void *)modelInstance;

- (BOOL)loadModelFromPath:(NSString *)modelPath;
- (BOOL)saveModelToPath:(NSString *)modelPath;

/**
 * @brief Returns given landmark's index in the vertices array
 * @param landmark short landmark - landmark's index
 * @return unsigned short - model vertex index
 */
- (short)indexOfLandmark:(unsigned short)landmark;

- (void)interpolateVertices;


@end
