//
//  SHUScanViewController.h
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-24.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CSAnimationView.h>
#import <MKNetworkKit.h>

@interface SHUScanViewController : UIViewController

@property (strong, nonatomic) UIImage *capturedImage;
@property (strong, nonatomic) NSString *parentID;
@property (strong, nonatomic) NSArray *data;

@end
