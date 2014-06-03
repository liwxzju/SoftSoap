//
//  SHUScanViewController.m
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-24.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import "SHUScanViewController.h"
#import "SHUTableViewController.h"
#import "HYCircleLoadingView.h"
#import "SHUImageProcessor.h"
#import "ANBlurredImageView.h"

#define SERVER_URL  @"oj.sssta.co:8080"
#define API_URL(__C__, __AG__,__WPC__) [NSString stringWithFormat:@"?Contours=%@&averangeGray=%@&whitePointsCount=%@", __C__, __AG__,__WPC__]

@interface SHUScanViewController ()

@property (strong, nonatomic) SHUImageProcessor *imageProcessor;

@property (strong, nonatomic) IBOutlet UIImageView *scanImageView;
@property (strong, nonatomic) IBOutlet HYCircleLoadingView *loadingView;
@property (strong, nonatomic) IBOutlet CSAnimationView *AnimationView;

@property (strong, nonatomic) IBOutlet UILabel *recommandedName;
@property (strong, nonatomic) IBOutlet UIImageView *recommanedImage;
@property (strong, nonatomic) IBOutlet UILabel *stateInfo;


@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) NSDictionary *scanResult;
@property (strong, nonatomic) NSDictionary *recommandResult;

@property (strong, nonatomic) NSArray *bgArray;


@end

@implementation SHUScanViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _bgArray = @[[UIImage imageNamed:@"bg1"],
                 [UIImage imageNamed:@"bg2"],
                 [UIImage imageNamed:@"bg3"],
                 [UIImage imageNamed:@"bg4"]];
    

    
    NSInteger index = arc4random() % 4;
    
    _scanImageView.image = _bgArray[index];
    
    _imageProcessor = [[SHUImageProcessor alloc] initWithSrcImage:_capturedImage];
    
    _scanResult = [_imageProcessor estimateImage];
    
    [self getRecommendation];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NetWork Method

- (void)getRecommendation
{
    [_loadingView startAnimation];
    
    MKNetworkEngine *engine = [[MKNetworkEngine alloc] initWithHostName:SERVER_URL];
    
    MKNetworkOperation *op = [engine operationWithPath:API_URL(_scanResult[__CONTOURS__],
                                                               _scanResult[__AVERANGEGRAY__],
                                                               _scanResult[__WHITEPOINTPRECENT__]) params:nil httpMethod:@"GET"];
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation){
    
        _recommandResult = [completedOperation responseJSON];
        [self.AnimationView startCanvasAnimation];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingView stopAnimation];
            _stateInfo.text = @"";
            _recommanedImage.image = [UIImage imageNamed:@"8.jpg"];
        });
        
    }errorHandler:^(MKNetworkOperation *completedOperation, NSError *error){
        NSLog(@"%@",error);
    }];
    
    [engine enqueueOperation:op];
}

#pragma mark - Animation Method

- (void)animateView
{
    _AnimationView.type = CSAnimationTypeBounceUp;
    _AnimationView.delay = 0.8f;
    _AnimationView.duration = 2.0f;
    
    [_AnimationView startCanvasAnimation];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segueToLast"]) {
        UINavigationController *navController = segue.destinationViewController;
        SHUTableViewController *tableViewController = navController.viewControllers[0];
        tableViewController.bgImage = _scanImageView.image;
        
        tableViewController.data = _recommandResult[@"recommends"];
    }
}

- (IBAction)closeView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)pushBack:(id)sender {
    if ([_parentID isEqualToString:@"CamViewController"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
