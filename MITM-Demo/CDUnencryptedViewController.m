//
//  CDUnencryptedViewController.m
//  MITM-Demo
//
//  Created by Daniel Schneller on 05.06.13.
//  Copyright (c) 2013 CenterDevice GmbH. All rights reserved.
//

#import "CDUnencryptedViewController.h"
#import "CDProgressDisplayController.h"

@interface CDUnencryptedViewController () <NSURLConnectionDataDelegate>
@end

@implementation CDUnencryptedViewController

-(NSString *)URL
{
    return @"http://www.apache.org";
}

@end
