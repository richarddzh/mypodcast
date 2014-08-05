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
#import "DZURLSessionForAudioStream.h"

@interface DZPlayViewController ()

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
    DZCache * cache = [DZCache sharedInstance];
    [cache getAllDataWithURL:@"http://richarddzh.github.io/podcast/demo.jpg"
              shouldDownload:YES
                     handler:^(NSData *data, NSError *error) {
                         if (data != nil && error == nil)
                             self.imageView.image = [UIImage imageWithData:data];
                     }];
    DZAudioPlayer * player = [[DZAudioPlayer alloc]init];
    [player playStreamWithURL:@"http://richarddzh.github.io/podcast/demo.mp3"];
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

@end
