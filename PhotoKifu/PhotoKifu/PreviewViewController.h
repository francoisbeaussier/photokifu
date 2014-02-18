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
#import "PKStones.h"
#import "ScanDisplay.h"

@interface PreviewViewController : UIViewController<MFMailComposeViewControllerDelegate, UIScrollViewDelegate>
{
    UIImage *_warpedImage;
    int _angle;
    UIDocumentInteractionController *_docController;
    ScanDisplay *_scanDisplay;
}

- (void) setStones: (PKStones *) stones andWarpedImage: (UIImage *) warpedImage andAngle: (int) angle andScanDisplay: (ScanDisplay *) scanDisplay;

@property PKStones *stones;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet GobanView *gobanView;

- (IBAction)UIBarButtonItemOpenIn:(id)sender;
- (IBAction)UIBarButtonItemEmail:(id)sender;
- (IBAction)UIBarButtonItemRotate:(id)sender;
- (IBAction)UIBarButtonItemOptions:(id)sender;

- (IBAction)UISwitchPhotoValueChanged:(UISwitch *)sender;

- (void) exportSGF;
- (void) emailSGF;
- (void) rotateBoard;
- (void) displayOptions;

@end
