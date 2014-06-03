//
//  SHUCheckViewController.m
//  UrineCheck
//
//  Created by 王澍宇 on 14-4-25.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import "SHUCheckViewController.h"
#import "SHUOpenCVEngine.h"

NSString *kNotificationName = @"targetColorChangeNotification";

@interface SHUCheckViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) SHUOpenCVEngine *engine;
@property (strong, nonatomic) NSArray *targetColors;

- (IBAction)selectThershold:(UISlider *)sender;

@end

@implementation SHUCheckViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _engine = [[SHUOpenCVEngine alloc] init];
    
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.mediaTypes = @[(__bridge NSString *)kUTTypeImage];
    _imagePickerController.delegate = self;
    _imagePickerController.allowsEditing = YES;
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    _picNeedSolving = _picView.image;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
} 


- (IBAction)selectPic:(id)sender {
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}

- (IBAction)selectThershold:(UISlider *)sender {
    _picView.image = [_engine soloveUrine:_picNeedSolving withThresholdPos:sender.value];
    _targetColors = _engine.targetColors;
}

- (IBAction)cancelCheck:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ImagePicker Method

- (BOOL)isCameraAvailable
{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL) doesCameraSupportTakingPhotos{
    return [self cameraSupportsMedia:(__bridge NSString *)kUTTypeImage
                          sourceType:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL)cameraSupportsMedia:(NSString *)paramMediaType sourceType:(UIImagePickerControllerSourceType)paramSourceType
{
    __block BOOL result = NO;
    
    if ([paramMediaType length] == 0){
        NSLog(@"Media type is empty.");
        return NO;
    }
    
    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    
    [availableMediaTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *mediaType = (NSString *)obj;
        if ([mediaType isEqualToString:paramMediaType]){
            result = YES;
            *stop= YES; }
    }];
    
    return result;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(__bridge NSString *)kUTTypeImage]) {
        UIImage *theImage = info[UIImagePickerControllerEditedImage];
        _selectedPhoto = theImage;
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
        _picView.image = _selectedPhoto;
        _picNeedSolving = _selectedPhoto;
    }];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segueToResult"]) {
        
    }
}


@end
