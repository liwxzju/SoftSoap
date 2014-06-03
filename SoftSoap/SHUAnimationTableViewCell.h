//
//  SHUAnimationTableViewCell.h
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-25.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CSAnimationView.h>

@interface SHUAnimationTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet CSAnimationView *animationView;

@property (strong, nonatomic) IBOutlet UILabel *contentNameLabel;

@property (strong, nonatomic) IBOutlet UIImageView *bgImageView;


@property (strong, nonatomic) NSString *url;

@end
