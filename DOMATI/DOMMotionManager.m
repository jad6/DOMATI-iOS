//
//  DOMMotionManager.m
//  DOMATI
//
//  Created by Jad Osseiran on 2/11/2013.
//  Copyright (c) 2013 Jad. All rights reserved.
//

#import "DOMMotionManager.h"

#import "DOMErrors.h"

@interface DOMMotionManager ()

@property (nonatomic, strong) DOMMotionItem *headMotionItem, *tailMotionItem;

@property (nonatomic, strong) dispatch_queue_t listQueue;

@end

// 100 Hz update interval.
static NSTimeInterval kUpdateInterval = 1/100.0;

@implementation DOMMotionManager

/**
 *  This makes sure we only ever access one istance of the manager.
 *
 *  @return the singleton manager object.
 */
+ (instancetype)sharedManager
{
    static __DISPATCH_ONCE__ DOMMotionManager *singletonObject = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singletonObject = [[self alloc] init];
        singletonObject.listQueue = dispatch_queue_create("list_queue", DISPATCH_QUEUE_SERIAL);
    });
    
    return singletonObject;
}

/**
 *  Starts the device sensors (both accelerometer and gyroscope).
 *
 *  @param error The error object which will be nil if the operation is successful
 */
- (void)startDeviceMotion:(NSError * __autoreleasing *)error
{
    // Do nothing if the motion sensors are already turned on.
    if ([self isDeviceMotionActive]) {
        return;
    }
    
    // Do not attempt to turn on the sensors if the device does not have
    // them enabled or available.
    if (![self isDeviceMotionAvailable]) {
        // Populate the error to alert the user.
        *error = [DOMErrors noDeviceMotionError];
        return;
    }
    
    // Set up the variables to be used.
    self.deviceMotionUpdateInterval = kUpdateInterval;
    
    // Observe the operation queue with KVO to be alerted when it is empty.
    NSOperationQueue *deviceMotionQueue = [[NSOperationQueue alloc] init];
    // Start the device motion update.
    [self startDeviceMotionUpdatesToQueue:deviceMotionQueue
                              withHandler:^(CMDeviceMotion *motion, NSError *error) {
                                  if (!error) {
                                      dispatch_sync(self.listQueue, ^{
                                          DOMMotionItem *motionItem = [[DOMMotionItem alloc] initWithDeviceMotion:motion];
                                          
                                          if (!self.headMotionItem) {
                                              self.headMotionItem = motionItem;
                                              self.tailMotionItem = motionItem;
                                          } else {
                                              self.tailMotionItem = [self.tailMotionItem insertObjectAfter:motionItem];
                                          }
                                      });
                                  } else {
                                      // Something has gone wrong, log the error and stop the sensors.
                                      [error handle];
                                      [self stopDeviceMotion];
                                  }
                              }];
}

/**
 *  Stops the device sensors (both accelerometer and gyroscope).
 */
- (void)stopDeviceMotion
{
    // Only stop the sensors if they were already active.
    if ([self isDeviceMotionActive]) {
        [self stopDeviceMotionUpdates];
    }
}

- (DOMMotionItem *)lastMotionItem
{
    __block DOMMotionItem *motionItem = nil;
    dispatch_barrier_sync(self.listQueue, ^{
        motionItem = self.tailMotionItem;
    });
    return motionItem;
}

@end