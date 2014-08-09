//
//  DZPlayViewController.m
//  mypodcast
//
//  Created by Richard Dong on 14-7-31.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZPlayViewController.h"
#import "DZCache.h"
#import "DZAudioPlayer.h"

@interface DZPlayViewController ()
{
    DZAudioPlayer * _player;
}

@end

@implementation DZPlayViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    DZAudioPlayer * player = [[DZAudioPlayer alloc]init];
    player.bufferProgress = self.progress;
    player.playSlider = self.slider;
    player.playTime = self.playTime;
    player.remainTime = self.remainTime;
    player.audioDuration = 370;
    [player playStreamWithURL:@"http://richarddzh.github.io/podcast/demo.mp3"];
    self->_player = player;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)onPlayButton:(id)sender
{
    
}

@end
