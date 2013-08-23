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

@interface DetailViewController : UIViewController<UITextFieldDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>
{
    CGFloat _panStartX;
	CGFloat _panStartY;
        
#ifdef __cplusplus
    cv::vector<cv::vector<cv::Point>> _stones;
#endif
    
    MagnifierView *loop;
}

@property (strong, nonatomic) GobanScanData *detailItem;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIButton *gridSizeButton;

@property (strong, nonatomic) UIDynamicPolygonView *polygonView;

- (IBAction) goButtonPressed: (id) sender;

- (IBAction) gridSizeButtonPressed: (id) sender;

@end
