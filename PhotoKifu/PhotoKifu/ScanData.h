//
//  ScanData.h
//  PhotoKifu
//
//  Created by Francois Beaussier on 29/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PKGrid.h"
#import "PKStones.h"

@interface ScanData : NSManagedObject

@property (nonatomic, retain) NSData * photoData;
@property (nonatomic, retain) NSData * gridData;
@property (nonatomic, retain) NSData * stonesData;

@property (nonatomic, retain) NSString * player1Name;
@property (nonatomic, retain) NSNumber * komi;
@property (nonatomic, retain) NSString * player2Name;
@property (nonatomic, retain) NSNumber * blackPlaysNext;

- (void) setGrid: (PKGrid *) grid;
- (PKGrid *) getGrid;

- (void) setStones: (PKStones *) stones;
- (PKStones *) getStones;

@end
