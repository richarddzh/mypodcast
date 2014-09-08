//
//  DZTableViewCell.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-8.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZTableViewCell.h"

static UIColor * _redColor;
static UIColor * _grayColor;
static UIColor * _blueColor;

#pragma mark - DZTableViewCellAction

@interface DZTableViewCellAction : NSObject
@property (nonatomic,assign) NSInteger identifier;
@property (nonatomic,copy) NSString * text;
@property (nonatomic,assign) BOOL destructive;
@end

@implementation DZTableViewCellAction
@end

#pragma mark - DZTableViewCell

@interface DZTableViewCell ()
{
    NSMutableArray * _actions;
    UIActionSheet * _sheet;
}
@end

@implementation DZTableViewCell

- (void)removeAllActions
{
    self->_actions = nil;
}

- (void)addActionWithIdentifier:(NSInteger)identifier text:(NSString *)text destructive:(BOOL)destructive
{
    if (self->_actions == nil) {
        self->_actions = [NSMutableArray array];
    }
    DZTableViewCellAction * action = [[DZTableViewCellAction alloc]init];
    action.identifier = identifier;
    action.text = text;
    action.destructive = destructive;
    [self->_actions addObject:action];
}

- (void)updateActionButtons
{
    if (_redColor == nil) {
        _redColor = [UIColor redColor];
        _blueColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
        _grayColor = [UIColor lightGrayColor];
    }
    NSMutableArray * utilityButtons = [NSMutableArray array];
    [utilityButtons sw_addUtilityButtonWithColor:_grayColor title:NSLocalizedString(@"More", nil)];
    if (self->_actions != nil && [self->_actions count] > 0) {
        DZTableViewCellAction * action = [self->_actions firstObject];
        [utilityButtons sw_addUtilityButtonWithColor:(action.destructive ? _redColor : _blueColor)
                                               title:action.text];
    }
    self.rightUtilityButtons = utilityButtons;
    self->_sheet = [[UIActionSheet alloc]init];
    self->_sheet.delegate = self;
    for (DZTableViewCellAction * action in self->_actions) {
        NSInteger index = [self->_sheet addButtonWithTitle:action.text];
        if (action.destructive) {
            self->_sheet.destructiveButtonIndex = index;
        }
    }
    NSInteger index = [self->_sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    self->_sheet.cancelButtonIndex = index;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex >= 0 && buttonIndex < [self->_actions count]) {
        DZTableViewCellAction * action = [self->_actions objectAtIndex:buttonIndex];
        [self.actionDelegate cell:self didTriggerAction:action.identifier];
    }
    [self hideUtilityButtonsAnimated:YES];
}

- (void)triggerRightUtilityButtonWithIndex:(NSInteger)index
{
    if (index == 0) {
        [self->_sheet showInView:self];
    } else {
        [self actionSheet:nil clickedButtonAtIndex:0];
    }
}

@end
