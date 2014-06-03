//
//  SHUContentViewController.h
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-25.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHUContentViewController : UIViewController

@property (strong, nonatomic) UIImage *bgImage;
@property (strong, nonatomic) IBOutlet UIImageView *bgImageView;
@property (strong, nonatomic) IBOutlet UIWebView *productWebView;
@property (strong, nonatomic) NSString *url;

@end
