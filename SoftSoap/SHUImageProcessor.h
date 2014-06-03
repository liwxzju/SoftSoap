//
//  SHUImageProcessor.h
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-21.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UIImage+ImageProcessorHelper.h"

#define __CONTOURS__          @"Contours"
#define __AVERANGEGRAY__      @"averangeGray"
#define __WHITEPOINTPRECENT__ @"whitePointsPrencent"

@interface SHUImageProcessor : NSObject

@property (strong, nonatomic) UIImage *srcImage;
@property (strong, nonatomic) UIImage *grayImage;
@property (strong, nonatomic) UIImage *binaryImage;
@property (strong, nonatomic) UIImage *cannyImage;

@property (assign, nonatomic) NSUInteger threholdValue;

// 轮廓数目
@property (assign, nonatomic) NSUInteger Contours;
// 平均灰度
@property (assign, nonatomic) CGFloat averangeGray;
// 二值化后白占比 (检测油性皮肤)
@property (assign, nonatomic) CGFloat whitePointsPrecent;

// 返回检查评估结果
@property (strong, nonatomic) NSDictionary *resultDictionary;

- (instancetype)initWithSrcImage:(UIImage *)image;

- (NSDictionary *)estimateImage;

- (void)drawContoursWithThreholdValue:(NSUInteger)threholdValue;

@end
