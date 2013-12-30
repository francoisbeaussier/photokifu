//
//  DataManager.m
//  PhotoKifu
//
//  Created by Francois Beaussier on 29/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "DataManager.h"

@implementation DataManager

+ (instancetype) sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    
    dispatch_once(&once, ^
                  {
                      sharedInstance = [self new];
                  });
    
    return sharedInstance;
}

- (NSArray *) LoadData
{
    //Model *ds = [Model sharedDataStore];
    //NSManagedObjectContext context = [dataStore context];
    
    return nil;
}

@end
