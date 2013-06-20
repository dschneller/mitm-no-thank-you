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
static NSString* const kFPWWW  = @"CC 20 5C 47 7C 54 0A 89 E8 C6 26 BF DA 57 87 13 8E 20 BE A7";
static NSString* const kFPStar = @"74 BE E6 47 61 81 33 95 28 7A 46 BB 9E 87 EC 00 36 BC 9B 94";

- (NSSet *)acceptableFingerprints
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _acceptableFingerprints = [NSSet setWithArray:@[kFPStar, kFPWWW]];
    });
    return _acceptableFingerprints;
}

#pragma mark - SSL related NSURLConnectionDelegate methods

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [super connection:connection willSendRequestForAuthenticationChallenge:challenge];
    if (!self.progressController.working) { return; }
    if (![super supportedProtectionSpace:challenge]) { return; }
    
    [self.progressController appendLog:@"Performing fingerprint comparison."];
    
    SecTrustRef serverPresentedTrustInfo = challenge.protectionSpace.serverTrust;
    [self matchesKnownFingerprint:serverPresentedTrustInfo
                            queue:dispatch_get_main_queue()
                       completion:^(BOOL matched) {
                           if (matched)
                           {
                               // certificate matched a known reference cert. Create a credential and proceed.
                               [self.progressController appendLog:@"Certificate validated. Proceeding."];
                               
                               NSURLCredential* cred = [NSURLCredential credentialForTrust:serverPresentedTrustInfo];
                               [challenge.sender useCredential:cred forAuthenticationChallenge:challenge];
                           } else {
                               // presented certificate did not match one on file. This means we have no conclusive
                               // idea about the identity of the server and will therefore abort the connection here.
                               [self.progressController appendLog:@"Certificate validation failed! Canceling connection!"];
                               [challenge.sender cancelAuthenticationChallenge:challenge];
                           }
                       }];
    
}


/*!
 Checks if any of the certificates contained in the presented trust
 information matches one of the known fingerprints. This is done only
 when the chain of trusts evaluates successfully against the default
 system trust store.
 
 This method will execute the actual checks async, because the validation
 of certiifactes may entail blocking network operations. Use the
 completion block to do any work based on the outcome of the fingerprint
 check.
 
 \param presentedTrustInfo the trust information presented to you by the server.
 This is typically obtained from a NSURLAuthenticationChallenge that
 you get as a NSURLConnectionDataDelegate
 
 \param queue Queue to execute the completion block on. In UI driven applications
 this will typically be the main queue, obtained by dispatch_get_main_queue()
 
 \param completion a block to execute when the fingerprint validation is completed.
 The block will be passed YES when the certificates contained in the passed in
 trust info validate against the trust root AND also one of them has a fingerprint
 matching one of the known ones.  NO in all other cases.
 */
- (void) matchesKnownFingerprint:(SecTrustRef)presentedTrustInfo
                           queue:(dispatch_queue_t)queue
                      completion:(void(^)(BOOL matched))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       // prepare return value
                       BOOL fingerprintVerified = NO; // defensive default
                       
                       [self.progressController appendLog:@"Step 1: Validate chain of trust..."];
                       
                       SecTrustResultType evaluationResult;
                       NSString* fingerprint = nil;
                       
                       OSStatus status = SecTrustEvaluate(presentedTrustInfo, &evaluationResult);
                       
                       // only if the call was successful do we need to look a the actual evaluation result
                       if (status == errSecSuccess)
                       {
                           BOOL chainOfTurstVerified = (evaluationResult == kSecTrustResultUnspecified
                                                        || evaluationResult == kSecTrustResultProceed);
                           if (chainOfTurstVerified)
                           {
                               [self.progressController appendLog:@"Step 2: Check fingerprints..."];
                               
                               // now we still need to double check the certificate fingerprints to
                               // make sure we are talking to the correct server, and not merely have
                               // an encrypted channel.
                               // otherwise someone could attempt a man-in-the-middle attack using
                               // a certificate that was correctly signed by any of the many root-CAs
                               // the system trusts. One of these roots might have been introduced
                               // maliciously or as part of corporate policy.
                               
                               // the presented trust information contains the individual certificates
                               // of the whole chain of trust. We iterate through them one by one,
                               // starting at the leaf certificate, looking for one that matches one
                               // of the known fingerprints. Once one is found, the iteration can
                               // stop early.
                               BOOL matchFoundYet = NO;
                               CFIndex certificateCount = SecTrustGetCertificateCount(presentedTrustInfo);
                               
                               for (CFIndex i = 0; i < certificateCount && !matchFoundYet; i++)
                               {
                                   SecCertificateRef certRef = SecTrustGetCertificateAtIndex(presentedTrustInfo, i);
                                   
                                   // get the current certificate's data and calculate the fingerprint from that
                                   CFDataRef certData = SecCertificateCopyData(certRef);
                                   NSData *myData = (NSData *)CFBridgingRelease(certData);
                                   fingerprint = [self sha1:myData];
                                   
                                   
                                   // iterate over all known fingerprints and compare with the one we just calculated
                                   NSString* acceptableOption;
                                   NSEnumerator* knownFingerprintsEnumerator = [self.acceptableFingerprints objectEnumerator];
                                   
                                   while (!matchFoundYet && (acceptableOption = [knownFingerprintsEnumerator nextObject]))
                                   {
                                       matchFoundYet = ([fingerprint compare:acceptableOption
                                                                     options:NSCaseInsensitiveSearch] == NSOrderedSame);
                                   }
                                   
                                   // this part is just for logging. It is not required for the actual checks.
                                   // for the logging, we get some printable info from the current certificate.
                                   NSString* summary = CFBridgingRelease(SecCertificateCopySubjectSummary(certRef));
                                   if (matchFoundYet)
                                   {
                                       [self.progressController appendLog:[NSString stringWithFormat:@"Matched: %@ [%@]", summary, fingerprint]];
                                   }
                                   else
                                   {
                                       [self.progressController appendLog:[NSString stringWithFormat:@"Failed : %@ [%@]", summary, fingerprint]];
                                   }
                               }
                               fingerprintVerified = matchFoundYet;
                           }
                       } else {
                           [self.progressController appendLog:@"Problem occurred executing SecTrustEvaluate. Rejecting connection."];
                       }
                       
                       [self.progressController appendLog:[NSString stringWithFormat:@"Verified: %@", fingerprintVerified ? @"YES" : @"NO"]];
                       
                       // finally execute the completion block on the queue the caller requested,
                       // passing in the outcome of the fingerprint verification
                       dispatch_async(queue,
                                      ^{
                                          completion(fingerprintVerified);
                                      }
                                      );
                   }
                   );
    
}


/*!
 Calculate the SHA-1 hash value of some data.
 
 \param data data to calculate the hash for
 
 \return a string with the fingerprint as it would appear in e. g. Safari. It is 20 hex bytes
 separated by spaces.
 */
- (NSString*)sha1:(NSData*)data {
    unsigned char sha1Buffer[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, sha1Buffer);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 3];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i)
    {
        [fingerprint appendFormat:@"%02x ",sha1Buffer[i]];
    }
    return [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end
