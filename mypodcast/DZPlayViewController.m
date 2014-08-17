//
//  DZPlayViewController.m
//  mypodcast
//
//  Created by Richard Dong on 14-7-31.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZPlayViewController.h"
#import "DZAudioPlayer.h"
#import "DZItem.h"
#import "DZCache.h"
#import "DZChannel.h"

@interface DZPlayViewController ()
{
    DZAudioPlayer * _player;
    DZItem * _feedItem;
}
- (void)playFeedItem;
@end

@implementation DZPlayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSLog(@"Load play view");
    if (self->_player == nil) {
        DZAudioPlayer * player = [[DZAudioPlayer alloc]init];
        player.bufferProgressView = self.progressView;
        player.playSlider = self.slider;
        player.playTimeLabel = self.playTimeLabel;
        player.remainTimeLabel = self.remainTimeLabel;
        player.playButton = self.playButton;
        self->_player = player;
    }
    if (self->_feedItem != nil) {
        [self playFeedItem];
    }
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

- (IBAction)onPlayButton:(id)sender
{
    [self->_player playPause];
}

- (IBAction)onSliderBeginDrag:(id)sender
{
    self->_player.isDraggingSlider = YES;
}

- (IBAction)onSliderChangeValue:(id)sender
{
    self->_player.isDraggingSlider = NO;
    [self->_player seekTo:self->_player.audioDuration * self.slider.value];
}

- (DZItem *)feedItem
{
    return self->_feedItem;
}

- (void)setFeedItem:(DZItem *)feedItem
{
    if (self->_feedItem != feedItem) {
        self->_feedItem = feedItem;
        if (feedItem != nil) {
            [self playFeedItem];
        }
    }
}

- (void)playFeedItem
{
    DZItem * feedItem = self->_feedItem;
    if (self->_player != nil && feedItem != nil) {
        self.title = feedItem.title;
        DZCache * cache = [DZCache sharedInstance];
        [cache getDataWithURL:[NSURL URLWithString:feedItem.channel.image] shallDownload:YES dataHandler:^(NSData * data, NSError * error) {
            if (data != nil && error == nil) {
                self.imageView.image = [UIImage imageWithData:data];
            }
        }];
        self->_player.audioDuration = [feedItem.duration doubleValue];
        [self->_player prepareForURL:feedItem.url];
        [self->_player playPause];
    }
}

@end
