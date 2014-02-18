//
//  DetailViewController.m
//  PhotoKifu2
//
//  Created by Francois Beaussier on 13/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <PhotoKifuCore/GobanDetector.h>
#import <PhotoKifuCore/PerspectiveGrid.h>
#import <PhotoKifuCore/PhotoKifuCore.h>
#import <PhotoKifuCore/GobanDetectorResult.h>

#import "DetailViewController.h"
#import "GobanScanData.h"
#import "UIDynamicPolygonView.h"
#import "PreviewViewController.h"
#import "Utils.h"
#import "DataManager.h"

@implementation DetailViewController

@synthesize scrollView = _scrollView;
@synthesize imageView = _imageView;
@synthesize polygonView = _polygonView;
@synthesize gridSizeButton;

#pragma mark - Managing the detail item

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Kifu";
        
    ScanDisplay *activeScan = [DataManager sharedInstance].activeScan;
    
    UIImage *image = [UIImage imageWithData: activeScan.details.photoData];

    self.imageView = [[UIImageView alloc] initWithImage: image];
    self.imageView.frame = (CGRect) { .origin = CGPointMake(0.0f, 0.0f), .size = image.size };
    [self.scrollView addSubview: self.imageView];

    self.scrollView.contentSize = image.size;
    
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action: @selector(scrollViewDoubleTapped:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    [self.scrollView addGestureRecognizer: doubleTapRecognizer];
    
    UITapGestureRecognizer *twoFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action: @selector(scrollViewTwoFingerTapped:)];
    twoFingerTapRecognizer.numberOfTapsRequired = 1;
    twoFingerTapRecognizer.numberOfTouchesRequired = 2;
    [self.scrollView addGestureRecognizer: twoFingerTapRecognizer];

    self.scrollView.canCancelContentTouches = NO;
    
    // used to know where the UI layout has changed the position / size of the scrollView
    _scrollViewFrame = CGRectMake(0, 0, 0, 0);
    
    [self.UIToolBarItemScan setEnabled: NO];
    
    // disable back navigation swipe, this conflicts with the movement of the grid corners
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    _cornerPositionHasChanged = false;
}

CGRect _scrollViewFrame;

- (void) viewDidLayoutSubviews
{
    CGRect scrollViewFrame = self.scrollView.frame;
    
    if (_scrollViewFrame.origin.x != scrollViewFrame.origin.x ||
        _scrollViewFrame.origin.y != scrollViewFrame.origin.y ||
        _scrollViewFrame.size.width != scrollViewFrame.size.width ||
        _scrollViewFrame.size.height != scrollViewFrame.size.height)
    {
        _scrollViewFrame = scrollViewFrame;
                
        CGFloat scaleWidth = scrollViewFrame.size.width / self.scrollView.contentSize.width;
        CGFloat scaleHeight = scrollViewFrame.size.height / self.scrollView.contentSize.height;
        CGFloat minScale = MIN(scaleWidth, scaleHeight);
        self.scrollView.minimumZoomScale = minScale;
        
        self.scrollView.maximumZoomScale = 0.5f;
        self.scrollView.zoomScale = minScale;
        
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
        
        int size = MIN(self.scrollView.frame.size.width / 3, self.scrollView.frame.size.height / 3);
        [activityView setFrame:CGRectMake(0, 0, size, size)];
        
        [activityView.layer setBackgroundColor:[[UIColor colorWithWhite: 0.0 alpha:0.60] CGColor]];
        activityView.layer.cornerRadius = 5;
        
        activityView.center = CGPointMake(self.scrollView.frame.size.width / 2, self.scrollView.frame.size.height / 2);
        
        [self.scrollView addSubview: activityView];
        [activityView startAnimating];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            ScanDisplay *activeScan = [DataManager sharedInstance].activeScan;
            PKGrid *grid = [activeScan.details getGrid];
            
            if (grid == nil)
            {
                GobanDetector gd(false);
                UIImage *image = [UIImage imageWithData: activeScan.details.photoData]; // TODO: cache this?
                cv::vector<cv::Point> corners = gd.detectGoban(image);
                
                if (corners.size() == 4)
                {
                    grid = [[PKGrid alloc] init];
                    grid.corner1 = CGPointMake(corners[0].x, corners[0].y);
                    grid.corner2 = CGPointMake(corners[1].x, corners[1].y);
                    grid.corner3 = CGPointMake(corners[2].x, corners[2].y);
                    grid.corner4 = CGPointMake(corners[3].x, corners[3].y);
                }
                
                _cornerPositionHasChanged = true;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // hide loading activity and refresh view with loaded data
                
                _magnifier = [[MagnifierView alloc] initWithFrame: CGRectMake(0, 0, 10, 10) andBoundingView: self.scrollView];
                _magnifier.viewToMagnify = self.imageView;
                
                self.polygonView = [[UIDynamicPolygonView alloc] initWithImageView: self.imageView andScrollView: self.scrollView andGrid: grid];
                self.polygonView.backgroundColor = [UIColor clearColor];
                self.polygonView.magnifier = _magnifier;
                self.polygonView.HasCornerPostionChanged = _cornerPositionHasChanged;
                
                [activeScan.details setGrid: grid];
                
                [self.scrollView addSubview: self.polygonView];
                [self.polygonView viewWillAppear:NO];
                
                // default grid size
                [self setGridSize: 19];
                
                [activityView stopAnimating];
                
                [self.UIToolBarItemScan setEnabled: YES];
            });
        });
        
        [self centerScrollViewContents];
    }
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
    if (self.polygonView.HasCornerPostionChanged)
    {
        ScanDisplay *activeScan = [DataManager sharedInstance].activeScan;
        
        PKGrid *grid = self.polygonView.grid;
        
        [activeScan.details setGrid: grid];
    }
    
    [[DataManager sharedInstance] save];
}

