//
//  SHUImageProcessor.m
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-21.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import "SHUImageProcessor.h"
#import "SHUUtilityHelper.h"

@interface SHUImageProcessor ()

// 原图、灰度图、二值图 （后单通道）、轮廓图
@property (nonatomic) IplImage *iplSrcImage;
@property (nonatomic) IplImage *iplGrayImage;
@property (nonatomic) IplImage *iplBinaryImage;
@property (nonatomic) IplImage *iplCannyImage;
// 存储序列
@property (nonatomic) CvSeq *Seq;
@property (nonatomic) CvMemStorage *memoryStore;
// 人脸识别库
@property (strong, nonatomic) CIDetector *faceDetector;
@property (strong, nonatomic) NSArray *faceFetures;

@end

@implementation SHUImageProcessor

- (instancetype)initWithSrcImage:(UIImage *)image
{
    if (self = [super init]) {
        
        // 初始化原图，检测人脸
        
        NSDictionary *detectorOptions = @{CIDetectorAccuracy: CIDetectorAccuracyHigh};
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
        _faceFetures = [_faceDetector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        
        UIImage *faceImage = nil;
        
        if (_faceFetures.count != 0) {
            faceImage = [image getSubImage:[(CIFaceFeature *)_faceFetures[0] bounds]];
        }else{
            faceImage = image;
        }
        
        self.srcImage = [faceImage copy];
        self.iplSrcImage = [SHUUtilityHelper CreateIplImageFromUIImage:faceImage];
        
        [self setupConfigurations];
    }
    return self;
}

- (void)dealloc
{
    cvReleaseImage(&_iplSrcImage);
    cvReleaseImage(&_iplGrayImage);
    cvReleaseImage(&_iplBinaryImage);
    cvReleaseImage(&_iplCannyImage);
    
    cvReleaseMemStorage(&_memoryStore);
}

#pragma mark - OpenCV Processor Method

- (void)setupConfigurations
{
    // 初始化灰度图
    self.iplGrayImage = cvCreateImage(cvGetSize(_iplSrcImage), IPL_DEPTH_8U, 1);
    cvCvtColor(_iplSrcImage, _iplGrayImage, CV_BGR2GRAY);
    
    // 计算灰度平均值
    [self calculateAverageWithGrayImage:_iplGrayImage];
    
    // 初始化二值图，获得灰度图拷贝，一次膨胀腐蚀，二值化
    _iplBinaryImage = cvCreateImage(cvGetSize(_iplGrayImage), IPL_DEPTH_8U, 1);
    
    cvCopy(_iplGrayImage, _iplBinaryImage);
    
    //平滑处理灰度图
    cvSmooth(_iplGrayImage, _iplGrayImage, CV_GAUSSIAN,3,1,0);
    
    // 形态学操作
    cvDilate(_iplBinaryImage, _iplBinaryImage, NULL, 1);
    cvErode(_iplBinaryImage, _iplBinaryImage, NULL, 1);
    
    // 初始化阈值
    _threholdValue = 100;
    
    cvThreshold(_iplBinaryImage, _iplBinaryImage, _threholdValue, 255, CV_THRESH_BINARY);
    
    [self calculateWhitePointsWithBinaryImage:_iplBinaryImage];
    
    // 初始化Canny处理
    _memoryStore = cvCreateMemStorage(0);
    _iplCannyImage = cvCreateImage(cvGetSize(_iplBinaryImage), IPL_DEPTH_8U, 3);
    [self drawContoursWithThreholdValue:160];
    
    // 保留三图的UIImage
    self.grayImage = [SHUUtilityHelper UIImageFromIplImage:_iplGrayImage grayImg:YES];
    self.binaryImage = [SHUUtilityHelper UIImageFromIplImage:_iplBinaryImage grayImg:YES];
    
}

- (NSDictionary *)estimateImage
{
    _resultDictionary = @{__CONTOURS__          : @(_Contours),
                          __AVERANGEGRAY__      : @(_averangeGray),
                          __WHITEPOINTPRECENT__ : @(_whitePointsPrecent)};
    
    return self.resultDictionary;
}

// 计算灰度图像素平均值
- (void)calculateAverageWithGrayImage:(IplImage *)grayImage
{
    CvScalar aScalar = cvAvg(_iplGrayImage, NULL);
    _averangeGray = aScalar.val[0];
}

// 计算二值图白点个数
- (void)calculateWhitePointsWithBinaryImage:(IplImage *)binaryImage
{
    _whitePointsPrecent = (CGFloat)cvCountNonZero(binaryImage) / (binaryImage->height * binaryImage->width);
}

// Canny阈值描边
- (void)drawContoursWithThreholdValue:(NSUInteger)threholdValue
{
    _threholdValue = threholdValue;
    
    IplImage *iplCopyBianaryImage = cvCreateImage(cvGetSize(_iplGrayImage), IPL_DEPTH_8U, 1);
    
    cvCopy(_iplGrayImage, iplCopyBianaryImage);
    
    cvThreshold(iplCopyBianaryImage,
                iplCopyBianaryImage,
                _threholdValue,
                255,
                CV_THRESH_BINARY);
    
    cvZero(_iplCannyImage);
    _Contours = cvFindContours(iplCopyBianaryImage,
                               _memoryStore,
                               &(_Seq),
                               sizeof(CvContour),
                               CV_RETR_LIST,
                               CV_CHAIN_APPROX_SIMPLE,
                               cvPoint(0,0));
    
    cvDrawContours(_iplCannyImage,
                   _Seq,
                   CV_RGB(255,0,0),
                   CV_RGB(0,255,0),
                   5 ,1, 8 ,
                   cvPoint(0,0));
    
    self.cannyImage = [SHUUtilityHelper UIImageFromIplImage:_iplCannyImage
                                                    grayImg:NO];
}


#pragma mark - UIImage Helper Method

// 帮助方法，将UIImage转成320宽分辨率
- (UIImage *)resizeSelectedImage:(UIImage *)image
{
    CGFloat fSmallImgWidth = 320.0f;
    
    BOOL bIsRotate = NO;
    switch (image.imageOrientation)
    {
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
        {
            bIsRotate = NO;
            //            NSLog(@"UP [%d]", image.imageOrientation);
        }
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
        {
            bIsRotate = YES;
            //            NSLog(@"LEFT [%d]", image.imageOrientation);
        }
            break;
        default:
            break;
    }
    
    CGRect rcSubRect;
    rcSubRect.origin.x = !bIsRotate ? image.size.width/8 : image.size.height/8;
    rcSubRect.origin.y = !bIsRotate ? image.size.height/8 : image.size.width/8;
    rcSubRect.size.width = !bIsRotate ? (image.size.width - image.size.width/4) : (image.size.height - image.size.height/4);
    rcSubRect.size.height = !bIsRotate ? (image.size.height - image.size.height/4) : (image.size.width - image.size.width/4);
    
    CGImageRef subImageRef = CGImageCreateWithImageInRect(image.CGImage, rcSubRect);
    CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
    
    UIGraphicsBeginImageContext(smallBounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallBounds, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef scale:1.0f orientation:image.imageOrientation];
    UIGraphicsEndImageContext();
    
    CGFloat objectWidth = !bIsRotate ? smallBounds.size.width : smallBounds.size.height;
    CGFloat objectHeight = !bIsRotate ? smallBounds.size.height : smallBounds.size.width;
    CGFloat scaledHeight = floorf(objectHeight / (objectWidth / fSmallImgWidth));
    CGSize newSize = CGSizeMake(fSmallImgWidth, scaledHeight);
    UIGraphicsBeginImageContext(newSize);
    // Tell the old image to draw in this new context, with the desired
    // new size
    [smallImage drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    // End the context
    UIGraphicsEndImageContext();
    
    CGImageRelease(subImageRef);
    
    return newImage;
}

@end
