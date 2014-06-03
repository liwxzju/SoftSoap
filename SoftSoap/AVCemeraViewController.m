//
//  SHUCemeraViewController.m
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-21.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import "AVCemeraViewController.h"
#import "UIImage+ImageProcessorHelper.h"

// 通过KVO观察 @"capturingStillImage" 属性来拍摄的触发闪光动画效果
static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";

// 该函数用于释放CVPixelBuffer
static void ReleaseCVPixelBuffer(void *pixel, const void *data, size_t size)
{
	CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)pixel;
	CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
	CVPixelBufferRelease( pixelBuffer );
}

// 巫毒函数：该函数用于以提供的像素缓存预设值创建一个CGImage，像素缓存必须是 kCVPixelFormatType_32ARGB 或者 kCVPixelFormatType_32BGRA
static OSStatus CreateCGImageFromCVPixelBuffer(CVPixelBufferRef pixelBuffer, CGImageRef *imageOut)
{
	OSStatus err = noErr;
	OSType sourcePixelFormat;
	size_t width, height, sourceRowBytes;
	void *sourceBaseAddr = NULL;
	CGBitmapInfo bitmapInfo;
	CGColorSpaceRef colorspace = NULL;
	CGDataProviderRef provider = NULL;
	CGImageRef image = NULL;
	
	sourcePixelFormat = CVPixelBufferGetPixelFormatType( pixelBuffer );
	if ( kCVPixelFormatType_32ARGB == sourcePixelFormat )
		bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipFirst;
	else if ( kCVPixelFormatType_32BGRA == sourcePixelFormat )
		bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
	else
		return -95014; // only uncompressed pixel formats
	
	sourceRowBytes = CVPixelBufferGetBytesPerRow( pixelBuffer );
	width = CVPixelBufferGetWidth( pixelBuffer );
	height = CVPixelBufferGetHeight( pixelBuffer );
	
	CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
	sourceBaseAddr = CVPixelBufferGetBaseAddress( pixelBuffer );
	
	colorspace = CGColorSpaceCreateDeviceRGB();
    
	CVPixelBufferRetain( pixelBuffer );
	provider = CGDataProviderCreateWithData( (void *)pixelBuffer, sourceBaseAddr, sourceRowBytes * height, ReleaseCVPixelBuffer);
	image = CGImageCreate(width, height, 8, 32, sourceRowBytes, colorspace, bitmapInfo, provider, NULL, true, kCGRenderingIntentDefault);
	
bail:
	if ( err && image ) {
		CGImageRelease( image );
		image = NULL;
	}
	if ( provider ) CGDataProviderRelease( provider );
	if ( colorspace ) CGColorSpaceRelease( colorspace );
	*imageOut = image;
	return err;
}

// 巫毒函数：创建位图环境
static CGContextRef CreateCGBitmapContextForSize(CGSize size)
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    int             bitmapBytesPerRow;
	
    bitmapBytesPerRow = (size.width * 4);
	
    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate (NULL,
									 size.width,
									 size.height,
									 8,      // 8位图
									 bitmapBytesPerRow,
									 colorSpace,
									 1);     // 枚举值没有 1
	CGContextSetAllowsAntialiasing(context, NO);
    CGColorSpaceRelease( colorSpace );
    return context;
}

@interface AVCemeraViewController ()

@end

@implementation AVCemeraViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
	[self setupAVCapture];
	_square = [UIImage imageNamed:@"squarePNG"];
	NSDictionary *detectorOptions = @{CIDetectorAccuracy: CIDetectorAccuracyHigh};
	_faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
		_beginGestureScale = _effectiveScale;
	}
	return YES;
}

- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
	BOOL allTouchesAreOnThePreviewLayer = YES;
	NSUInteger numTouches = [recognizer numberOfTouches], i;
	for ( i = 0; i < numTouches; ++i ) {
		CGPoint location = [recognizer locationOfTouch:i inView:_previewView];
		CGPoint convertedLocation = [_previewLayer convertPoint:location fromLayer:_previewLayer.superlayer];
		if ( ! [_previewLayer containsPoint:convertedLocation] ) {
			allTouchesAreOnThePreviewLayer = NO;
			break;
		}
	}
	
	if ( allTouchesAreOnThePreviewLayer ) {
		_effectiveScale = _beginGestureScale * recognizer.scale;
		if (_effectiveScale < 1.0)
			_effectiveScale = 1.0;
		CGFloat maxScaleAndCropFactor = [[_stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
		if (_effectiveScale > maxScaleAndCropFactor)
			_effectiveScale = maxScaleAndCropFactor;
		[CATransaction begin];
		[CATransaction setAnimationDuration:.025];
		[_previewLayer setAffineTransform:CGAffineTransformMakeScale(_effectiveScale, _effectiveScale)];
		[CATransaction commit];
	}
}



#pragma mark - Camera Internal Methods

// 该方法初始化并配置Session
- (void)setupAVCapture
{
	NSError *error = nil;
	
    // 初始化Session
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPreset1280x720;
    
    // 配置视频输入Device与Input
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (!error) {
        _isUsingFrontFacingCamera = NO;
        if ( [session canAddInput:deviceInput] )
            [session addInput:deviceInput];
        
        // 选择静帧图像输出，Output
        _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        
        // 设置简直观察触发动画闪光效果
        [_stillImageOutput addObserver:self
                            forKeyPath:@"capturingStillImage"
                               options:NSKeyValueObservingOptionNew
                               context:(__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext)];
        
        if ( [session canAddOutput:_stillImageOutput] )
            [session addOutput:_stillImageOutput];
        
        _videoDataOutPut = [[AVCaptureVideoDataOutput alloc] init];
        
        // 以 BGRA 色彩空间初始化OutPut预设值, CoreGraphics 与 OpenGL 都支持 'BGRA'
        NSDictionary *rgbOutputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCMPixelFormat_32BGRA)};
        [_videoDataOutPut setVideoSettings:rgbOutputSettings];
        
        // 处理静帧数据时忽略阻塞的数据
        [_videoDataOutPut setAlwaysDiscardsLateVideoFrames:YES];
        
        // 用线性队列保证帧安全被代理方法处理
        _videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        
        [_videoDataOutPut setSampleBufferDelegate:self queue:_videoDataOutputQueue];
        
        if ( [session canAddOutput:_videoDataOutPut] )
            [session addOutput:_videoDataOutPut];
        
        [[_videoDataOutPut connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
        
        // 初始化焦距默认值与相机预览图层
        _effectiveScale = 1.0;
        
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        
        [_previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        
        CALayer *rootLayer = [_previewView layer];
        
        [rootLayer setMasksToBounds:YES];
        
        [_previewLayer setFrame:[rootLayer bounds]];
        
        [rootLayer addSublayer:_previewLayer];
        
        [session startRunning];
        
    }else{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        [self teardownAVCapture];
    }
}

// 清空Catpure设置
- (void)teardownAVCapture
{
	[_stillImageOutput removeObserver:self forKeyPath:@"isCapturingStillImage"];
	[_previewLayer removeFromSuperlayer];
}

// 响应静帧改变触发动画的KVO方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ( context == (__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext) ) {
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		
		if ( isCapturingStillImage ) {
            
            // 灯泡效果动画
            
			_flashView = [[UIView alloc] initWithFrame:[_previewView frame]];
			[_flashView setBackgroundColor:[UIColor whiteColor]];
			[_flashView setAlpha:0.f];
			[self.view.window addSubview:_flashView];
			
			[UIView animateWithDuration:.4f
							 animations:^{
								 [_flashView setAlpha:1.f];
							 }
			 ];
		}
		else {
			[UIView animateWithDuration:.4f
							 animations:^{
								 [_flashView setAlpha:0.f];
							 }
							 completion:^(BOOL finished){
								 [_flashView removeFromSuperview];
								 _flashView = nil;
							 }
			 ];
		}
	}
}

// 动态选择照片抓取方向
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
	AVCaptureVideoOrientation result;
    
    (deviceOrientation == UIDeviceOrientationPortrait) ? (result = AVCaptureVideoOrientationPortrait) : (result = AVCaptureVideoOrientationPortraitUpsideDown);
    
	if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
		result = AVCaptureVideoOrientationLandscapeRight;
	else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
		result = AVCaptureVideoOrientationLandscapeLeft;
    
	return result;
}

