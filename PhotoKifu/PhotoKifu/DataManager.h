//
//  DataManager.h
//  PhotoKifu
//
//  Created by Francois Beaussier on 29/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScanDisplay.h"
#import "ScanData.h"

@interface DataManager : NSObject

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) ScanDisplay *activeScan;

+ (instancetype) sharedInstance;

- (id) init;

- (void) save;

- (NSMutableArray *) loadScans;

- (ScanDisplay *) addNewScanFromBundle: (NSString *) photoName withTitle: (NSString *) title;
- (ScanDisplay *) addNewScan: (UIImage *) image withTitle: (NSString *) title;

@end
