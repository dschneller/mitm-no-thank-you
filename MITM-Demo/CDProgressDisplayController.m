//
//  CDProgressDisplayController.m
//  MITM-Demo
//
//  Created by Daniel Schneller on 06.06.13.
//  Copyright (c) 2013 CenterDevice GmbH. All rights reserved.
//

#import "CDProgressDisplayController.h"

@interface CDProgressDisplayController ()

@property (strong, nonatomic) NSMutableString* log;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UITextView *logText;
@property (assign, nonatomic) NSUInteger logLineNumber;

@end

@implementation CDProgressDisplayController

- (void)viewDidAppear:(BOOL)animated
{
    self.working = NO;
}

-(void)setWorking:(BOOL)working
{
    if (_working == working) { return; }
    _working = working;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!working) {
            [self.activity stopAnimating];
        } else {
            [self.activity startAnimating];
        }
    });
}

-(void)setStatus:(NSString *)status
{
    _status = status;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = status;
    });
}

- (void) reset
{
    self.logLineNumber = 1;
    self.working = NO;
    self.log = [@"" mutableCopy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.logText setText:self.log];
        self.status = @"Ready";
    });
}

- (void) appendLog:(NSString*)entry
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.log appendFormat:@"\n%02d: %@", self.logLineNumber++, entry];
        [self.logText setText:self.log];
    });
}


@end
