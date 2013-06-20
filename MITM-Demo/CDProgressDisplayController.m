//
//  CDProgressDisplayController.m
//  MITM-Demo
//
//  Created by Daniel Schneller on 06.06.13.
//  Copyright (c) 2013 CenterDevice GmbH. All rights reserved.
//

#import "CDProgressDisplayController.h"
#import "CDLogHistoryTableViewCell.h"

@interface CDProgressDisplayController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableString* log;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (assign, nonatomic) NSUInteger logLineNumber;

@property (strong, nonatomic) NSMutableArray* logLines;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation CDProgressDisplayController

- (void)viewDidAppear:(BOOL)animated
{
    self.working = NO;
}

-(void)setWorking:(BOOL)working
{
    if (_working == working) { return; }
    _working = working;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!working) {
            [self.activity stopAnimating];
        } else {
            [self.activity startAnimating];
        }
    });
}

-(void)setStatus:(NSString *)status
{
    _status = status;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = status;
    });
}

- (void) reset
{
    self.logLines = [NSMutableArray array];
    self.working = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.status = @"Ready";
    });
}

- (void) appendLog:(NSString*)entry
{
    [self.logLines addObject:entry];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


#pragma mark - Table View

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.logLines count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const cellId = @"logHistoryCell";
    CDLogHistoryTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    cell.lineNumberLabel.text = [NSString stringWithFormat:@"%02d", indexPath.row+1];
    cell.statusEntryLabel.text = self.logLines[indexPath.row];
//    cell.lineNumberLabel.textColor = (indexPath.row % 2 == 0) ? [UIColor lightGrayColor] : [UIColor whiteColor];
    
    return cell;
}

@end
