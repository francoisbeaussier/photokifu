//
//  MasterViewController.m
//  PhotoKifu2
//
//  Created by Francois Beaussier on 13/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "GobanScanData.h"
#import "AppDelegate.h"
#import "Utils.h"

@interface MasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation MasterViewController

@synthesize scans = _scans;


- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(getPhotoTapped:)];
    self.navigationItem.rightBarButtonItem = addButton;

    self.title = @"Kifu List";
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) insertNewObject:(id)sender
{
    if (!_objects) {
        _scans = [[NSMutableArray alloc] init];
    }
    [_scans insertObject: [NSDate date] atIndex: 0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 0 inSection: 0];
    [self.tableView insertRowsAtIndexPaths: @[indexPath] withRowAnimation: UITableViewRowAnimationAutomatic];
}

- (void) getPhotoTapped: (id) sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
    {
        [imagePicker setSourceType: UIImagePickerControllerSourceTypeCamera];
    }
    else
    {
        [imagePicker setSourceType: UIImagePickerControllerSourceTypePhotoLibrary];
    }
    
    [imagePicker setCameraFlashMode:UIImagePickerControllerCameraFlashModeOff];
    [imagePicker setDelegate: self];
    
    [self presentViewController: imagePicker animated: YES completion: nil];
}

- (void) imagePickerController: (UIImagePickerController *)picker didFinishPickingMediaWithInfo: (NSDictionary *) info
{
    UIImage *image = [info objectForKey: UIImagePickerControllerOriginalImage];
    
//    CGSize newSize = CGSizeMake(640, 480);
    
//    image = [Utils resizeImage:image scaledToSize:newSize];
    
//    [self.imageView setImage: image];
    
    [self dismissViewControllerAnimated: YES completion:nil];
    UIImage *thumb = [AppDelegate generateThumb: image];
    
    GobanScanData *newScan = [[GobanScanData alloc] initWithTitle: @"new" thumbImage: thumb fullImage: image];
    [_scans addObject: newScan];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: _scans.count - 1 inSection: 0];
    NSArray *indexPaths = [NSArray arrayWithObject: indexPath];
    [self.tableView insertRowsAtIndexPaths: indexPaths withRowAnimation: YES];
    
    [self.tableView selectRowAtIndexPath: indexPath animated: YES scrollPosition: UITableViewScrollPositionMiddle];
    [self performSegueWithIdentifier: @"MySegue" sender: self];
}


#pragma mark - Table View

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
    return _scans.count;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MyBasicCell"];
    GobanScanData *scan = [self.scans objectAtIndex: indexPath.row];
    cell.textLabel.text = scan.title;
    cell.imageView.image = scan.thumbImage;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView: (UITableView *)tableView commitEditingStyle: (UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [_scans removeObjectAtIndex: indexPath.row];
        
        [tableView deleteRowsAtIndexPaths: @[indexPath] withRowAnimation: UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        
        
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void) prepareForSegue: (UIStoryboardSegue *) segue sender: (id) sender
{
    DetailViewController *detailController = segue.destinationViewController;

    GobanScanData *scan = [self.scans objectAtIndex: self.tableView.indexPathForSelectedRow.row];
    
    detailController.detailItem = scan;
}

@end
