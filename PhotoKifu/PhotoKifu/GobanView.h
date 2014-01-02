//
//  GobanView.h
//  PhotoKifu2
//
//  Created by Francois Beaussier on 11/07/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PKStones.h"

@interface GobanView : UIScrollView
{
    int _gobanSize;
    float _gridCellWidth;
    float _gridLeftPadding;

    UIImage * _warpedImage;
}

- (void) setWarpedImage: (UIImage *) image;

- (CGPoint) coordinateFromPoint: (CGPoint) point;

@property (nonatomic, strong) PKStones *stones;
@property (assign, atomic) bool WarpedImageIsVisible;
@property (assign, atomic) int WarpedImageRotationAngle;

@end
