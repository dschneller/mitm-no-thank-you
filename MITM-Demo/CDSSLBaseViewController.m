//
//  CDSSLBaseViewController.m
//  
//
//  Created by Daniel Schneller on 06.06.13.
//
//

#import "CDSSLBaseViewController.h"

@interface CDSSLBaseViewController()

@property (nonatomic, readwrite) BOOL gotReusedTLSSession;

@end

@implementation CDSSLBaseViewController

//
// Default SSL URL to connect to.
//
-(NSString *)URL
{
    /*
     Due to TLS session re-use (a protocol/operation system level
     optimization to prevent unneeded crypto-handshakes) it can
     be difficult for a single process to witness more than one
     session negotiation to the same host. 
     
     We try to reduce the chance of running into this problem here
     by specifying the same destination in two ways (with and
     without a trailing dot). This will resolve to the same host,
     but at least seems to reduce our chance of hitting cached
     TLS sessions. 
     
     See
     http://developer.apple.com/library/ios/#qa/qa1727/_index.html
     for more details.
     */
    static BOOL withDot = YES;
    withDot = !withDot;
    return withDot ? @"https://www.google.de." : @"https://www.google.de";
}

-(void)connect:(id)sender
{
    self.gotReusedTLSSession = YES;
    [super connect:sender];
}

-(void)connection:(NSURLConnection *)connection
willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge __attribute((objc_requires_super))
{
    if (!self.progressController.working) { return; }
    self.gotReusedTLSSession = NO;
    [self.progressController appendLog:@"Received auth challenge."];
}



- (BOOL) supportedProtectionSpace:(NSURLAuthenticationChallenge*)challenge
{
    if (![challenge.protectionSpace.authenticationMethod
          isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        [self.progressController appendLog:[NSString stringWithFormat:@"%@ not supported. Aborting.",
                                            challenge.protectionSpace]];
        [challenge.sender cancelAuthenticationChallenge:challenge];
        return NO;
    }
    return YES;
}


-(void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    if (self.gotReusedTLSSession)
    {
        self.progressController.status = @"Re-used TLS Session detected.";
        [self.progressController appendLog:@"Re-used TLS Session detected.\nThis is an OS-level optimization.\nTry again or restart the app." success:NO];
        [connection cancel];
        self.progressController.working = NO;
    }
    else
    {
        [super connection:connection didReceiveResponse:response];
    }
}

@end