// 画脸
- (CGImageRef)newSquareOverlayedImageForFeatures:(NSArray *)features
                                       inCGImage:(CGImageRef)backgroundImage
                                 withOrientation:(UIDeviceOrientation)orientation
                                     frontFacing:(BOOL)isFrontFacing
{
	CGImageRef returnImage = NULL;
	CGRect backgroundImageRect = CGRectMake(0., 0., CGImageGetWidth(backgroundImage), CGImageGetHeight(backgroundImage));
    
    // 初始化位图环境
	CGContextRef bitmapContext = CreateCGBitmapContextForSize(backgroundImageRect.size);
	CGContextClearRect(bitmapContext, backgroundImageRect);
    
	CGContextDrawImage(bitmapContext, backgroundImageRect, backgroundImage);
	CGFloat rotationDegrees = 0.;
	
	switch (orientation) {
		case UIDeviceOrientationPortrait:
			rotationDegrees = -90.;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			rotationDegrees = 90.;
			break;
		case UIDeviceOrientationLandscapeLeft:
			if (isFrontFacing) rotationDegrees = 180.;
			else rotationDegrees = 0.;
			break;
		case UIDeviceOrientationLandscapeRight:
			if (isFrontFacing) rotationDegrees = 0.;
			else rotationDegrees = 180.;
			break;
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
		default:
			break; 
	}
    
	UIImage *rotatedSquareImage = [_square imageRotatedByDegrees:rotationDegrees];
	
    // features found by the face detector
	for ( CIFaceFeature *ff in features ) {
		CGRect faceRect = [ff bounds];
		CGContextDrawImage(bitmapContext, faceRect, [rotatedSquareImage CGImage]);
	}
	returnImage = CGBitmapContextCreateImage(bitmapContext);
	CGContextRelease (bitmapContext);
	
	return returnImage;
}

- (BOOL)writeCGImageToCameraRoll:(CGImageRef)cgImage withMetadata:(NSDictionary *)metadata
{
	CFMutableDataRef destinationData = CFDataCreateMutable(kCFAllocatorDefault, 0);
	CGImageDestinationRef destination = CGImageDestinationCreateWithData(destinationData,
																		 CFSTR("public.jpeg"),
																		 1,
																		 NULL);
	BOOL success = (destination != NULL);
    
    if (success) {
        const float JPEGCompQuality = 0.85f; // JPEGHigherQuality
        CFMutableDictionaryRef optionsDict = NULL;
        CFNumberRef qualityNum = NULL;
        
        qualityNum = CFNumberCreate(0, kCFNumberFloatType, &JPEGCompQuality);
        if ( qualityNum ) {
            optionsDict = CFDictionaryCreateMutable(0, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            if ( optionsDict )
                CFDictionarySetValue(optionsDict, kCGImageDestinationLossyCompressionQuality, qualityNum);
            CFRelease( qualityNum );
        }
        
        CGImageDestinationAddImage( destination, cgImage, optionsDict );
        success = CGImageDestinationFinalize( destination );
        
        if ( optionsDict )
            CFRelease(optionsDict);
        
        if (success) {
            CFRetain(destinationData);
            ALAssetsLibrary *library = [ALAssetsLibrary new];
            [library writeImageDataToSavedPhotosAlbum:(__bridge id)destinationData metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
                if (destinationData)
                    CFRelease(destinationData);
            }];
        }else{
            if (destinationData)
                CFRelease(destinationData);
            if (destination)
                CFRelease(destination);
        }
    }else{
        if (destinationData)
            CFRelease(destinationData);
        if (destination)
            CFRelease(destination);
    }
	return success;
}

// 处理处理拍照失败
- (void)displayErrorOnMainQueue:(NSError *)error withMessage:(NSString *)message
{
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d)", message, (int)[error code]]
															message:[error localizedDescription]
														   delegate:nil
												  cancelButtonTitle:@"Dismiss"
												  otherButtonTitles:nil];
		[alertView show];
	});
}

// 拍照

