//
//  DZFeaturedViewController.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-18.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZFeaturedViewController.h"
#import "DZFeedViewController.h"
#import "DZDatabase.h"

@interface DZFeaturedViewController ()

@end

@implementation DZFeaturedViewController

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
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://richarddzh.github.io/podcast/demo.html"]]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"DZSegueChannel"]) {
        NSString * urlStr = sender;
        DZChannel * channel = [[DZDatabase sharedInstance]channelWithURL:urlStr];
        DZFeedViewController * vc = segue.destinationViewController;
        vc.feedChannel = channel;
        [vc beginRefresh];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.scheme.lowercaseString isEqualToString:@"dz"]) {
        NSString * urlStr = request.URL.absoluteString;
        urlStr = [NSString stringWithFormat:@"http%@", [urlStr substringFromIndex:2]];
        [self performSegueWithIdentifier:@"DZSegueChannel" sender:urlStr];
        return NO;
    }
    return YES;
}

@end
