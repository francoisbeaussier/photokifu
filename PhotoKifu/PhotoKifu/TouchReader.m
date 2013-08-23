//
//  TouchReader.m
//  PhotoKifu2
//
//  Created by Francois Beaussier on 20/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//
/*
#import "TouchReader.h"
#import "MagnifierView.h"

@implementation TouchReader

@synthesize touchTimer;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.touchTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(addLoop) userInfo:nil repeats:NO];
    
    // just create one loop and re-use it.
    if (loop == nil) {
        loop = [[MagnifierView alloc] init];
        loop.viewToMagnify = self;
    }
    
    UITouch *touch = [touches anyObject];
    loop.touchPoint = [touch locationInView:self];
    [loop setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleAction:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.touchTimer invalidate];
    self.touchTimer = nil;
    [loop removeFromSuperview];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.touchTimer invalidate];
    self.touchTimer = nil;
    [loop removeFromSuperview];
}

- (void)addLoop {
    // add the loop to the superview.  if we add it to the view it magnifies, it'll magnify itself!
    [self.superview addSubview:loop];
    // here, we could do some nice animation instead of just adding the subview...
}

- (void)handleAction:(id)timerObj {
    NSSet *touches = timerObj;
    UITouch *touch = [touches anyObject];
    loop.touchPoint = [touch locationInView:self];
    [loop setNeedsDisplay];
}

@end

*/