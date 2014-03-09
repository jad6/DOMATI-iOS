//
//  DOMDataRecordingStrengthGestureRecognizer.m
//  DOMATI
//
//  Created by Jad Osseiran on 27/02/2014.
//  Copyright (c) 2014 Jad. All rights reserved.
//

#import <UIKit/UIGestureRecognizerSubclass.h>

#import "DOMDataRecordingStrengthGestureRecognizer.h"

#import "DOMCalibrationViewController.h"

#import "DOMCoreDataManager.h"
#import "DOMTouchData+Extension.h"
#import "DOMRawMotionData+Extensions.h"
#import "DOMRawTouchData+Extensions.h"

@interface DOMDataRecordingStrengthGestureRecognizer ()

@property (nonatomic, copy) DOMCoreDataSave saveDataCompletionBlock;

@property (nonatomic) BOOL saving;
// Variable to keep track of the number of Core Data saves.
// When this value reaches 0, saving is set to NO. YES otherwise.
@property (nonatomic) NSInteger numberOfCoreDataSaves;
// The current touch strength being recorded if there is one.
@property (nonatomic) DOMCalibrationState currentState;

@end

@implementation DOMDataRecordingStrengthGestureRecognizer 

- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        self.currentState = DOMCalibrationStateNone;
        // Listen to the changes of claibration strengths.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changedState:) name:kCalibrationStateChangeNotificationName object:nil];
    }
    return self;
}

