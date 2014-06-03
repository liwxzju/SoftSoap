//
//  SHUCemeraViewController.h
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-21.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>


@interface AVCemeraViewController : UIViewController <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) IBOutlet UIView *previewView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *camerasControl;

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutPut;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;

@property (assign, nonatomic) BOOL detectFaces;
@property (assign, nonatomic) BOOL isUsingFrontFacingCamera;

@property (assign, nonatomic) CGFloat beginGestureScale;
@property (assign, nonatomic) CGFloat effectiveScale;

@property (strong, nonatomic) dispatch_queue_t videoDataOutputQueue;

@property (strong, nonatomic) UIView *flashView;
@property (strong, nonatomic) UIImage *square;

@property (strong, nonatomic) CIDetector *faceDetector;

@property (strong, nonatomic) UIImage *takedImage;

- (IBAction)takePicture:(id)sender;
- (IBAction)switchCameras:(id)sender;
- (IBAction)handlePinchGesture:(UIGestureRecognizer *)sender;
- (IBAction)toggleFaceDetection:(id)sender;

@end
