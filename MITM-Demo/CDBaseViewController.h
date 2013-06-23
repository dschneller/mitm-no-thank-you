//
//  CDBaseViewController.h
//
//
//  Created by Daniel Schneller on 06.06.13.
//
//

#import "CDProgressDisplayController.h"

/*!
 @class CDBaseViewController
 @abstract Base class providing a progress controller and
 target URL property.
 @discussion Base class for view controllers in this demo
 application, providing a property that references an instance
 of CDProgressDisplayController which can be used to report
 progress to the UI. The URL property getter should be overriden
 by concrete subclasses and provide the address to connect to.
 */
@interface CDBaseViewController : UIViewController <NSURLConnectionDataDelegate>

/*!
 Provides an instance of CDProgressDisplayController that can 
 be used to report progress and messages to.
 */
@property (nonatomic, readonly) CDProgressDisplayController* progressController;

/*!
 Provides the URL for this controller to connect to. Getter 
 must be overriden by subclasses.
 */
@property (nonatomic, readonly) NSString* URL;

- (IBAction)connect:(id)sender;


@end
