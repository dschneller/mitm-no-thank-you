//
//  CDFingerprintViewController.m
//  MITM-Demo
//
//  Created by Daniel Schneller on 05.06.13.
//  Copyright (c) 2013 CenterDevice GmbH. All rights reserved.
//

#import "CDFingerprintViewController.h"
#import <CommonCrypto/CommonDigest.h>

@interface CDFingerprintViewController () <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSSet* acceptableFingerprints;

@end

@implementation CDFingerprintViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.acceptableFingerprints = [NSSet setWithArray:@[
                                   @"CC 20 5C 47 7C 54 0A 89 E8 C6 26 BF DA 57 87 13 8E 20 BE A7",
                                   @"74 BE E6 47 61 81 33 95 28 7A 46 BB 9E 87 EC 00 36 BC 9B 94"]];
}

#pragma mark - SSL related NSURLConnectionDelegate methods

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (!self.progressController.working) { return; }
    [self.progressController appendLog:@"Authentication challenge received"];
    
    SecTrustRef receivedServerCertificate = challenge.protectionSpace.serverTrust;
    if ([self matchesKnownFingerprint:receivedServerCertificate]) {
        // certificate matched a known reference cert. Create a credential and proceed.
        [self.progressController appendLog:@"Certificate validated. Proceeding."];
        
        NSURLCredential* cred = [NSURLCredential credentialForTrust:receivedServerCertificate];
        [challenge.sender useCredential:cred forAuthenticationChallenge:challenge];
    } else {
        // presented certificate did not match one on file. This means we have no conclusive
        // idea about the identity of the server and will therefore abort the connection here.
        [self.progressController appendLog:@"Certificate validation failed! Canceling connection!"];
        [challenge.sender cancelAuthenticationChallenge:challenge];
    }
    
}

- (BOOL) matchesKnownFingerprint:(SecTrustRef)trustRef {
    // prepare return value
    BOOL fingerprintVerified = NO; // defensive default

    [self.progressController appendLog:@"Step 1: Validate chain of trust..."];
    
    SecTrustResultType evaluationResult;
    NSString* fingerprint = nil;
    OSStatus status = SecTrustEvaluate(trustRef, &evaluationResult);

    // only if the call was successful do we need to look a the actual evaluation result
    if (status == errSecSuccess)
    {
        BOOL certificateVerified = (evaluationResult == kSecTrustResultUnspecified
                                    || evaluationResult == kSecTrustResultProceed);
        if (certificateVerified)
        {
            [self.progressController appendLog:@"Step 2: Check fingerprints..."];

            // now we still need to double check the certificate fingerprints to
            // make sure we are talking to the correct server, and not merely have
            // an encrypted channel.
            // otherwise someone could attempt a man-in-the-middle attack using
            // a certificate that was correctly signed by any of the many root-CAs
            // the system trusts.
            
            // iterate over the presented certicate chain.
            BOOL matchFound = NO;
            CFIndex count = SecTrustGetCertificateCount(trustRef);
            for (CFIndex i = 0; i < count && !matchFound; i++)
            {
                SecCertificateRef certRef = SecTrustGetCertificateAtIndex(trustRef, i);
                CFDataRef certData = SecCertificateCopyData(certRef);
              
                NSData *myData = (NSData *)CFBridgingRelease(certData);
                fingerprint = [self sha1:myData];
                
                NSString* summary = CFBridgingRelease(SecCertificateCopySubjectSummary(certRef));
                
                NSString* acceptableOption;
                NSEnumerator* enumerator = [self.acceptableFingerprints objectEnumerator];
                
                while (!matchFound && (acceptableOption = [enumerator nextObject]))
                {
                    matchFound = ([fingerprint compare:acceptableOption options:NSCaseInsensitiveSearch] == NSOrderedSame);
                }
                
                if (matchFound)
                {
                    [self.progressController appendLog:[NSString stringWithFormat:@"Matched: %@ [%@]", summary, fingerprint]];
                }
                else
                {
                    [self.progressController appendLog:[NSString stringWithFormat:@"Failed : %@ [%@]", summary, fingerprint]];
                }
            }
            fingerprintVerified = matchFound;
        }
    } else {
        [self.progressController appendLog:@"Problem occurred executing SecTrustEvaluate. Rejecting connection."];
    }
    
    [self.progressController appendLog:[NSString stringWithFormat:@"Verified: %@", fingerprintVerified ? @"YES" : @"NO"]];
    return fingerprintVerified;
}



- (NSString*)sha1:(NSData*)certData {
    unsigned char sha1Buffer[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(certData.bytes, certData.length, sha1Buffer);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 3];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i)
    {
        [fingerprint appendFormat:@"%02x ",sha1Buffer[i]];
    }
    return [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end
