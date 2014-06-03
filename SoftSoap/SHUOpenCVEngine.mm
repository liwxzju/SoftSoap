//
//  SHUOpenCVEngine.m
//  UrineCheck
//
//  Created by 王澍宇 on 14-4-25.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import "SHUOpenCVEngine.h"
#include "opencv2/core/core_c.h"
#include "opencv2/imgproc/imgproc_c.h"
#include "opencv2/highgui/highgui_c.h"


@interface SHUOpenCVEngine ()

@end

@implementation SHUOpenCVEngine

const char *pstrWindowsBinaryTitle = "二值图(http://blog.csdn.net/MoreWindows)";
const char *pstrWindowsOutLineTitle = "轮廓图(http://blog.csdn.net/MoreWindows)";

IplImage *g_pGrayImage = NULL;

CvSeq *g_pcvSeq = NULL;

- (UIImage *)soloveUrine:(UIImage *)urinePic withThresholdPos:(float)pos;
{
    // 从文件中加载原图
    IplImage *pSrcImage = [self convertToIplImage:urinePic];
    
    // 转为灰度图
    g_pGrayImage =  cvCreateImage(cvGetSize(pSrcImage), IPL_DEPTH_8U, 1);
    cvCvtColor(pSrcImage, g_pGrayImage, CV_BGR2GRAY);
    
    // 形态学操作
    cvDilate(g_pGrayImage, g_pGrayImage, NULL, 1);
    cvErode(g_pGrayImage, g_pGrayImage, NULL, 1);
    
    // 转为二值图
    
    int position = (int)(pos * 254);
    
    IplImage *pBinaryImage = cvCreateImage(cvGetSize(g_pGrayImage), IPL_DEPTH_8U, 1);
    cvThreshold(g_pGrayImage, pBinaryImage, position, 255, CV_THRESH_BINARY);
    
    CvMemStorage* cvMStorage = cvCreateMemStorage(0);
    // 检索轮廓并返回检测到的轮廓的个数
    cvFindContours(pBinaryImage,cvMStorage, &g_pcvSeq, sizeof(CvContour),CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0));
    
    IplImage *pOutlineImage = cvCreateImage(cvGetSize(g_pGrayImage), IPL_DEPTH_8U, 3);
    int _levels = 5;
    cvZero(pOutlineImage);
    cvDrawContours(pOutlineImage, g_pcvSeq, CV_RGB(255,0,0), CV_RGB(0,255,0), _levels ,1, 8 ,cvPoint(0,0));
    
    // 计算轮廓面积
    
    // self.countourArea = cvContourArea(g_pcvSeq);
    
    // 存储二值图
    
    self.solvedPic = [self convertToUIImage:pOutlineImage];
    
    // 寻找红色外轮廓并通过下偏移找到目标颜色
    int breakFlag = 0;
    float R,G,B;
    
    for(int i=0;i<pOutlineImage->height;i++){
        
        if (breakFlag == 1) {
            break;
        }
        
        for(int j=0;j<pOutlineImage->width;j++){
            R=cvGet2D(pOutlineImage,i,j).val[0];
            G=cvGet2D(pOutlineImage,i,j).val[1];
            B=cvGet2D(pOutlineImage,i,j).val[2];
            
            if (G != 0.0) {
                // 通过向下偏移找到目标颜色，同时排除第一边界情况
                int offset = 30;
                float tR,tG,tB;
                
                if (j + offset <= pSrcImage->height && i + offset <= pSrcImage->width) {
                    tR=cvGet2D(pSrcImage,i,j + offset).val[0];
                    tG=cvGet2D(pSrcImage,i,j + offset).val[1];
                    tB=cvGet2D(pSrcImage,i,j + offset).val[2];
                }else{
                    tR=cvGet2D(pSrcImage,i,j).val[0];
                    tG=cvGet2D(pSrcImage,i,j).val[1];
                    tB=cvGet2D(pSrcImage,i,j).val[2];
                }
                
                
                self.targetColors = @[@(tB),
                                      @(tG),
                                      @(tR)];
                
                NSLog(@"%@",self.targetColors);
                
                breakFlag = 1;
                break;
            }
        }
    }
    
    cvReleaseMemStorage(&cvMStorage);
    cvReleaseImage(&pBinaryImage);
    cvReleaseImage(&pOutlineImage);
    
    cvReleaseImage(&pSrcImage);
    cvReleaseImage(&g_pGrayImage);
    
    return _solvedPic;
}

- (CGContextRef) createARGBBitmapContextFromImage:(CGImageRef) inImage {
    
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    NSInteger             bitmapByteCount;
    NSInteger             bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (pixelsWide * 4);
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color spacen");
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedFirst);
    if (context == NULL)
    {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
    }
    // Make sure and release colorspace before returning
    CGColorSpaceRelease( colorSpace );
    
    return context;
}

#pragma mark -
#pragma mark OpenCV Support Methods

// 把UIImage类型转换成IplImage类型.
// NOTE you SHOULD cvReleaseImage() for the return value when end of the code.
- (IplImage *)convertToIplImage:(UIImage *)image {
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    IplImage *iplimage = cvCreateImage(cvSize(image.size.width, image.size.height),
                                       IPL_DEPTH_8U, 4);
    CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData,
                                                    iplimage->width,
                                                    iplimage->height,
                                                    iplimage->depth,
                                                    iplimage->widthStep,
                                                    colorSpace,
                                                    kCGImageAlphaPremultipliedLast |
                                                    kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGB2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}

// 把IplImage类型转换成UIImage类型.
// NOTE You should convert color mode as RGB before passing to this function.
- (UIImage *)convertToUIImage:(IplImage *)image {
//    NSLog(@"IplImage (%d, %d) %d bits by %d channels, %d bytes/row %s",
//          image->width,
//          image->height,
//          image->depth,
//          image->nChannels,
//          image->widthStep,
//          image->channelSeq);
    cvCvtColor(image, image, CV_BGR2RGB);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(image->width,
                                        image->height,
                                        image->depth,
                                        image->depth * image->nChannels,
                                        image->widthStep,
                                        colorSpace,
                                        kCGImageAlphaNone |
                                        kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault);
    
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return ret;
}

@end