- (id)init
{
    return [self initWithTarget:nil action:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setNumberOfCoreDataSaves:(NSInteger)numberOfCoreDataSaves
{
    if (self->_numberOfCoreDataSaves != numberOfCoreDataSaves) {
        self->_numberOfCoreDataSaves = numberOfCoreDataSaves;
        
        self.saving = (numberOfCoreDataSaves != 0);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Must call this first to populate allPhasesInfoForTouch: &
    // motionsInfoForTouch:
    [super touchesEnded:touches withEvent:event];
    
    // Create a dispatch group to make sure we only call the
    // completion block once all object have been saved.
    dispatch_group_t savingGroup = dispatch_group_create();
    
    for (UITouch *touch in touches) {
        // Get the information from the super class.
        NSArray *touchAllPhasesInfo = [self allPhasesInfoForTouch:touch];
        NSDictionary *motionsInfo = [self motionsInfoForTouch:touch];
        
#warning Should I take this threadContext creation outside of the enumaration?
        // Create a new ManagedObjectContext for multi threading core data operations.
        NSManagedObjectContext *threadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        threadContext.parentContext = [DOMCoreDataManager sharedManager].mainContext;
        
        // Increment the number of saves as we are about to do one.
        self.numberOfCoreDataSaves++;
        // Enter the blcok prior to the save.
        dispatch_group_enter(savingGroup);
        
        [threadContext performBlock:^{
            // Create and set the touch data objects along with
            // its relationships.
            [DOMTouchData touchData:^(DOMTouchData *touchData) {
                [self setDeviceMotionsInfo:motionsInfo
                               onTouchData:touchData
                                 inContext:threadContext];
                
                [self setTouchAllPhasesInfo:touchAllPhasesInfo
                                onTouchData:touchData
                                  inContext:threadContext];
            } inContext:threadContext];
            
            // Save the thread contexts
            [[DOMCoreDataManager sharedManager] saveContext:threadContext];
            
            // We finished saving, decrement that operation.
            self.numberOfCoreDataSaves--;
            // Leave the group.
            dispatch_group_leave(savingGroup);
        }];
    }
    
    // All the saves have completed, call the saving block on
    // the main queue.
    dispatch_group_notify(savingGroup, dispatch_get_main_queue(), ^ {
        if (self.saveDataCompletionBlock) {
            self.saveDataCompletionBlock();
        }
    });
}

/**
 *  Calculates the touch data attributes which are given from the
 *  touches info form all its phases.
 *
 *  @param touchAllPhasesInfo A touch's info in all its stages.
 *  @param touchData          The touch data on which to save data on.
 *  @param context            The context in which to save the data.
 */
- (void)setTouchAllPhasesInfo:(NSArray *)touchAllPhasesInfo
                  onTouchData:(DOMTouchData *)touchData
                    inContext:(NSManagedObjectContext *)context
{
    // Need the start and end times to calculate duration
    NSTimeInterval startTimestamp = 0.0;
    NSTimeInterval endTimestamp = 0.0;
    
    // Used to calculate the x & y deltas.
    CGFloat startX = 0.0;
    CGFloat endX = 0.0;
    CGFloat startY = 0.0;
    CGFloat endY = 0.0;
    
    // Variable to store the maximum radius found for the touch.
    CGFloat maxRadius = (CGFLOAT_IS_DOUBLE) ? DBL_MIN : FLT_MIN;
    
    // Enumerate through each of the touch's phase info.
    for (NSDictionary *touchInfo in touchAllPhasesInfo) {
        // Save the start variables on UITouchPhaseBegan and the end
        // variables on UITouchPhaseEnded.
        if ([touchInfo[kTouchInfoPhaseKey] integerValue] == UITouchPhaseBegan) {
            startTimestamp = [touchInfo[kTouchInfoTimestampKey] doubleValue];
            
            startX = (CGFLOAT_IS_DOUBLE) ? [touchInfo[kTouchInfoXKey] doubleValue] : [touchInfo[kTouchInfoXKey] floatValue];
            startY = (CGFLOAT_IS_DOUBLE) ? [touchInfo[kTouchInfoYKey] doubleValue] : [touchInfo[kTouchInfoYKey] floatValue];
        } else if ([touchInfo[kTouchInfoPhaseKey] integerValue] == UITouchPhaseEnded) {
            endTimestamp = [touchInfo[kTouchInfoTimestampKey] doubleValue];
            
            endX = (CGFLOAT_IS_DOUBLE) ? [touchInfo[kTouchInfoXKey] doubleValue] : [touchInfo[kTouchInfoXKey] floatValue];
            endY = (CGFLOAT_IS_DOUBLE) ? [touchInfo[kTouchInfoYKey] doubleValue] : [touchInfo[kTouchInfoYKey] floatValue];
        }
        
        // Get the current touch radius.
        CGFloat radius = (CGFLOAT_IS_DOUBLE) ? [touchInfo[kTouchInfoRadiusKey] doubleValue] : [touchInfo[kTouchInfoRadiusKey] floatValue];
        // Save it if it is the new maximum.
        if (radius > maxRadius) {
            maxRadius = radius;
        }
        
        // Create a raw touch data object in the context from
        // the touch info.
        DOMRawTouchData *rawData = [DOMRawTouchData rawTouchDataInContext:context fromTouchInfo:touchInfo];
        // Set the relationship between touchData & rawData.
        [touchData addRawTouchDataObject:rawData];
    }
    
    // Set the calculated variables to the touch data object.
    touchData.calibrationStrength = @(self.currentState);
    touchData.xDetla = @(ABS(endX - startX));
    touchData.yDelta = @(ABS(endY - startY));
    touchData.maxRadius = @(maxRadius);
    touchData.duration = @(endTimestamp - startTimestamp);
}

/**
 *  Gets the saved motion data for a touch and saves them on a
 *  DOMTouchData object.
 *
 *  @param motionsInfo The motion data picked up by the device.
 *  @param touchData   The touch data on which to save data on.
 *  @param context     The context in which to save the data.
 */
- (void)setDeviceMotionsInfo:(NSDictionary *)motionsInfo
                 onTouchData:(DOMTouchData *)touchData
                   inContext:(NSManagedObjectContext *)context
{
    // Enumerate through each motion and save them as
    // DOMRawMotionData object.
    for (CMDeviceMotion *motion in motionsInfo[kMotionInfoMotionsKey]) {
        // Create a raw motion data object in the context from
        // the touch info.
        DOMRawMotionData *rawData = [DOMRawMotionData rawMotionDataInContext:context fromDeviceMotion:motion];
        // Set the relationship between touchData & rawData.
        [touchData addRawMotionDataObject:rawData];
    }
    
    // Set the calculated variables to the touch data object.
    touchData.rotationAvg = motionsInfo[kMotionInfoAvgRotationKey];
    touchData.accelerationAvg = motionsInfo[kMotionInfoAvgAccelerationKey];
}

- (void)setCoreDataSaveCompletionBlock:(DOMCoreDataSave)block
{
    self.saveDataCompletionBlock = block;
}

#pragma mark - Notification

/**
 *  Handler method to save the new state change picked up from 
 *  a notification.
 *
 *  @param notification The notification which triggered the call.
 */
- (void)changedState:(NSNotification *)notification
{
    self.currentState = [[notification userInfo][@"state"] integerValue];
}

@end
