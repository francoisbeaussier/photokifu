//
//  PKGrid.h
//  PhotoKifu
//
//  Created by Francois Beaussier on 31/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PKGrid : NSObject

@property (nonatomic, assign) CGPoint corner1;
@property (nonatomic, assign) CGPoint corner2;
@property (nonatomic, assign) CGPoint corner3;
@property (nonatomic, assign) CGPoint corner4;

- (void) setCorner: (CGPoint) point atZeroBasedIndex: (int) zeroBasedIndex;
- (CGPoint) getCornerAtZeroBasedIndex: (int) zeroBasedIndex;

@end
