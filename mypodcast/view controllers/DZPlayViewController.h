//
//  DZPlayViewController.h
//  mypodcast
//
//  Created by Richard Dong on 14-7-31.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DZEventCenter.h"

@class DZItem;

@interface DZPlayViewController : UIViewController <DZEventHandler>

@property (nonatomic,retain) IBOutlet UIImageView * imageView;
@property (nonatomic,retain) IBOutlet UISlider * slider;
@property (nonatomic,retain) IBOutlet UIProgressView * progressView;
@property (nonatomic,retain) IBOutlet UIButton * playButton;
@property (nonatomic,retain) IBOutlet UILabel * playTimeLabel;
@property (nonatomic,retain) IBOutlet UILabel * remainTimeLabel;

- (IBAction)onPlayButton:(id)sender;
- (IBAction)onSliderChangeValue:(id)sender;
- (IBAction)onSliderBeginDrag:(id)sender;

@end
