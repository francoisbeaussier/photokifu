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

@interface ScanData : NSManagedObject

@property (nonatomic, retain) NSData * photo;
@property (nonatomic, retain) NSData * gridCorners;
@property (nonatomic, retain) NSData * stones;
@property (nonatomic, retain) NSString * player1Name;
@property (nonatomic, retain) NSNumber * komi;
@property (nonatomic, retain) NSString * player2Name;
@property (nonatomic, retain) NSNumber * blackPlaysNext;

- (void) setGrid: (PKGrid *) grid;
- (PKGrid *) getGrid;

@end
