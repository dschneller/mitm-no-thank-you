//
//  CDReferenceCertViewController.m
//  MITM-Demo
//
//  Created by Daniel Schneller on 06.06.13.
//  Copyright (c) 2013 CenterDevice GmbH. All rights reserved.
//

#import "CDReferenceCertViewController.h"

@interface CDReferenceCertViewController ()

/*!
 List of known reference certificates.
 Cached after first load.
 */
@property (nonatomic, readonly) NSArray* referenceCerts;

@end

@implementation CDReferenceCertViewController

@synthesize referenceCerts = _referenceCerts;

- (NSArray *)referenceCerts
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Load reference certificate from our main bundle
        NSArray* certificateFiles = @[@"www.google.de",
                                      @"www.google.com"];
        NSBundle* mainBundle = [NSBundle mainBundle];
        NSMutableArray* certDatas = [NSMutableArray array];
        for (NSUInteger i = 0; i<certificateFiles.count; i++)
        {
            NSString *certificateFileLocation =
            [mainBundle pathForResource:certificateFiles[i]
                                 ofType:@"der"];
            NSData *certificateData = [[NSData alloc] initWithContentsOfFile:certificateFileLocation];
            [certDatas addObject:certificateData];
        }
        _referenceCerts = [NSArray arrayWithArray:certDatas];
    });
    return _referenceCerts;
}

#pragma mark - SSL related NSURLConnectionDelegate methods

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [super connection:connection willSendRequestForAuthenticationChallenge:challenge];
    if (!self.progressController.working) { return; }
    if (![super supportedProtectionSpace:challenge]) { return; }
    
    SecTrustRef rcvdServerTrust = challenge.protectionSpace.serverTrust;
    if ([self matchesKnownCertificates:rcvdServerTrust]) {
        // certificate matched a known reference cert.
        // Create a credential instance and proceed.
        NSURLCredential* cred = [NSURLCredential credentialForTrust:rcvdServerTrust];
        [challenge.sender useCredential:cred
             forAuthenticationChallenge:challenge];
    } else {
        // presented certificate did not match one on file.
        // This means we have no conclusive idea about the
        // identity of the server and will therefore abort
        // the connection here.
        [challenge.sender cancelAuthenticationChallenge:challenge];
    }
    
}



- (BOOL)matchesKnownCertificates:(SecTrustRef)presentedTrustInformation {
    // prepare return value
    BOOL certificateVerified = NO; // defensive default
    
    // Perform default trust evaluation first, to make sure the
    // format of the presented data is correct and there are no
    // other trust issues
    SecTrustResultType evaluationResult;
    OSStatus status = SecTrustEvaluate(presentedTrustInformation,
                                       &evaluationResult);
    
    // status now contains the general success/failure result of
    // the evaluation call. evaluationResult has the concrete
    // outcome of the certificate check.
    // only if the call was successful do we need to look a the
    // actual evaluation result
    if (status == errSecSuccess)
    {
        BOOL chainOfTrustOK = (evaluationResult == kSecTrustResultUnspecified);
        [self.progressController appendLog:
         [NSString stringWithFormat:@"Chain of trust %@",
          chainOfTrustOK ? @"OK" : @"broken"]
                                   success:chainOfTrustOK];
        if (chainOfTrustOK)
        {
            [self.progressController appendLog:@"Comparing certs."];
            
            NSUInteger referenceCertCount = [self.referenceCerts count];
            for (NSUInteger i = 0; i<referenceCertCount
                 && !certificateVerified; i++)
            {
                NSData* referenceCert = self.referenceCerts[i];
                
                CFIndex presentedCertsCount = SecTrustGetCertificateCount(presentedTrustInformation);
                for (CFIndex j = 0; j<presentedCertsCount
                     && !certificateVerified; j++)
                {
                    SecCertificateRef currentCert = SecTrustGetCertificateAtIndex(presentedTrustInformation, j);
                    NSData* certData = CFBridgingRelease(SecCertificateCopyData(currentCert));
                    certificateVerified = [referenceCert isEqualToData:certData];
                }
                
                [self.progressController appendLog:[NSString stringWithFormat:@"Ref cert #%d: %@", i, certificateVerified ? @"match" : @"no match"] success:certificateVerified];
            }
            [self.progressController appendLog:(certificateVerified ? @"Found matching reference" : @"No matching reference")
                                       success:certificateVerified];
        }
    } else {
        [self.progressController appendLog:@"SecTrustEvaluate failed."
                                   success:NO];
    }
    
    return certificateVerified;
}



@end
