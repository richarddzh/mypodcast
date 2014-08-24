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
#import "DZFileStream.h"

@interface DZPlayViewController ()
{
    DZAudioPlayer * _player;
    BOOL _isDraggingSlider;
    NSString * _playButtonName;
}
- (void)showAlbumArtImage;
- (void)showPlayingStatus;
- (NSString *)stringFromTime:(NSTimeInterval)time;
- (void)setPlayButtonImageWithName:(NSString *)name;
@end

@implementation DZPlayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.playTimeLabel.text = @"00:00";
    self.remainTimeLabel.text = @"00:00";
    self.slider.value = 0;
    self->_isDraggingSlider = NO;
    self->_player = [DZAudioPlayer sharedInstance];
    [self showAlbumArtImage];
    self->_playButtonName = nil;
    [self setPlayButtonImageWithName:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self->_player addEventTarget:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self->_player removeEventTarget:self];
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
    self->_isDraggingSlider = YES;
}

- (IBAction)onSliderChangeValue:(id)sender
{
    self->_isDraggingSlider = NO;
    [self->_player seekTo:[self->_player.feedItem.duration doubleValue] * self.slider.value];
}

- (void)handleEvent:(DZEvent *)event
{
    NSString * info = event.userInfo;
    if (info == kDZPlayerIsPlaying) {
        [self showPlayingStatus];
        [self setPlayButtonImageWithName:nil];
    } else if (info == kDZPlayerWillStartPlaying) {
        [self showAlbumArtImage];
        [self showPlayingStatus];
        [self setPlayButtonImageWithName:@"pause"];
    } else if (info == kDZPlayerDidFinishPlaying) {
        [self setPlayButtonImageWithName:@"play"];
    }
}

- (void)showAlbumArtImage
{
    DZItem * feedItem = self->_player.feedItem;
    if (self->_player != nil && feedItem != nil) {
        self.title = feedItem.title;
        DZCache * cache = [DZCache sharedInstance];
        [cache getDataWithURL:[NSURL URLWithString:feedItem.channel.image] shallDownload:YES dataHandler:^(NSData * data, NSError * error) {
            if (data != nil && error == nil) {
                self.imageView.image = [UIImage imageWithData:data];
            }
        }];
    }
}

- (void)showPlayingStatus
{
    DZItem * feedItem = self->_player.feedItem;
    if (self->_player == nil || feedItem == nil) {
        return;
    }
    self.progressView.progress = [self->_player downloadBufferProgress];
    if (self->_isDraggingSlider == NO) {
        if (self->_player.feedItem.duration != nil && [self->_player.feedItem.duration doubleValue] > 0) {
            NSTimeInterval duration = [self->_player.feedItem.duration doubleValue];
            NSTimeInterval playtime = [self->_player currentTime];
            self.slider.value = playtime / duration;
            self.playTimeLabel.text = [self stringFromTime:playtime];
            self.remainTimeLabel.text = [self stringFromTime:playtime - duration];
        }
    }
}

- (NSString *)stringFromTime:(NSTimeInterval)time
{
    int itime = round(time);
    return [NSString stringWithFormat:@"%@%02u:%02u",
            (itime >= 0 ? @"" : @"-"),
            abs(itime) / 60,
            abs(itime) % 60];
}

- (void)setPlayButtonImageWithName:(NSString *)name
{
    if ([@"play" compare:name] != NSOrderedSame && [@"pause" compare:name] != NSOrderedSame) {
        DZPlayerStatus status = [self->_player status];
        if (status == DZPlayerStatus_Stop || status == DZPlayerStatus_UserPause) {
            name = @"play";
        } else {
            name = @"pause";
        }
    }
    if ([name compare:self->_playButtonName] != NSOrderedSame) {
        self->_playButtonName = name;
        [self.playButton setImage:[[UIImage imageNamed:[name stringByAppendingString:@"-button"]]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.playButton setImage:[[UIImage imageNamed:[name stringByAppendingString:@"-button-highlight"]]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    }
}

@end
