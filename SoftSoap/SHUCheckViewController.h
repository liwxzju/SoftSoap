//
//  SHUCheckViewController.h
//  UrineCheck
//
//  Created by 王澍宇 on 14-4-25.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface SHUCheckViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *picView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *checkButton;

@property (strong, nonatomic) UIImage *picNeedSolving;

@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) UIImage *selectedPhoto;

@end
