//
//  SHUCameraViewController.m
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-24.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import "SHUCameraViewController.h"
#import "SHUScanViewController.h"
#import "BLRView.h"

#define kButtonMoveAnimation @"ButtonMoveAnimation"

@interface SHUCameraViewController () <SimpleCamDelegate>

@property (strong, nonatomic) IBOutlet UIView *overlayView;
@property (strong, nonatomic) IBOutlet UIButton *takePhotoButton;

@property (strong, nonatomic) UIImage *capturedImage;

- (IBAction)selectPhoto:(id)sender;
- (IBAction)takePhoto:(id)sender;

@end

@implementation SHUCameraViewController

- (void)loadView
{
    [super loadView];
    
    self.hideAllControls = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.delegate = self;
    
    [self.view addSubview:_overlayView];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selectPhoto:(id)sender {
    
}

- (IBAction)takePhoto:(id)sender {
    [self capturePhoto];
    [self performSegueWithIdentifier:@"segueToScan" sender:self];
}

#pragma mark - SimpleCamera Delegate Method

- (void)simpleCam:(SHUSimpleCamController *)simpleCam didFinishWithImage:(UIImage *)image
{
    _capturedImage = image;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    SHUScanViewController *scanViewController = segue.destinationViewController;
    scanViewController.capturedImage = self.capturedImage;
}


@end
