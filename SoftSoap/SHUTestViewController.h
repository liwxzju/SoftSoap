//
//  SHUTestViewController.h
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-21.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHUTestViewController : UIViewController

@property (strong, nonatomic) UIImage *testImage;

@property (strong, nonatomic) IBOutlet UIImageView *testImageView;
@property (strong, nonatomic) IBOutlet UIImageView *grayImageView;
@property (strong, nonatomic) IBOutlet UIImageView *binaryImageView;
@property (strong, nonatomic) IBOutlet UIImageView *cannyImageview;

@property (strong, nonatomic) IBOutlet UILabel *testLabel;

@end
