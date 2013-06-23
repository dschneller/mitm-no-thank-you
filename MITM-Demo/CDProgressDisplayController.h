//
//  CDProgressDisplayController.h
//  MITM-Demo
//
//  Created by Daniel Schneller on 06.06.13.
//  Copyright (c) 2013 CenterDevice GmbH.
//  All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @class CDProgressDisplayController
 @abstract Simple view controller to display a single line status
 and a multi-line history.
 @discussion This view controller manages a current status display 
 and a multi-line status history. By setting the status the 
 single-line display can be modified, the appendLog: method allows 
 directly adding a new entry to the history log.
 */
@interface CDProgressDisplayController : UIViewController

/*!
 When set, a progress indicator will be shown to indicate 
 there is work being done.
 */
@property (nonatomic, assign) BOOL working;

/*!
 Current single-line status
 */
@property (copy, nonatomic)   NSString* status;

/*!
 Appends a line to the log view in this controller's view. 
 It will automatically be assigned the next free line number. 
 Depending on the success flag, the entry will be prepended 
 with a suitable icon.
 
 This method can be called from any queue, it will make
 sure to update any UI components on the main queue.
 
 \param entry the new log entry
 \param success YES when the entry represents a success,
 NO for problems
 */
- (void) appendLog:(NSString*)entry success:(BOOL)success;

/*!
 Appends a line to the log view in this controller's view. 
 It will automatically be assigned the next free line number.
 
 This method can be called from any queue, it will make
 sure to update any UI components on the main queue.
 
 \param entry the new log entry
 */
- (void) appendLog:(NSString*)entry;

/*!
 Resets the current status and history log, as well as resetting 
 the working indicator to an inactive state.
 */
- (void) reset;

@end
