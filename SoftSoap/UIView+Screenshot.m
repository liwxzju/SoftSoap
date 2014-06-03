//
//  UIView+Screenshot.m
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-24.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import "UIView+Screenshot.h"

@implementation UIView (Screenshot)

-(UIImage *)convertViewToImage
{
    UIGraphicsBeginImageContext(self.bounds.size);
    
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

@end
