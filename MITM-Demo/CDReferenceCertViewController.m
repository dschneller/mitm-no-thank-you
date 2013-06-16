//
//  CDReferenceCertViewController.m
//  MITM-Demo
//
//  Created by Daniel Schneller on 06.06.13.
//  Copyright (c) 2013 CenterDevice GmbH. All rights reserved.
//

#import "CDReferenceCertViewController.h"

@interface CDReferenceCertViewController ()
{
    NSUInteger _numReferenceCerts;
    CFArrayRef* _chainsOfTrust;
    SecCertificateRef* _secCertificateRefs;
    CFDataRef* _certDataRefs;
}

@end

@implementation CDReferenceCertViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self loadReferenceCertificates];
}

- (void) loadReferenceCertificates
{
    // Load reference certificate from our main bundle
    NSArray* certificateFiles = @[@"star.centerdevice.de", @"www.centerdevice.de"];
    _numReferenceCerts = certificateFiles.count;
    if (_numReferenceCerts == 0) { return; }
    
    _chainsOfTrust = malloc(_numReferenceCerts * sizeof(CFArrayRef));
    _secCertificateRefs = malloc(_numReferenceCerts * sizeof(SecCertificateRef));
    _certDataRefs = malloc(_numReferenceCerts * sizeof(CFDataRef));
    
    for (NSUInteger i = 0; i<certificateFiles.count; i++)
    {
        NSString *certificateFileLocation = [[NSBundle mainBundle] pathForResource:certificateFiles[i] ofType:@"der"];
        NSData *certificateData = [[NSData alloc] initWithContentsOfFile:certificateFileLocation];
        _certDataRefs[i] = (__bridge_retained CFDataRef)certificateData;
        _secCertificateRefs[i] = SecCertificateCreateWithData(NULL, _certDataRefs[i]);
        
        // Create a specific chain of trust that just contains our reference certificate at the top
        _chainsOfTrust[i] = CFArrayCreate(NULL, (void *)&_secCertificateRefs[i], 1, NULL);;
    }
}

- (void) dealloc
{
    for (NSUInteger i=0; i<_numReferenceCerts; i++)
    {
        CFRelease(_chainsOfTrust[i]);
        CFRelease(_secCertificateRefs[i]);
        CFRelease(_certDataRefs[i]);
    }
}


#pragma mark - SSL related NSURLConnectionDelegate methods

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (!self.progressController.working) { return; }
    [self.progressController appendLog:@"Authentication challenge received"];
    
    SecTrustRef receivedServerCertificate = challenge.protectionSpace.serverTrust;
    if ([self matchesKnownCertificates:receivedServerCertificate]) {
        // certificate matched a known reference cert. Create a credential and proceed.
        [self.progressController appendLog:@"Certificate validated. Proceeding."];
        
        NSURLCredential* cred = [NSURLCredential credentialForTrust:receivedServerCertificate];
        [challenge.sender useCredential:cred forAuthenticationChallenge:challenge];
    } else {
        // presented certificate did not match one on file. This means we have no conclusive
        // idea about the identity of the server and will therefore abort the connection here.
        [self.progressController appendLog:@"Validation Failed! Canceling connection!"];
        [challenge.sender cancelAuthenticationChallenge:challenge];
    }
    
}



- (BOOL)matchesKnownCertificates:(SecTrustRef)presentedTrustInformation {
    // prepare return value
    BOOL certificateVerified = NO; // defensive default

    for (NSUInteger i=0; i<_numReferenceCerts && !certificateVerified; i++)
    {
        [self.progressController appendLog:[NSString stringWithFormat:@"Check against ref. cert #%d", i]];

        // Set up the security framework to verify the presented certificate against our custom
        // chain of trust instead of against the system keychain
        SecTrustSetAnchorCertificates(presentedTrustInformation, _chainsOfTrust[i]);

        // Now perform the actual check, based on the set up a moment ago
        SecTrustResultType evaluationResult;
        OSStatus status = SecTrustEvaluate(presentedTrustInformation, &evaluationResult);
        
        // status now contains the general success/failure result of the evaluation call.
        // evaluationResult has the concrete outcome of the certificate check.
        
        
        // only if the call was successful do we need to look a the actual evaluation result
        if (status == errSecSuccess)
        {
            // only in these 2 cases the certificate could be definitely verified.
            // now we still need to double check the certificate fingerprints to
            // make sure we are talking to the correct server, and not merely have
            // an encrypted channel.
            // otherwise someone could attempt a man-in-the-middle attack using
            // a certificate that was correctly signed by any of the many root-CAs
            // the system trusts by default.
            certificateVerified = (evaluationResult == kSecTrustResultUnspecified
                                   || evaluationResult == kSecTrustResultProceed);
            [self.progressController appendLog:[NSString stringWithFormat:@"  Verified: %@",
                                                certificateVerified ? @"YES" : @"NO"]];
        } else {
            [self.progressController appendLog:@"Problem occurred executing SecTrustEvaluate. Rejecting connection."];
        }

    }

    return certificateVerified;
}



@end
