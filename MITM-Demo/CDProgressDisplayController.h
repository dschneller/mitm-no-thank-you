//
//  CDProgressDisplayController.h
//  MITM-Demo
//
//  Created by Daniel Schneller on 06.06.13.
//  Copyright (c) 2013 CenterDevice GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CDProgressDisplayController : UIViewController

@property (nonatomic, assign) BOOL working;
@property (copy, nonatomic)   NSString* status;

- (void) appendLog:(NSString*)entry;
- (void) reset;

@end
