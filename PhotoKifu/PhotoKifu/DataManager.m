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

- (id) init
{
    self = [super init];
    
    if (self != nil)
    {
    }
    
    return self;
}


- (void) save
{
    NSError *error;
    if (![self.context save:&error])
    {
        NSLog(@"Could not save update to corners: %@", [error localizedDescription]);
    }
}

- (NSMutableArray *) loadScans
{
   
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ScanDisplay" inManagedObjectContext:self.context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    NSMutableArray *result = [NSMutableArray arrayWithArray: [self.context executeFetchRequest:fetchRequest error:&error]];
    
    if (error != nil) {
        NSLog(@"Could not fetch ScanDisplays: %@", [error localizedDescription]);
    }
    
    return result;
}

@end
