//
//  CDStandardSSLViewController.m
//  MITM-Demo
//
//  Created by Daniel Schneller on 05.06.13.
//  Copyright (c) 2013 CenterDevice GmbH. All rights reserved.
//

#import "CDStandardSSLViewController.h"

@interface CDStandardSSLViewController () <NSURLConnectionDataDelegate>
@end

@implementation CDStandardSSLViewController

#pragma mark - SSL related NSURLConnectionDelegate methods

// This need not be implemented - then the the system default behaviour takes place.
// Implemented here to add some logging and for clarity
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (!self.progressController.working) { return; }
    [self.progressController appendLog:@"Authentication challenge received"];
    
    [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
}




@end
