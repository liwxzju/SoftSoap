//
//  SHUContentViewController.m
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-25.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import "SHUContentViewController.h"

@interface SHUContentViewController ()

@end

@implementation SHUContentViewController

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
    
    NSURLRequest *request =[NSURLRequest requestWithURL:[NSURL URLWithString:_url]];
    
    _bgImageView.image = _bgImage;
    [_productWebView loadRequest:request];
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
- (IBAction)pushBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)closeView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
