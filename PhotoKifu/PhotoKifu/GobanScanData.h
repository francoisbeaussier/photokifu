//
//  GobanScanData.h
//  PhotoKifu2
//
//  Created by Francois Beaussier on 13/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GobanScanData : NSObject

@property (strong) NSString *title;
@property (strong) UIImage *thumbImage;
@property (strong) UIImage *fullImage;

- (id) initWithTitle: (NSString *) title thumbImage: (UIImage *) thumbImage fullImage: (UIImage *) fullImage;

@end
