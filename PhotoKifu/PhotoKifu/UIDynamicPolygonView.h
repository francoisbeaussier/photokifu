//
//  UIDynamicPolygonView.h
//  PhotoKifu2
//
//  Created by Francois Beaussier on 14/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MagnifierView.h"
#import "PKGrid.h"

@interface UIDynamicPolygonView : UIView
{
    // MagnifierView *loop;
    int gridSize;
}

@property (assign, nonatomic) bool HasCornerPostionChanged;
@property (strong, nonatomic) NSMutableArray *buttons;
@property (strong, nonatomic) PKGrid *grid;

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (assign, nonatomic) int gridSize;

@property (strong, nonatomic) MagnifierView *magnifier;

- (id) initWithImageView: (UIImageView *) contentImageView andScrollView: (UIScrollView *) scrollView andGrid: (PKGrid *) grid;

- (void) viewWillAppear:(BOOL)animated;

- (void) updateAfterZoom;

@end
