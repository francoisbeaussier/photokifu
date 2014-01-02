//
//  PKStones.h
//  PhotoKifu
//
//  Created by Francois Beaussier on 1/01/2014.
//  Copyright (c) 2014 Francois Beaussier. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const int PKStonesEmpty;
extern const int PKStonesBlack;
extern const int PKStonesWhite;

@interface PKStones : NSObject

@property (nonatomic, strong) NSMutableArray *blackStones;
@property (nonatomic, strong) NSMutableArray *whiteStones;

- (int) getStoneColor:(CGPoint) coordinates;

- (void) addBlackStone:(CGPoint) coordinates;
- (void) addWhiteStone:(CGPoint) coordinates;

- (void) removeBlackStone:(CGPoint) coordinates;
- (void) removeWhiteStone:(CGPoint) coordinates;

- (NSString *) generateSgfContent;

- (void) rotate;

@end
