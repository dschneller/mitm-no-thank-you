//
//  CDSSLBaseViewController.m
//  
//
//  Created by Daniel Schneller on 06.06.13.
//
//

#import "CDSSLBaseViewController.h"

@interface CDSSLBaseViewController () <NSURLConnectionDataDelegate>
@end

@implementation CDSSLBaseViewController

// Default SSL URL to connect to.
-(NSString *)URL
{
    return @"https://api.centerdevice.de";
}

#pragma mark - SSL related NSURLConnectionDelegate methods

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    [self.progressController appendLog:@"Checking protection space is server-trust"];
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}


@end
