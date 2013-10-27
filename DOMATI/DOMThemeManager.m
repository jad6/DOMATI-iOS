//
//  DOMThemeManager.m
//  DOMATI
//
//  Created by Jad Osseiran on 27/10/2013.
//  Copyright (c) 2013 Jad. All rights reserved.
//

#import "DOMThemeManager.h"

#import "DOMThemeResources.h"

@implementation DOMThemeManager

+ (id<DOMTheme>)sharedTheme
{
    static __DISPATCH_ONCE__ id singletonObject = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Create and return the theme: (This line should change in the future to change the theme)
        singletonObject = [[DOMThemeResources alloc] init];
    });
    
    return singletonObject;
}

+ (void)customiseAppAppearance
{
    [[UINavigationBar appearance] setBarTintColor:BACKGROUND_COLOR];
    NSDictionary *navAttributes = @{NSForegroundColorAttributeName : TEXT_COLOR};
    [[UINavigationBar appearance] setTitleTextAttributes:navAttributes];
    
    [[UITableView appearance] setBackgroundColor:BACKGROUND_COLOR];
    [[UITableViewCell appearance] setBackgroundColor:BACKGROUND_COLOR];
}

@end
