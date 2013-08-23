//
//  UIDynamicPolygonView.h
//  PhotoKifu2
//
//  Created by Francois Beaussier on 14/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MagnifierView.h"

@interface UIDynamicPolygonView : UIView
{
    MagnifierView *loop;
    int gridSize;
}

@property (strong, nonatomic) NSMutableArray *buttons;
@property (strong, nonatomic) NSMutableArray *corners;

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (assign, nonatomic) int gridSize;

#ifdef __cplusplus

- (id) initWithImageView: (UIImageView *) contentImageView andScrollView: (UIScrollView *) scrollView andCorners: (cv::vector<cv::Point>) points;

#endif

- (void) viewWillAppear:(BOOL)animated;

- (void) updateAfterZoom;

@end
