//
//  YViewController.m
//  YKeyCommands
//
//  Created by lizunyuan on 09/28/2017.
//  Copyright (c) 2017 lizunyuan. All rights reserved.
//

#import "YViewController.h"
#import "YKeyCommands.h"

@interface YViewController ()

@end

@implementation YViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[YKeyCommands sharedInstance] registerKeyCommandWithInput:@"r" modifierFlags:UIKeyModifierCommand action:^(UIKeyCommand *command) {
        NSLog(@"%@",@"11");
    }];
    
    
    [[YKeyCommands sharedInstance] registerKeyCommandWithInput:@"h" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift action:^(UIKeyCommand *command) {
        NSLog(@"%@",@"11");
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
