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

// definition of well-known certificate fingerprints
static NSString* const kFP1 = @"CC 20 5C 47 7C 54 0A 89 E8 C6 26 BF DA 57 87 13 8E 20 BE A7";
static NSString* const kFP2 = @"74 BE E6 47 61 81 33 95 28 7A 46 BB 9E 87 EC 00 36 BC 9B 94";

- (NSSet *)acceptableFingerprints
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _acceptableFingerprints = [NSSet setWithArray:@[kFP1,
                                                        kFP2]];
    });
    return _acceptableFingerprints;
}

#pragma mark - SSL related NSURLConnectionDelegate methods

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [super connection:connection willSendRequestForAuthenticationChallenge:challenge];
    if (!self.progressController.working) { return; }
    if (![super supportedProtectionSpace:challenge]) { return; }
    
    [self.progressController appendLog:@"Perform fingerprint comparison."];
    
    SecTrustRef rcvdSrvTrustInfo = challenge.protectionSpace.serverTrust;
    
    void(^completion)(BOOL) = ^(BOOL matched) {
        if (matched)
        {
            // certificate matched a known reference cert.
            // Create a credential and proceed.
            NSURLCredential* cred = [NSURLCredential credentialForTrust:rcvdSrvTrustInfo];
            [challenge.sender useCredential:cred
                 forAuthenticationChallenge:challenge];
        } else {
            // presented certificate did not match one on file.
            // This means we have no conclusive idea about the
            // identity of the server and will therefore abort
            // the connection here.
            [challenge.sender
             cancelAuthenticationChallenge:challenge];
        }
    };
    
    [self matchesKnownFingerprint:rcvdSrvTrustInfo
                            queue:dispatch_get_main_queue()
                       completion:completion];
    
}


/*!
 Checks if any of the certificates contained in the presented trust
 information matches one of the known fingerprints. This is done
 only when the chain of trusts evaluates successfully against the
 default system trust store.
 
 This method will execute the actual checks async, because the
 validation of certiifactes may entail blocking network operations.
 Use the completion block to do any work based on the outcome of
 the fingerprint check.
 
 \param presentedTrustInfo the trust information presented
 by the server.  This is typically obtained from a
 NSURLAuthenticationChallenge that you get as a
 NSURLConnectionDelegate
 
 \param queue Queue to execute the completion block on. In UI
 driven applications this will typically be the main queue,
 obtained by dispatch_get_main_queue()
 
 \param completion a block to execute when the fingerprint
 validation is completed. The block will be passed YES when the
 certificates contained in the passed in trust info validate
 against the trust root AND also one of them has a fingerprint
 matching one of the known ones. NO in all other cases.
 */
- (void) matchesKnownFingerprint:(SecTrustRef)rcvdSrvTrustInfo
                           queue:(dispatch_queue_t)queue
                      completion:(void(^)(BOOL matched))completion
{
    void(^asyncBlock)() = ^{
        // prepare return value w/ defensive default
        BOOL fpMatched = NO;
        
        SecTrustResultType evaluationResult;
        NSString* rcvdFP = nil;
        
        OSStatus status = SecTrustEvaluate(rcvdSrvTrustInfo,
                                           &evaluationResult);
        
        // only if the call was successful do we
        // need to look a the actual evaluation
        // result
        if (status == errSecSuccess)
        {
            BOOL chainOfTrustOK = (evaluationResult == kSecTrustResultUnspecified);
            [self.progressController appendLog:
             [NSString stringWithFormat:@"Chain of trust %@",
              chainOfTrustOK ? @"OK" : @"broken"]
                                       success:chainOfTrustOK];
            if (chainOfTrustOK)
            {
                [self.progressController
                 appendLog:@"Check fingerprints..."];
                
                // now we still need to double check the
                // certificate fingerprints to make sure we are
                // talking to the correct server, and not merely
                // have an encrypted channel.
                // otherwise someone could attempt a man-in-the-
                // middle attack using a certificate that was
                // correctly signed by any of the many Root-CAs
                // the system trusts. One of these roots might have
                // been introduced maliciously or as part of
                // corporate policy.
                
                // the presented trust information contains the
                // individual certificates of the whole chain of
                // trust. We iterate through them one by one,
                // starting at the leaf certificate, looking for
                // one that matches one of the known fingerprints.
                // Once one is found, the iteration can stop early.
                BOOL found = NO;
                CFIndex certCount = SecTrustGetCertificateCount(rcvdSrvTrustInfo);
                
                for (CFIndex i = 0; i < certCount && !found; i++)
                {
                    SecCertificateRef crtRef = SecTrustGetCertificateAtIndex(rcvdSrvTrustInfo, i);
                    
                    // get the current certificate's data and
                    // calculate the fingerprint from that
                    CFDataRef crtDataRef = SecCertificateCopyData(crtRef);
                    NSData *crtData = (NSData *)CFBridgingRelease(crtDataRef);
                    rcvdFP = [self sha1:crtData];
                    
                    // iterate over all known fingerprints and
                    // compare with the one we just calculated
                    NSString* knownFP;
                    NSEnumerator* knownFPEnum = [self.acceptableFingerprints objectEnumerator];
                    
                    while (!found
                           && (knownFP = [knownFPEnum nextObject]))
                    {
                        found = NSOrderedSame ==
                        [rcvdFP compare:knownFP
                                options:NSCaseInsensitiveSearch];
                    }
                    
                    // just for for the logging, we get some
                    // printable info from the current certificate.
                    NSString* info = CFBridgingRelease(SecCertificateCopySubjectSummary(crtRef));
                    
                    [self.progressController
                     appendLog:info
                     success:found];
                    [self.progressController
                     appendLog:rcvdFP
                     success:found];
                }
                fpMatched = found;
            }
        } else {
            [self.progressController appendLog:@"Problem w/ SecTrustEvaluate."];
            [self.progressController appendLog:@"Rejecting connection."];
        }
        
        [self.progressController appendLog:[NSString stringWithFormat:@"Fingerprint %@", fpMatched ? @"accepted" : @"unknown"] success:fpMatched];
        
        // finally execute the completion block on the queue the
        // caller requested, passing in the outcome of the
        // fingerprint verification
        dispatch_async(queue, ^{
            completion(fpMatched);
        });
        
        
    };
    
    dispatch_async(dispatch_get_global_queue                   (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), asyncBlock);
}


/*!
 Calculate the SHA-1 hash value of some data.
 
 \param data data to calculate the hash for
 
 \return a string with the fingerprint as it would appear in 
 e. g. Safari. It is 20 hex bytes separated by spaces.
 */
- (NSString*)sha1:(NSData*)data {
    unsigned char sha1Buffer[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, sha1Buffer);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 3];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i)
    {
        [fingerprint appendFormat:@"%02x",sha1Buffer[i]];
        if (i < CC_SHA1_DIGEST_LENGTH - 1)
        {
            [fingerprint appendString:@" "];
        }
    }
    return fingerprint;
}

@end
