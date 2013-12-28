//
//  GobanView.h
//  PhotoKifu2
//
//  Created by Francois Beaussier on 11/07/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GobanView : UIScrollView
{
    int _gobanSize;
    float _gridCellWidth;
    float _gridLeftPadding;

#ifdef __cplusplus
    cv::vector<cv::vector<cv::Point>> _stones;
#endif
    UIImage * _warpedImage;
}

#ifdef __cplusplus
- (void) setStones: (cv::vector<cv::vector<cv::Point>>) stones;
#endif


- (void) setWarpedImage: (UIImage *) image;

- (CGPoint) coordinateFromPoint: (CGPoint) point;

@property (assign, atomic) bool WarpedImageIsVisible;
@property (assign, atomic) int WarpedImageRotationAngle;
@end
