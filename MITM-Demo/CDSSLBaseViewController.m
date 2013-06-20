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

//
// Default SSL URL to connect to.
//
-(NSString *)URL
{
    return @"https://api.centerdevice.de";
}

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge __attribute((objc_requires_super))
{
    if (!self.progressController.working) { return; }
    
    [self.progressController appendLog:@"Received authentication challenge."];
}


- (BOOL) supportedProtectionSpace:(NSURLAuthenticationChallenge*)challenge
{
    if (![challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        [self.progressController appendLog:[NSString stringWithFormat:@"Protection Space %@ not supported. Aborting.",
                                            challenge.protectionSpace]];
        [challenge.sender cancelAuthenticationChallenge:challenge];
        return NO;
    }
    return YES;
}

@end
