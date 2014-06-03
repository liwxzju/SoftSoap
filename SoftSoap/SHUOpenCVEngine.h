//
//  SHUOpenCVEngine.h
//  UrineCheck
//
//  Created by 王澍宇 on 14-4-25.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SHUOpenCVEngine : NSObject

@property (strong, nonatomic) UIImage *solvedPic;
@property (strong, nonatomic) NSArray *targetColors;

- (UIImage *)soloveUrine:(UIImage *)urinePic withThresholdPos:(float)pos;

@end
