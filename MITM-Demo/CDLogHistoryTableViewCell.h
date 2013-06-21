//
//  CDLogHistoryTableViewCell.h
//  MITM-Demo
//
//  Created by Daniel Schneller on 21.6.13.
//  Copyright (c) 2013 CenterDevice GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CDLogHistoryTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *lineNumberLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusEntryLabel;

@end
