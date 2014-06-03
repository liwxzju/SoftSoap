//
//  UIImage+ImageProcessorHelper.h
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-22.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import <UIKit/UIKit.h>

// 该函数用于角度到弧度的转换

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

@interface UIImage (ImageProcessorHelper)

// 该方法将图片旋转给定角度
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
// 截取部分图像
- (UIImage*)getSubImage:(CGRect)rect;
// 等比例缩放
- (UIImage*)scaleToSize:(CGSize)size;

// 修正方向
+ (UIImage *)fixOrientation:(UIImage *)aImage;
@end
