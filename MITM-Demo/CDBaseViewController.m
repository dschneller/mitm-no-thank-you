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
    // Simulator apparently sometimes ignored cache policy defined below.
    // To work around that the URL gets modified every time by appending
    // a counter. Still does not help every time, though. :(
    NSMutableString* newUrl = [NSMutableString stringWithString:url];
    static NSUInteger counter = 0;
    [newUrl appendFormat:@"/%d", counter++];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:newUrl]
                                         cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                     timeoutInterval:30.0f];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:req delegate:self];

    self.progressController.status = newUrl;
    [self.progressController appendLog:newUrl];
    [self.progressController appendLog:@"---------------------"];
    
    return connection;
}

#pragma mark - NSURLConnectionDelegate protocol

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
