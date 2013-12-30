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
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ScanDisplay" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    _scans = [NSMutableArray arrayWithArray: [context executeFetchRequest:fetchRequest error:&error]];
    
    if (error != nil) {
        NSLog(@"Could not fetch ScanDisplays: %@", [error localizedDescription]);
    }
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
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Camera"
                                  otherButtonTitles:@"Photo Library", nil];
    actionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
    [actionSheet showInView: self.view];

    return;
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        NSLog(@"ok Camera");
        if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
        {
            
            UIImagePickerController * picker = [[UIImagePickerController alloc] init];
            [picker setSourceType: UIImagePickerControllerSourceTypeCamera];
            [picker setCameraFlashMode:UIImagePickerControllerCameraFlashModeOff];
            picker.delegate = self;
            [self presentViewController: picker animated: YES completion: nil];
        }
    }

    if (buttonIndex == 1)
    {
        NSLog(@"ok Library");
        
        UIImagePickerController * picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        [picker setSourceType: UIImagePickerControllerSourceTypePhotoLibrary];
        //        picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        [self presentViewController: picker animated: YES completion: nil];
    }
        
    if (!(buttonIndex == [actionSheet cancelButtonIndex]))
    {
    }
}

- (void) imagePickerController: (UIImagePickerController *)picker didFinishPickingMediaWithInfo: (NSDictionary *) info
{
    UIImage *image = [info objectForKey: UIImagePickerControllerOriginalImage];
    
//    CGSize newSize = CGSizeMake(640, 480);
    
//    image = [Utils resizeImage:image scaledToSize:newSize];
    
//    [self.imageView setImage: image];
    
    [self dismissViewControllerAnimated: YES completion:nil];
    UIImage *thumb = [AppDelegate generateThumb: image];
    
    ScanDisplay *newScan = [[ScanDisplay alloc] init]; //]WithTitle: @"new" thumbImage: thumb fullImage: image];
    
    newScan.title = @"New";
    newScan.scanDate = [NSDate date];
    newScan.thumbnail = UIImageJPEGRepresentation(thumb, 0.0);
    newScan.details.photo = UIImageJPEGRepresentation(image, 0.0);
    
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
    ScanDisplay *scan = [self.scans objectAtIndex: indexPath.row];
    cell.textLabel.text = scan.title;
    cell.imageView.image = [UIImage imageWithData:scan.thumbnail]; // TODO: cache this, probably in the ScanDisplay object
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
        ScanDisplay *objectToDelete = [_scans objectAtIndex: indexPath.row];
        [self.managedObjectContext deleteObject: objectToDelete];

        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Could not save deletion: %@", [error localizedDescription]);
        }
        
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

    ScanDisplay *scan = [self.scans objectAtIndex: self.tableView.indexPathForSelectedRow.row];
    
    detailController.detailItem = scan;
    detailController.managedObjectContext = self.managedObjectContext;
}

@end
