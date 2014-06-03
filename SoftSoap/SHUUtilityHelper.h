//
//  SHUUtilityHelper.h
//  ARCS
//
//  Created by 王澍宇 on 14-5-18.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>

@interface SHUUtilityHelper : NSObject

+ (IplImage *)CreateIplImageFromUIImage:(UIImage *)image;
+ (UIImage *)UIImageFromIplImage:(IplImage *)image grayImg:(BOOL)bIsGrayImg;
+ (CvHistogram *)get4ChannelHist:(IplImage *)image;
+ (CvHistogram *)getHSVHist:(IplImage *)image;

@end
