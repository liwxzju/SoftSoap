//
//  SHUDetailViewController.h
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-21.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHUDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
