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
#import "DataManager.h"

@interface MasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation MasterViewController

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) viewDidLoad
{
    // http://stackoverflow.com/questions/9079907/why-does-uinavigationbar-steal-touch-events
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(getPhotoTapped:)];
    self.navigationItem.rightBarButtonItem = addButton;

    self.title = @"Kifu List";
    
    self.scans = [[DataManager sharedInstance] loadScans];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) insertNewObject:(id)sender
{
    if (!_objects) {
        self.scans = [[NSMutableArray alloc] init];
    }
    [self.scans insertObject: [NSDate date] atIndex: 0];
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
    
    
    ScanDisplay *newScan = [[DataManager sharedInstance] addNewScan: image withTitle: @"New"];
    
    [self.scans addObject: newScan];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: self.scans.count - 1 inSection: 0];
    NSArray *indexPaths = [NSArray arrayWithObject: indexPath];
    [self.tableView insertRowsAtIndexPaths: indexPaths withRowAnimation: YES];
    
    [self.tableView selectRowAtIndexPath: indexPath animated: YES scrollPosition: UITableViewScrollPositionMiddle];
    [self performSegueWithIdentifier: @"MySegue" sender: self];
    
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSSortDescriptor *sort=[NSSortDescriptor sortDescriptorWithKey:@"scanDate" ascending:NO];
    [self.scans sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    
    [self.tableView reloadData];
}

#pragma mark - Table View

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
    return self.scans.count;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MyBasicCell"];
    ScanDisplay *scan = [self.scans objectAtIndex: indexPath.row];
    cell.textLabel.text = scan.title;
    cell.imageView.image = [UIImage imageWithData:scan.thumbnailData]; // TODO: cache this, probably in the ScanDisplay object
    return cell;
}

//- (void) refreshTableRowAtIndex: (int) index
//{
//    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
//    
//    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
//}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView: (UITableView *)tableView commitEditingStyle: (UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSManagedObjectContext *context = [DataManager sharedInstance].context;
        
        ScanDisplay *objectToDelete = [self.scans objectAtIndex: indexPath.row];
        [context deleteObject: objectToDelete];

        NSError *error;
        if (![context save:&error]) {
            NSLog(@"Could not save deletion: %@", [error localizedDescription]);
        }
        
        [self.scans removeObjectAtIndex: indexPath.row];
        
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
    ScanDisplay *scan = [self.scans objectAtIndex: self.tableView.indexPathForSelectedRow.row];

    [DataManager sharedInstance].activeScan = scan;
}

@end
