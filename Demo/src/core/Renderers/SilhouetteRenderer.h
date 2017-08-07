//
//  SilhouetteRenderer.h
//  Demo
//
//  Created by Leonid Mesentsev on 07/12/15.
//  Copyright © 2015 Leo Mesentsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface SilhouetteRenderer : NSObject

- (void)setProjection:(GLKMatrix4)projection;
- (void)render;
- (void)tearDown;

@end
