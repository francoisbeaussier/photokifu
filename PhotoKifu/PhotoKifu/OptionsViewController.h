//
//  OptionsViewController.h
//  PhotoKifu
//
//  Created by Francois Beaussier on 22/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OptionsViewController : UIViewController<UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *UiTextFieldBlackPlayer;
@property (strong, nonatomic) IBOutlet UITextField *UITextFieldWhitePlayer;

@end
