//
//  OptionsViewController.h
//  PhotoKifu
//
//  Created by Francois Beaussier on 22/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScanDisplay.h"

@interface OptionsViewController : UIViewController<UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *UiTextFieldBlackPlayer;
@property (strong, nonatomic) IBOutlet UITextField *UITextFieldWhitePlayer;
@property (strong, nonatomic) IBOutlet UISlider *UISliderKomi;
@property (strong, nonatomic) IBOutlet UILabel *UILabelKomi;
@property (strong, nonatomic) IBOutlet UISegmentedControl *UISegmentedControlNextTurn;
@property (strong, nonatomic) IBOutlet UITextField *UITextFieldDescription;

- (IBAction) sliderAction:(id)sender;

@end
