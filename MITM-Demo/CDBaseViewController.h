//
//  CDBaseViewController.h
//  
//
//  Created by Daniel Schneller on 06.06.13.
//
//

#import "CDProgressDisplayController.h"

@interface CDBaseViewController : UIViewController

@property (nonatomic, readonly) CDProgressDisplayController* progressController;
@property (nonatomic, readonly) NSString* URL;

@end
