//
//  CDSSLBaseViewController.h
//  
//
//  Created by Daniel Schneller on 06.06.13.
//
//

#import "CDBaseViewController.h"

@interface CDSSLBaseViewController : CDBaseViewController

/*!
 
 Checks the protection space in the passed authentication challenge and verifies
 it is supported. Puts out a bit of logging. If the protection 
 space is NOT supported, the connection will be cancelled
 automatically before returning.
 
 \param challenge The authentication challenge provided for the
 connection
 \return YES, when protected space is supported, NO otherwise.
 
 */
- (BOOL) supportedProtectionSpace:(NSURLAuthenticationChallenge*)challenge;

/*!
 
 Base implementation puts out a log line.
 The implementation subclasses are reponsible to do the right
 thing.
 
 \see supportedProtectionSpace:

 */
-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge __attribute((objc_requires_super));



@end
