//
//  CDStandardSSLViewController.m
//  MITM-Demo
//
//  Created by Daniel Schneller on 05.06.13.
//  Copyright (c) 2013 CenterDevice GmbH. All rights reserved.
//

#import "CDStandardSSLViewController.h"

@interface CDStandardSSLViewController () <NSURLConnectionDelegate>
@end

@implementation CDStandardSSLViewController

#pragma mark - SSL related NSURLConnectionDelegate methods

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [super connection:connection willSendRequestForAuthenticationChallenge:challenge];
    if (!self.progressController.working) { return; }
    if (![super supportedProtectionSpace:challenge]) { return; }
    
    [self.progressController appendLog:@"Performing default authentication handling."];
    [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
}




@end
