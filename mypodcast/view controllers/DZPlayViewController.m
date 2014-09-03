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
#import "NSString+DZFormatter.h"
#import "UIButton+DZImagePool.h"

@interface DZPlayViewController ()
{
    DZAudioPlayer * _player;
    BOOL _isDraggingSlider;
    NSString * _playButtonName;
}
- (void)showAlbumArtImage;
- (void)showPlayingStatus;
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
    [[DZEventCenter sharedInstance]addHandler:self forEventID:DZEventID_PlayerDidFinishPlaying];
    [[DZEventCenter sharedInstance]addHandler:self forEventID:DZEventID_PlayerIsPlaying];
    [[DZEventCenter sharedInstance]addHandler:self forEventID:DZEventID_PlayerWillStartPlaying];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[DZEventCenter sharedInstance]removeHandler:self forEventID:DZEventID_PlayerDidFinishPlaying];
    [[DZEventCenter sharedInstance]removeHandler:self forEventID:DZEventID_PlayerIsPlaying];
    [[DZEventCenter sharedInstance]removeHandler:self forEventID:DZEventID_PlayerWillStartPlaying];
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

- (void)handleEventWithID:(NSInteger)eID userInfo:(id)userInfo fromSource:(id)source
{
    switch (eID) {
        case DZEventID_PlayerIsPlaying:
            [self showPlayingStatus];
            [self setPlayButtonImageWithName:nil];
            break;
        case DZEventID_PlayerWillStartPlaying:
            [self showAlbumArtImage];
            [self showPlayingStatus];
            [self setPlayButtonImageWithName:@"pause"];
            break;
        case DZEventID_PlayerDidFinishPlaying:
            [self setPlayButtonImageWithName:@"play"];
            break;
        default:
            break;
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
            self.playTimeLabel.text = [NSString stringFromTime:playtime];
            self.remainTimeLabel.text = [NSString stringFromTime:playtime - duration];
        }
    }
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
        [self.playButton setImageWithName:[name stringByAppendingString:@"-button"]];
    }
}

@end
