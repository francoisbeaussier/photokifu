//
//  ScanDisplay.h
//  PhotoKifu
//
//  Created by Francois Beaussier on 29/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ScanData;

@interface ScanDisplay : NSManagedObject

@property (nonatomic, retain) NSData * thumbnailData;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * scanDate;
@property (nonatomic, retain) ScanData *details;

@end
