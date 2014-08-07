//
//  DZPlayViewController.h
//  mypodcast
//
//  Created by Richard Dong on 14-7-31.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DZPlayViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIImageView * imageView;
@property (nonatomic, retain) IBOutlet UISlider * slider;
@property (nonatomic, retain) IBOutlet UIProgressView * progress;
@property (nonatomic, retain) IBOutlet UIButton * playButton;
@property (nonatomic, retain) IBOutlet UILabel * playTime;
@property (nonatomic, retain) IBOutlet UILabel * remainTime;

- (IBAction)onPlayButton:(id)sender;

@end
