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
    if (!working) {
        [self.activity stopAnimating];
    } else {
        [self.activity startAnimating];
    }
    
}

-(void)setStatus:(NSString *)status
{
    _status = status;
    self.statusLabel.text = status;
}

- (void) reset
{
    self.log = [@"" mutableCopy];
    [self.logText setText:self.log];
    self.status = @"Ready";
    self.logLineNumber = 1;
    self.working = NO;
}

- (void) appendLog:(NSString*)entry
{   
    [self.log appendFormat:@"\n%02d: %@", self.logLineNumber++, entry];
    [self.logText setText:self.log];
}


@end
