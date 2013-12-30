//
//  GobanScanData.m
//  PhotoKifu2
//
//  Created by Francois Beaussier on 13/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "GobanScanData.h"

@implementation GobanScanData

- (id) initWithTitle: (NSString *) title thumbImage: (UIImage *) thumbImage fullImage: (UIImage *) fullImage;
{
    if ((self = [super init]))
    {
        self.title = title;
        self.thumbImage = thumbImage;
        self.fullImage = fullImage;
    }
    
    return self;
}


@end
