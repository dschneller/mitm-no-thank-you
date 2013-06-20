//
//  CDBaseViewController.m
//
//
//  Created by Daniel Schneller on 06.06.13.
//
//

#import "CDBaseViewController.h"

@interface CDBaseViewController ()

@property (nonatomic, readwrite) CDProgressDisplayController* progressController;

@end

@implementation CDBaseViewController

#pragma mark - Actions

- (IBAction)connect:(id)sender
{
    if (self.progressController.working) { return; }
    
    [self.progressController reset];
    NSURLConnection* connection = [self getConnectionFor:self.URL];
    self.progressController.working = YES;
    [connection start];
}


#pragma mark - View and Controller Lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"embedProgress"]) {
        self.progressController = segue.destinationViewController;
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.progressController reset];
}

#pragma mark - Utility functions

- (NSURLConnection*) getConnectionFor:(NSString*)url
{
    // Make sure we don't get any cached response back.
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                         cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                     timeoutInterval:10.0f];
    // Create connection to URL.
    // NOTICE: Even though this is a new connection instance, the underlying network
    //         implementation can re-use an SSL session that has already been negotiated.
    //         In that case, the delegate will not see calls to the security-related
    //         callback methods. This cannot be overridden in iOS6. Just wait about 10
    //         seconds before trying again. By that time the session should have been
    //         torn down.
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:req delegate:self];
    
    self.progressController.status = url;
    [self.progressController appendLog:url];
    [self.progressController appendLog:@"---------------------"];
    
    return connection;
}

#pragma mark - NSURLConnectionDelegate protocol

// default implementations for connection delegate callback methods. they just log their
// call to the progress controller and (if needed, set the "working" property.

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (!self.progressController.working) { return; }
    self.progressController.status = @"Response received";
    [self.progressController appendLog:@"Response received"];
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!self.progressController.working) { return; }
    self.progressController.status = @"Data received";
    [self.progressController appendLog:@"Data received"];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (!self.progressController.working) { return; }
    self.progressController.status = @"Finished loading";
    [self.progressController appendLog:@"Finished loading"];
    self.progressController.working = NO;
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (!self.progressController.working) { return; }
    self.progressController.status = @"ERROR !";
    [self.progressController appendLog:error.description];
    self.progressController.working = NO;
}


@end
