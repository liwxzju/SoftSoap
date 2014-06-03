//
//  SHUTestViewController.m
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-21.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import "SHUTestViewController.h"
#import "SHUImageProcessor.h"

@interface SHUTestViewController ()

@property (strong, nonatomic) SHUImageProcessor *imageProcessor;

@end

@implementation SHUTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    NSString *urlStr = @"http://www.weather.com.cn/data/sk/101281601.html";
//    
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    
//    [manager GET:urlStr parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"JSON: %@", responseObject);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"Error: %@", error);
//    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)calculate:(id)sender {
    
    _imageProcessor = [[SHUImageProcessor alloc] initWithSrcImage:_testImageView.image];

    _grayImageView.image = _imageProcessor.grayImage;
    _binaryImageView.image = _imageProcessor.binaryImage;
    _cannyImageview.image = _imageProcessor.cannyImage;
}

- (IBAction)calculationDone:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
