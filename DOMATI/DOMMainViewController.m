//  DOMMainViewController.m
//  DOMATI
// 
//  Created by Jad on 22/04/2014.
//  Copyright (c) 2014 Jad. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
// 
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer. Redistributions in binary
//  form must reproduce the above copyright notice, this list of conditions and
//  the following disclaimer in the documentation and/or other materials
//  provided with the distribution. Neither the name of the nor the names of
//  its contributors may be used to endorse or promote products derived from
//  this software without specific prior written permission.
// 
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.

#import "DOMMainViewController.h"

#import "DOMStrengthGestureRecognizer.h"

@implementation DOMMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSError *error = nil;
    DOMStrengthGestureRecognizer *strengthGR = [[DOMStrengthGestureRecognizer alloc] initWithTarget:self action:@selector(strengthTapAction:) error:&error];
    
    if (error)
        [error handle];
    else
        [self.view addGestureRecognizer:strengthGR];
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Actions

- (void)strengthTapAction:(DOMStrengthGestureRecognizer *)strengthGR
{
    CGFloat strength = strengthGR.strength;
    
    NSLog(@"strength: %f", strength);
    
    if (strength <= 0.33)
    {
        NSLog(@"SOFT");
    }
    else if (strength > 0.33 && strength <= 0.66)
    {
        NSLog(@"MEDIUM");
    }
    else if (strength > 0.66)
    {
        NSLog(@"HARD");
    }
}

@end
