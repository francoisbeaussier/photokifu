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

@property (strong) NSArray *gridCorners;

@property (strong) NSArray *stones;
//@property (strong) NSString *svgFileContent;

@property (strong) NSString *player1Name;
@property (strong) NSString *player2Name;
@property (assign) double komi;
@property (assign) bool nextPlayerIsBlack;

- (id) initWithTitle: (NSString *) title thumbImage: (UIImage *) thumbImage fullImage: (UIImage *) fullImage;

@end
