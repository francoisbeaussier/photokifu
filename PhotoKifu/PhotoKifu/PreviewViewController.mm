//
//  PreviewViewController.m
//  PhotoKifu2
//
//  Created by Francois Beaussier on 11/07/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "PreviewViewController.h"
#import <PhotoKifuCore/PhotoKifuCore.h>
#import "OptionsViewController.h"
#import "DataManager.h"

@interface PreviewViewController ()

@end

@implementation PreviewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self.scrollView setContentSize: CGSizeMake(1000, 1000)];
    
    CGFloat scaleWidth = self.scrollView.frame.size.width / self.scrollView.contentSize.width;
    CGFloat scaleHeight = self.scrollView.frame.size.height / self.scrollView.contentSize.height;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
    self.scrollView.minimumZoomScale = minScale;
    
    self.scrollView.maximumZoomScale = 2.0f;
    self.scrollView.zoomScale = minScale;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
   
    self.gobanView = [[GobanView alloc] initWithFrame: CGRectMake(0, 0, 1000, 1000)];
    self.gobanView.backgroundColor = [UIColor colorWithRed:234.0f/255.0f green:198.0f/255.0f blue:139.0f/255.0f alpha:1.0f];

    [self.scrollView addSubview: self.gobanView];
    [self.scrollView setContentSize: CGSizeMake(1000, 1000)];
    self.scrollView.delegate = self;
    
    [self.gobanView setStones: self.stones];
    [self.gobanView setWarpedImage: _warpedImage];
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action: @selector(scrollViewSingleTapped:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    [self.gobanView addGestureRecognizer: singleTapRecognizer];
    
    UISwitch *photoSwitch = [[UISwitch alloc] init];
    [photoSwitch setOn:NO];
    [photoSwitch addTarget: self action: @selector(UISwitchPhotoValueChanged:) forControlEvents:UIControlEventValueChanged];

    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:photoSwitch];
    self.navigationItem.rightBarButtonItem = barButtonItem;
}

- (void) centerScrollViewContents
{
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.gobanView.frame;
    
    if (contentsFrame.size.width < boundsSize.width)
    {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    }
    else
    {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height)
    {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    }
    else
    {
        contentsFrame.origin.y = 0.0f;
    }
    
    self.gobanView.frame = contentsFrame;
}

- (UIView*) viewForZoomingInScrollView: (UIScrollView *) scrollView
{
    // Return the view that you want to zoom
    return self.gobanView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    // The scroll view has zoomed, so you need to re-center the contents
    [self centerScrollViewContents];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

struct Remover : public std::binary_function<cv::Point, CGPoint, bool>
{
public:
    bool operator()(const cv::Point& point, CGPoint coordinates) const
    {
        return point.x == coordinates.x && point.y == coordinates.y;
    }
};

- (void) removeStone:(cv::vector<cv::Point>&)stones atCoordinate:(CGPoint) coordinates
{
    stones.erase(std::remove_if(stones.begin(), stones.end(), std::bind2nd(Remover(), coordinates)), stones.end());
}

- (void) scrollViewSingleTapped: (UITapGestureRecognizer*) recognizer
{
    CGPoint pointInView = [recognizer locationInView: self.gobanView];
    //CGPoint pointRelative = [recognizer locationInView: self.scrollView];
    
    CGPoint gobanCoordinates = [self.gobanView coordinateFromPoint:pointInView];

    int color = [self.stones getStoneColor: gobanCoordinates];
    
    if (color == PKStonesEmpty)
    {
        [self.stones addBlackStone: gobanCoordinates];
    }
    else if (color == PKStonesBlack)
    {
        [self.stones removeBlackStone: gobanCoordinates];
        [self.stones addWhiteStone: gobanCoordinates];
    }
    else if (color == PKStonesWhite)
    {
        [self.stones removeWhiteStone: gobanCoordinates];
    }
    
    [self.gobanView setStones: _stones];
    [self.gobanView setNeedsDisplay];
}

- (void) scrollViewDoubleTapped: (UITapGestureRecognizer*) recognizer
{
    CGPoint pointInView = [recognizer locationInView: self.gobanView];
    //CGPoint pointRelative = [recognizer locationInView: self.scrollView];
    
    CGFloat newZoomScale = self.scrollView.zoomScale * 1.5f;
    newZoomScale = MIN(newZoomScale, self.scrollView.maximumZoomScale);
    
    CGSize scrollViewSize = self.scrollView.bounds.size;
    
    CGFloat w = scrollViewSize.width / newZoomScale;
    CGFloat h = scrollViewSize.height / newZoomScale;
    CGFloat x = pointInView.x - (w / 2.0f);
    CGFloat y = pointInView.y - (h / 2.0f);
    
    CGRect rectToZoomTo = CGRectMake(x, y, w, h);
    
    [self.scrollView zoomToRect: rectToZoomTo animated:YES];
}

- (void) setStones: (PKStones *) stones andWarpedImage: (UIImage *) warpedImage
{
    _stones = stones;
    _warpedImage = warpedImage;
}

- (IBAction)UIBarButtonItemOpenIn:(id)sender {
    [self save];
    
    [self exportSGF];
}

- (IBAction)UIBarButtonItemEmail:(id)sender {
    [self save];
    
     [self emailSGF];
}

- (IBAction)UIBarButtonItemRotate:(id)sender {
     [self rotateBoard];
}

- (IBAction)UIBarButtonItemOptions:(id)sender {
     [self displayOptions];
}

- (IBAction)UISwitchPhotoValueChanged:(UISwitch *)sender {

    self.gobanView.WarpedImageIsVisible = !self.gobanView.WarpedImageIsVisible;

    [self.gobanView setNeedsDisplay];
}

- (void) didMoveToParentViewController:(UIViewController *)parent
{
    if (![parent isEqual:self.parentViewController])
    {
        [self save];
    }
}

- (void) save
{
    ScanDisplay *activeScan = [DataManager sharedInstance].activeScan;
    
    [activeScan.details setStones: self.stones];
    
    [[DataManager sharedInstance] save];
}

/*
- (IBAction) sliderAction:(id)sender
{
    UISlider *slider = (UISlider *) sender;
    float value = (float) roundf(slider.value);
    value = value - 0.5;
    [self.UILabelKomi setText: [NSString stringWithFormat:@"Komi is %.1f", value]];
}
*/

- (NSString *) createSGF
{
    NSString *sgfContent = [self.stones generateSgfContent];
    
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
    [self.stones rotate];
    [self.gobanView setStones: self.stones];
    
    self.gobanView.WarpedImageRotationAngle = (self.gobanView.WarpedImageRotationAngle + 90) % 360;
    [self.gobanView setNeedsDisplay];
}

- (void) displayOptions
{
    [self save];
    
    OptionsViewController *options = [self.storyboard instantiateViewControllerWithIdentifier:@"OptionsViewController"];
    
    [self.navigationController pushViewController: options animated: YES];
}

@end
