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
}
- (void)showAlbumArtImage;
- (void)showPlayingStatus;
@end

@implementation DZPlayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self->_isDraggingSlider = NO;
    self->_player = [DZAudioPlayer sharedInstance];
    [self showAlbumArtImage];
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
    } else if (info == kDZPlayerWillStartPlaying) {
        [self showAlbumArtImage];
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
}

@end
