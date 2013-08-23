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

@interface PreviewViewController : UIViewController<UITabBarDelegate, MFMailComposeViewControllerDelegate>
{
#ifdef __cplusplus
    cv::vector<cv::vector<cv::Point>> _stones;
#endif

    UIDocumentInteractionController *_docController;

}

#ifdef __cplusplus
- (void) setStones: (cv::vector<cv::vector<cv::Point>>) stones;
#endif

@property (strong, nonatomic) IBOutlet GobanView *gobanView;
@property (strong, nonatomic) IBOutlet UISlider *UISliderKomi;
@property (strong, nonatomic) IBOutlet UISegmentedControl *UISegmentedControlTurnToPlay;
@property (strong, nonatomic) IBOutlet UILabel *UILabelKomi;
@property (strong, nonatomic) IBOutlet UITabBar *UITabBarPreview;

- (IBAction) sliderAction:(id)sender;

- (void) tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item;

- (void) exportSGF;
- (void) emailSGF;
- (void) rotateBoard;
- (void) displayOptions;

@end
