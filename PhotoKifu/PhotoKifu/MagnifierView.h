//
//  MagnifierView.h
//  PhotoKifu2
//
//  Created by Francois Beaussier on 20/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MagnifierView : UIView {
    UIView *viewToMagnify;
    CGPoint touchPoint;
    
    CGImageRef mask;
    UIImage *glass;
}

@property (nonatomic, retain) UIView *viewToMagnify;
@property (assign) CGPoint touchPoint;

@end