- (IBAction)takePicture:(id)sender
{
	// Find out the current orientation and tell the still image output.
	AVCaptureConnection *stillImageConnection = [_stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
	[stillImageConnection setVideoOrientation:avcaptureOrientation];
	[stillImageConnection setVideoScaleAndCropFactor:_effectiveScale];
	
    BOOL doingFaceDetection = _detectFaces && (_effectiveScale == 1.0);
	
    // set the appropriate pixel format / image type output setting depending on if we'll need an uncompressed image for
    // the possiblity of drawing the red square over top or if we're just writing a jpeg to the camera roll which is the trival case
    if (doingFaceDetection)
		[_stillImageOutput setOutputSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCMPixelFormat_32BGRA)}];
	else
		[_stillImageOutput setOutputSettings:@{AVVideoCodecKey: AVVideoCodecJPEG}];
	
	[_stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                  completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                      if (error) {
                                                          [self displayErrorOnMainQueue:error withMessage:@"Take picture failed"];
                                                      }
                                                      else {
                                                          if (doingFaceDetection) {
                                                              // Got an image.
                                                              CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(imageDataSampleBuffer);
                                                              CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
                                                              CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
                                                              if (attachments)
                                                                  CFRelease(attachments);
                                                              
                                                              NSDictionary *imageOptions = nil;
                                                              NSNumber *orientation = (__bridge NSNumber *)(CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyOrientation, NULL));
                                                              if (orientation) {
                                                                  imageOptions = @{CIDetectorImageOrientation: orientation};
                                                              }
                                                              
                                                              // when processing an existing frame we want any new frames to be automatically dropped
                                                              // queueing this block to execute on the videoDataOutputQueue serial queue ensures this
                                                              // see the header doc for setSampleBufferDelegate:queue: for more information
                                                              dispatch_sync(_videoDataOutputQueue, ^(void) {
                                                                  
                                                                  // get the array of CIFeature instances in the given image with a orientation passed in
                                                                  // the detection will be done based on the orientation but the coordinates in the returned features will
                                                                  // still be based on those of the image.
                                                                  
                                                                  // 初始化人脸识别检查人脸
                                                                  
                                                                  CIDetector *aDetector = [[CIDetector alloc] init];
                                                                  
                                                                  NSArray *features = [aDetector featuresInImage:ciImage options:imageOptions];
                                                                  CGImageRef srcImage = NULL;
                                                                  OSStatus err = CreateCGImageFromCVPixelBuffer(CMSampleBufferGetImageBuffer(imageDataSampleBuffer), &srcImage);
                                                                  check(!err);
                                                                  
                                                                  CGImageRef cgImageResult = [self newSquareOverlayedImageForFeatures:features 
                                                                                                                            inCGImage:srcImage 
                                                                                                                      withOrientation:curDeviceOrientation 
                                                                                                                          frontFacing:_isUsingFrontFacingCamera];
                                                                  if (srcImage)
                                                                      CFRelease(srcImage);
                                                                  
                                                                  CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, 
                                                                                                                              imageDataSampleBuffer, 
                                                                                                                              kCMAttachmentMode_ShouldPropagate);
                                                                  [self writeCGImageToCameraRoll:cgImageResult withMetadata:(__bridge id)attachments];
                                                                  if (attachments)
                                                                      CFRelease(attachments);
                                                                  if (cgImageResult)
                                                                      CFRelease(cgImageResult);
                                                                  
                                                              });
                                                              
                                                          }
                                                          else {
                                                              // trivial simple JPEG case
                                                              NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                              CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, 
                                                                                                                          imageDataSampleBuffer, 
                                                                                                                          kCMAttachmentMode_ShouldPropagate);
                                                              ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                                                              [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
                                                                  if (error) {
                                                                      [self displayErrorOnMainQueue:error withMessage:@"Save to camera roll failed"];
                                                                  }
                                                              }];
                                                              
                                                              if (attachments)
                                                                  CFRelease(attachments);
                                                          }
                                                      }
                                                  }
	 ];
}

- (IBAction)toggleFaceDetection:(id)sender
{
	_detectFaces = [(UISwitch *)sender isOn];
	[[_videoDataOutPut connectionWithMediaType:AVMediaTypeVideo] setEnabled:_detectFaces];
	if (!_detectFaces) {
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			// clear out any squares currently displaying.
			[self drawFaceBoxesForFeatures:@[] forVideoBox:CGRectZero orientation:UIDeviceOrientationPortrait];
		});
	}
}

// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}

// called asynchronously as the capture output is capturing sample buffers, this method asks the face detector (if on)
// to detect features and for each draw the red square in a layer and set appropriate orientation
- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
    //    NSLog(@"%@",NSStringFromCGRect(clap));
    
	NSArray *sublayers = [NSArray arrayWithArray:[_previewLayer sublayers]];
	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
	NSInteger featuresCount = [features count], currentFeature = 0;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] )
			[layer setHidden:YES];
	}
	
	if ( featuresCount == 0 || !_detectFaces ) {
		[CATransaction commit];
		return; // early bail.
	}
    
	CGSize parentFrameSize = [_previewView frame].size;
	NSString *gravity = [_previewLayer videoGravity];
	BOOL isMirrored = [_previewLayer.connection isVideoMirrored];
	CGRect previewBox = [AVCemeraViewController videoPreviewBoxForGravity:gravity
                                                                 frameSize:parentFrameSize
                                                              apertureSize:clap.size];
	
	for ( CIFaceFeature *ff in features ) {
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect faceRect = [ff bounds];
        
		// flip preview width and height
		CGFloat temp = faceRect.size.width;
		faceRect.size.width = faceRect.size.height;
		faceRect.size.height = temp;
		temp = faceRect.origin.x;
		faceRect.origin.x = faceRect.origin.y;
		faceRect.origin.y = temp;
		// scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
		CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
		faceRect.size.width *= widthScaleBy;
		faceRect.size.height *= heightScaleBy;
		faceRect.origin.x *= widthScaleBy;
		faceRect.origin.y *= heightScaleBy;
        
		if ( isMirrored )
			faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
		else
			faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
		
		CALayer *featureLayer = nil;
		
		// re-use an existing layer if possible
		while ( !featureLayer && (currentSublayer < sublayersCount) ) {
			CALayer *currentLayer = sublayers[currentSublayer++];
			if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
		
		// create a new one if necessary
		if ( !featureLayer ) {
			featureLayer = [CALayer new];
			[featureLayer setContents:(id)[_square CGImage]];
			[featureLayer setName:@"FaceLayer"];
			[_previewLayer addSublayer:featureLayer];
		}
		[featureLayer setFrame:faceRect];
		
		switch (orientation) {
			case UIDeviceOrientationPortrait:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(180.))];
				break;
			case UIDeviceOrientationLandscapeLeft:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(90.))];
				break;
			case UIDeviceOrientationLandscapeRight:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.))];
				break;
			case UIDeviceOrientationFaceUp:
			case UIDeviceOrientationFaceDown:
			default:
				break; // leave the layer in its last known orientation
		}
		currentFeature++;
	}
	
	[CATransaction commit];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	// got an image
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
	if (attachments)
		CFRelease(attachments);
	NSDictionary *imageOptions = nil;
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	int exifOrientation;
	
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
	};
	
	switch (curDeviceOrientation) {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (_isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (_isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    
	imageOptions = @{CIDetectorImageOrientation: @(exifOrientation)};
	NSArray *features = [_faceDetector featuresInImage:ciImage options:imageOptions];
	
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
	CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
	
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self drawFaceBoxesForFeatures:features forVideoBox:clap orientation:curDeviceOrientation];
	});
}

- (void)dealloc
{
	[self teardownAVCapture];
    
}

// use front/back camera
- (IBAction)switchCameras:(id)sender
{
	AVCaptureDevicePosition desiredPosition;
	if (_isUsingFrontFacingCamera)
		desiredPosition = AVCaptureDevicePositionBack;
	else
		desiredPosition = AVCaptureDevicePositionFront;
	
	for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([d position] == desiredPosition) {
			[[_previewLayer session] beginConfiguration];
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
			for (AVCaptureInput *oldInput in [[_previewLayer session] inputs]) {
				[[_previewLayer session] removeInput:oldInput];
			}
			[[_previewLayer session] addInput:input];
			[[_previewLayer session] commitConfiguration];
			break;
		}
	}
	_isUsingFrontFacingCamera = !_isUsingFrontFacingCamera;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
