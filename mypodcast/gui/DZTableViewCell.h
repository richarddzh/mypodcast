//
//  DZTableViewCell.h
//  mypodcast
//
//  Created by Richard Dong on 14-9-8.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "SWTableViewCell.h"

@class DZTableViewCell;

@protocol DZTabelViewCellActionDelegate <NSObject>

- (void)cell:(DZTableViewCell *)cell didTriggerAction:(NSInteger)actionID;

@end

@interface DZTableViewCell : SWTableViewCell <UIActionSheetDelegate>

@property (nonatomic,weak) id<DZTabelViewCellActionDelegate> actionDelegate;

- (void)removeAllActions;
- (void)addActionWithIdentifier:(NSInteger)identifier text:(NSString *)text destructive:(BOOL)destructive;
- (void)triggerRightUtilityButtonWithIndex:(NSInteger)index;

@end
