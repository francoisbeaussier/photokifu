//
//  MasterViewController.h
//  PhotoKifu2
//
//  Created by Francois Beaussier on 13/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MasterViewController : UITableViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong) NSMutableArray *scans;

@end
