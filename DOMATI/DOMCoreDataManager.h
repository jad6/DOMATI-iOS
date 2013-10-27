//
//  DOMCoreDataManager.h
//  DOMATI
//
//  Created by Jad Osseiran on 6/09/13.
//  Copyright (c) 2013 Jad. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DOMTouch;
@class Touch;

@interface DOMCoreDataManager : NSObject

+ (instancetype)sharedManager;

- (void)setupCoreData;

- (Touch *)saveTouch:(DOMTouch *)touch;

@end