- (void) centerScrollViewContents
{
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    
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
    
    self.imageView.frame = contentsFrame;
    self.polygonView.frame = contentsFrame;
}


- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

- (IBAction) gridSizeButtonPressed: (id) sender
{
    int nextGridSize = -1;
    
    switch (self.gridSizeButton.tag)
    {
        case 19:
            nextGridSize = 13;
            break;
        case 13:
            nextGridSize = 9;
            break;
        case 9:
            nextGridSize = 19;
            break;
        default:
            NSLog(@"Unknow grid size: %i", self.gridSizeButton.tag);
            nextGridSize = 19;
    }

    [self setGridSize: nextGridSize];
}

- (IBAction)UIToolBarItemScan:(id)sender
{
    [self.UIToolBarItemScan setEnabled: NO];
    
    [self showPreview];
}

- (void) setGridSize: (int) gridSize
{
    self.gridSizeButton.tag = gridSize;
    [self.gridSizeButton setTitle: [NSString stringWithFormat: @"%i", gridSize] forState: UIControlStateNormal];

    self.polygonView.gridSize = gridSize;
}

- (void) showPreview
{
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    [self.scrollView addSubview: activityView];
    
    int size = MIN(self.scrollView.frame.size.width / 3, self.scrollView.frame.size.height / 3);
    [activityView setFrame:CGRectMake(0, 0, size, size)];
    
    [activityView.layer setBackgroundColor:[[UIColor colorWithWhite: 0.0 alpha:0.60] CGColor]];
    activityView.layer.cornerRadius = 5;

    activityView.center = CGPointMake(self.scrollView.frame.size.width / 2, self.scrollView.frame.size.height / 2);
    
    [activityView startAnimating];
    
    [self save];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // hide loading activity and refresh view with loaded data

            ScanDisplay *activeScan = [DataManager sharedInstance].activeScan;
            
            self.stones = [activeScan.details getStones];
            
            PKGrid *grid = self.polygonView.grid;
            
            GobanDetector gd(false);
            
            cv::vector<cv::Point> points;
            
            points.push_back(cv::Point(grid.corner1.x, grid.corner1.y));
            points.push_back(cv::Point(grid.corner2.x, grid.corner2.y));
            points.push_back(cv::Point(grid.corner3.x, grid.corner3.y));
            points.push_back(cv::Point(grid.corner4.x, grid.corner4.y));
            
            GobanDetectorResult result = gd.extractGobanState(self.imageView.image, points);
            
            // because we don't save the warpedImage, we need to re-extract the goban state. We don't however copy the stones if we already have some, unless the corners have changed
            _warpedImage = result.warpedImage;
            
            if (self.polygonView.HasCornerPostionChanged || self.stones == nil)
            {
                self.stones = [[PKStones alloc] init];
                
                for (int i = 0; i < result.Stones[0].size(); i++)
                {
                    cv::Point point = result.Stones[0][i];
                    
                    [self.stones addBlackStone: CGPointMake(point.x, point.y)];
                }
                
                for (int i = 0; i < result.Stones[1].size(); i++)
                {
                    cv::Point point = result.Stones[1][i];
                    
                    [self.stones addWhiteStone: CGPointMake(point.x, point.y)];
                }
                
                self.polygonView.HasCornerPostionChanged = false;
            }
            
            _cornerPositionHasChanged = false;
            
            [activityView stopAnimating];
            
            [self performSegueWithIdentifier: @"ShowPreview" sender: self];
        
            [self.UIToolBarItemScan setEnabled: YES];
        });
    });
}

- (void) scrollViewDoubleTapped: (UITapGestureRecognizer*) recognizer
{
    CGPoint pointInView = [recognizer locationInView: self.imageView];
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

- (void) scrollViewSingleTapped: (UITapGestureRecognizer*) recognizer
{
}

- (void) scrollViewTwoFingerTapped: (UITapGestureRecognizer*) recognizer
{
    // Zoom out slightly, capping at the minimum zoom scale specified by the scroll view
    CGFloat newZoomScale = self.scrollView.zoomScale / 1.5f;
    newZoomScale = MAX(newZoomScale, self.scrollView.minimumZoomScale);
    [self.scrollView setZoomScale: newZoomScale animated: YES];
}

- (UIView*) viewForZoomingInScrollView: (UIScrollView *) scrollView
{
    // Return the view that you want to zoom
    return self.imageView;
}

- (void) scrollViewDidZoom: (UIScrollView *) scrollView
{
    // The scroll view has zoomed, so you need to re-center the contents
    [self centerScrollViewContents];
    
    [self.polygonView updateAfterZoom];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) textFieldShouldReturn: (UITextField *) textField
{
    [textField resignFirstResponder];

    return YES;
}
 
- (void) prepareForSegue: (UIStoryboardSegue *) segue sender: (id) sender
{
    if ([[segue identifier] isEqualToString: @"ShowPreview"])
    {
        ScanDisplay *activeScan = [DataManager sharedInstance].activeScan;
        
        [activeScan.details setStones: self.stones];
        
        [[DataManager sharedInstance] save];
        
        // Get destination view
        PreviewViewController *preview = [segue destinationViewController];
        
        [preview setStones: self.stones andWarpedImage: _warpedImage andAngle: [activeScan.details.rotation intValue] andScanDisplay: activeScan];
    }
}

@end
