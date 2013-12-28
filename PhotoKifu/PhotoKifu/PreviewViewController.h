//
//  PreviewViewController.h
//  PhotoKifu2
//
//  Created by Francois Beaussier on 11/07/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GobanView.h"
#import "MessageUI/MessageUI.h"
#import "MessageUI/MFMailComposeViewController.h"

@interface PreviewViewController : UIViewController<MFMailComposeViewControllerDelegate, UIScrollViewDelegate>
{
#ifdef __cplusplus
    cv::vector<cv::vector<cv::Point>> _stones;
#endif

    UIImage *_warpedImage;
    UIDocumentInteractionController *_docController;

}

#ifdef __cplusplus
- (void) setStones: (cv::vector<cv::vector<cv::Point>>) stones andWarpedImage: (UIImage *) warpedImage;
#endif

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet GobanView *gobanView;
//@property (strong, nonatomic) IBOutlet UISlider *UISliderKomi;
//@property (strong, nonatomic) IBOutlet UISegmentedControl *UISegmentedControlTurnToPlay;
//@property (strong, nonatomic) IBOutlet UILabel *UILabelKomi;
//@property (strong, nonatomic) IBOutlet UITabBar *UITabBarPreview;

- (IBAction)UIBarButtonItemOpenIn:(id)sender;
- (IBAction)UIBarButtonItemEmail:(id)sender;
- (IBAction)UIBarButtonItemRotate:(id)sender;
- (IBAction)UIBarButtonItemOptions:(id)sender;

- (IBAction)UISwitchPhotoValueChanged:(UISwitch *)sender;

//- (IBAction) sliderAction:(id)sender;

- (void) exportSGF;
- (void) emailSGF;
- (void) rotateBoard;
- (void) displayOptions;

@end
