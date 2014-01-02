//
//  OptionsViewController.m
//  PhotoKifu
//
//  Created by Francois Beaussier on 22/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "OptionsViewController.h"
#import "DataManager.h"

@interface OptionsViewController ()

@end

@implementation OptionsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    ScanDisplay *activeScan = [DataManager sharedInstance].activeScan;
    
    float komi = [activeScan.details.komi floatValue];
    self.UISliderKomi.value = komi;
    [self.UILabelKomi setText: [NSString stringWithFormat:@"Komi is %.1f", komi - .5f]];
    
    bool blackPlaysNext = [activeScan.details.blackPlaysNext boolValue];
    [self.UISegmentedControlNextTurn setSelectedSegmentIndex: blackPlaysNext ? 0 : 1];
    
    [self.UiTextFieldBlackPlayer setText: activeScan.details.player1Name];
    [self.UITextFieldWhitePlayer setText: activeScan.details.player2Name];
    
    [self.UITextFieldDescription setText: activeScan.title];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) sliderAction:(id)sender
{
    UISlider *slider = (UISlider *) sender;
    float komi = (float) roundf(slider.value);
    [self.UILabelKomi setText: [NSString stringWithFormat:@"Komi is %.1f", komi - .5f]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

-(void)dismissKeyboard
{
    [self.UiTextFieldBlackPlayer resignFirstResponder];
    [self.UITextFieldWhitePlayer resignFirstResponder];
    [self.UITextFieldDescription resignFirstResponder];
}

- (void) didMoveToParentViewController:(UIViewController *)parent
{
    if (![parent isEqual:self.parentViewController])
    {
        [self save];
    }
}

- (void) save
{
    DataManager *dataManager = [DataManager sharedInstance];
    
    ScanDisplay *activeScan = dataManager.activeScan;

    float value = (float) roundf(self.UISliderKomi.value);
    
    activeScan.details.komi = [NSNumber numberWithFloat: value];

    activeScan.details.player1Name = self.UiTextFieldBlackPlayer.text;
    activeScan.details.player2Name = self.UITextFieldWhitePlayer.text;
    
    activeScan.details.blackPlaysNext = [NSNumber numberWithBool: self.UISegmentedControlNextTurn.selected];

    activeScan.title = self.UITextFieldDescription.text;
    
    [[DataManager sharedInstance] save];
}

@end
