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

    // Adjust the goban, it needs to stay just under the navigation bar
    // self.gobanView.frame = CGRectMake(0, self.topLayoutGuide.length, self.view.frame.size.width, 19 * 17);
    
    //self.gobanView.frame = self.scrollView.frame;//CGRectMake(0, 0, 1000, 1000);
    
    [self.scrollView setContentSize: CGSizeMake(1000, 1000)];
    
    CGFloat scaleWidth = self.scrollView.frame.size.width / self.scrollView.contentSize.width;
    CGFloat scaleHeight = self.scrollView.frame.size.height / self.scrollView.contentSize.height;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
    self.scrollView.minimumZoomScale = minScale;
    
    // 5
    self.scrollView.maximumZoomScale = 2.0f;
    self.scrollView.zoomScale = minScale;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 1
    //self.imageView = [[UIImageView alloc] initWithImage: image];
    //self.imageView.frame = (CGRect) { .origin = CGPointMake(0.0f, 0.0f), .size = image.size };
    //[self.scrollView addSubview: self.imageView];
    
    // 2
    //self.scrollView.contentSize = image.size;
    
    self.gobanView = [[GobanView alloc] initWithFrame: CGRectMake(0, 0, 1000, 1000)];
    self.gobanView.backgroundColor = [UIColor colorWithRed:234.0f/255.0f green:198.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
//    self.gobanView.frame = CGRectMake(0, 0, 1000, 1000);
    [self.scrollView addSubview: self.gobanView];
    [self.scrollView setContentSize: CGSizeMake(1000, 1000)];
    self.scrollView.delegate = self;
    
    [self.gobanView setStones: _stones];
    [self.gobanView setWarpedImage: _warpedImage];
    
    // Custom initialization
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action: @selector(scrollViewDoubleTapped:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    //[self.gobanView addGestureRecognizer: doubleTapRecognizer];
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action: @selector(scrollViewSingleTapped:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    //[singleTapRecognizer requireGestureRecognizerToFail: doubleTapRecognizer];
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

- (int) getStoneColor:(CGPoint) coordinates
{
    cv::vector<cv::Point> blackStones = _stones[0];
    
    for (int i = 0; i < blackStones.size(); i++)
    {
        cv::Point point = blackStones[i];
        if (point.x == coordinates.x && point.y == coordinates.y)
        {
            return 1; // black stone
        }
    }

    cv::vector<cv::Point> whiteStones = _stones[1];
    
    for (int i = 0; i < whiteStones.size(); i++)
    {
        cv::Point point = whiteStones[i];
        if (point.x == coordinates.x && point.y == coordinates.y)
        {
            return 2; // black stone
        }
    }
    
    return 0;
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

    int color = [self getStoneColor: gobanCoordinates];
    
    if (color == 0)
    {
        // no stone, add a black one;
        _stones[0].push_back(cv::Point(gobanCoordinates.x, gobanCoordinates.y));
    }
    else if (color == 1)
    {
        // black stone, switch to white
        [self removeStone: _stones[0] atCoordinate:gobanCoordinates];
        
        _stones[1].push_back(cv::Point(gobanCoordinates.x, gobanCoordinates.y));
    }
    else if (color == 2)
    {
        // white stone, remove it
        [self removeStone: _stones[1] atCoordinate:gobanCoordinates];
    }
    
    [self.gobanView setStones: _stones];
    [self.gobanView setNeedsDisplay];
    
    /*
    CGFloat newZoomScale = self.scrollView.zoomScale * 1.5f;
    newZoomScale = MIN(newZoomScale, self.scrollView.maximumZoomScale);
    
    CGSize scrollViewSize = self.scrollView.bounds.size;
    
    CGFloat w = scrollViewSize.width / newZoomScale;
    CGFloat h = scrollViewSize.height / newZoomScale;
    CGFloat x = pointInView.x - (w / 2.0f);
    CGFloat y = pointInView.y - (h / 2.0f);
    
    CGRect rectToZoomTo = CGRectMake(x, y, w, h);
    
    [self.scrollView zoomToRect: rectToZoomTo animated:YES];
     */
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

- (void) setStones: (cv::vector<cv::vector<cv::Point>>) stones andWarpedImage: (UIImage *) warpedImage
{
    _stones = stones;
    _warpedImage = warpedImage;
}

- (IBAction)UIBarButtonItemOpenIn:(id)sender {
    [self exportSGF];
}

- (IBAction)UIBarButtonItemEmail:(id)sender {
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
/*
- (IBAction) sliderAction:(id)sender
{
    UISlider *slider = (UISlider *) sender;
    float value = (float) roundf(slider.value);
    value = value - 0.5;
    [self.UILabelKomi setText: [NSString stringWithFormat:@"Komi is %.1f", value]];
}
*/

/*
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
    
    [tabBar setSelectedItem:nil];
}*/

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
    self.gobanView.WarpedImageRotationAngle = (self.gobanView.WarpedImageRotationAngle + 90) % 360;
    [self.gobanView setNeedsDisplay];
}

- (void) displayOptions
{
    OptionsViewController *options = [self.storyboard instantiateViewControllerWithIdentifier:@"OptionsViewController"];
    
    [self.navigationController pushViewController: options animated: YES];
}

@end
