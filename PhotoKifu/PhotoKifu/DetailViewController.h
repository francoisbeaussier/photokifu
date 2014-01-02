//
//  DetailViewController.h
//  PhotoKifu2
//
//  Created by Francois Beaussier on 13/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GobanScanData.h"
#import "UIDynamicPolygonView.h"
#import "MagnifierView.h"
#import "ScanDisplay.h"
#import "ScanData.h"
#import "PKStones.h"

@interface DetailViewController : UIViewController<UITextFieldDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>
{
    CGFloat _panStartX;
	CGFloat _panStartY;
    
    UIImage *_warpedImage;
    MagnifierView *loop;
    
    bool _cornerPositionHasChanged;
}

@property (nonatomic, strong) UIImageView *imageView;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIButton *gridSizeButton;

@property (strong, nonatomic) UIDynamicPolygonView *polygonView;
@property (strong, nonatomic) PKStones *stones;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *UIToolBarItemScan;

- (void) centerScrollViewContents;
- (void) scrollViewDoubleTapped: (UITapGestureRecognizer*) recognizer;
- (void) scrollViewTwoFingerTapped: (UITapGestureRecognizer*) recognizer;

- (IBAction) gridSizeButtonPressed: (id) sender;
- (IBAction) UIToolBarItemScan:(id)sender;

@end
