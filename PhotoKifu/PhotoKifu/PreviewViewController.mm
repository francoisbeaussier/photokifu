//
//  PreviewViewController.m
//  PhotoKifu2
//
//  Created by Francois Beaussier on 11/07/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "PreviewViewController.h"
#import "PhotoKifuCore.h"

@interface PreviewViewController ()

@end

@implementation PreviewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    /*
    NSLayoutConstraint *cn = [NSLayoutConstraint constraintWithItem:self.gobanView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1
                                                           constant:200];
    [self.gobanView addConstraint:cn];
    
    cn = [NSLayoutConstraint constraintWithItem:self.gobanView
                                      attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:nil
                                      attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1
                                       constant:200];
    [self.gobanView addConstraint: cn];
    */
    [self.gobanView setStones: _stones];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setStones: (cv::vector<cv::vector<cv::Point>>) stones
{
    _stones = stones;
}

- (IBAction) sliderAction:(id)sender
{
    UISlider *slider = (UISlider *) sender;
    float value = (float) roundf(slider.value);
    value = value / 2;
    [self.UILabelKomi setText: [NSString stringWithFormat:@"Komi is %.1f", value]];
}

- (void) tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    switch (item.tag)
    {
        case 0:
            [self exportSGF];
            break;
        case 1:
            [self emailSGF];
            break;
        case 2:
            [self rotateBoard];
            break;
        case 3:
            [self displayOptions];
            break;
        default:
            NSLog(@"Invalid tabBar item: tag = %i", item.tag);
    }
}

- (NSString *) createSGF
{
    NSString *sgfContent = [PhotoKifuCore generateSgfContent: _stones];
    
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    
    NSString *uniqueFileName = [NSString stringWithFormat: @"photokifu_%@.sgf", guid];
    
    // Create a filePath for the pdf.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex: 0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent: uniqueFileName];
    
    NSError *error = nil;
    
    // Save the PDF. UIDocumentInteractionController has to use a physical PDF, not just the data.
    [sgfContent writeToFile: filePath atomically: YES encoding: NSUTF8StringEncoding error: &error];
    
    NSLog(@"Sgf: %@", sgfContent);
    
    if (error != nil)
    {
        NSLog(@"ERROR: trying to white file: %@", error);
    }
    
    return filePath;
}

- (void) exportSGF
{
    NSString *filePath = [self createSGF];
    
    _docController = [UIDocumentInteractionController interactionControllerWithURL: [NSURL fileURLWithPath: filePath]];
    
    CGPoint centerPoint = self.view.window.center;
    CGRect centerRec = CGRectMake(centerPoint.x, centerPoint.y, 90, 90);
    BOOL isValid = [_docController presentOpenInMenuFromRect: centerRec inView: self.view animated: YES];
    
    if (!isValid)
    {
        NSLog(@"docController: Not valid!");
    }
}

- (NSString *) getTimeFileNameWithPrefix:(NSString *)prefix andSuffix:(NSString *)suffix
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setDateFormat:@"MMddyyyyHHmmss"];
    NSString *fileDate = [dateFormatter stringFromDate:[NSDate date]];
    
    return [NSString stringWithFormat: @"%@%@%@", prefix, fileDate, suffix];
}

- (void) emailSGF
{
    if ([MFMailComposeViewController canSendMail])
    {        
        MFMailComposeViewController *viewController = [[MFMailComposeViewController alloc] init];
        viewController.mailComposeDelegate = self;
        
        [viewController setSubject:@"PhotoKifu - new Kifu"];
        
        NSString *filePath = [self createSGF];
        
        NSMutableData *data=[NSMutableData dataWithContentsOfFile:filePath];
        
        NSString *attachmentFileName = [self getTimeFileNameWithPrefix:@"PhotoKifu-" andSuffix:@".sgf"];
        [viewController addAttachmentData:data mimeType:@"application/x-go-sgf" fileName:attachmentFileName];
        
        [self presentViewController:viewController animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"This device is not configured to send emails" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [alert show];
    }
}


- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) rotateBoard
{
    int boardSize = 19;
    
//  0,  0 -> 19, 0
// 19,  0 -> 19, 19
// 19, 19 -> 0, 19
//  0, 19 -> 0, 0
    
//    3,  1 -> 19 - 1, 3
//   18,  3 -> 19 - 3, 18
    
// x, y -> 19 - y, x
    
    for (int stoneList = 0; stoneList < 2; stoneList++)
    {
        for (int i = 0; i < _stones[stoneList].size(); i++)
        {
            cv::Point point = _stones[stoneList][i];
            
            _stones[stoneList][i] = cv::Point(boardSize - 1 - point.y, point.x);
        }
    }
    
    [self.gobanView setStones: _stones];
    [self.gobanView setNeedsDisplay];
}

- (void) displayOptions
{
    
}



@end
