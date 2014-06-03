//
//  SHUMainViewController.m
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-22.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import "SHUMainViewController.h"
#import "SHUCamViewController.h"
#import "SHUScanViewController.h"

@interface SHUMainViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIImagePickerController *imagePickerController;

@property (strong, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (strong, nonatomic) IBOutlet UIButton *selectPhotoButton;

@property (strong, nonatomic) UIImage *selectedPhoto;

- (IBAction)takePhoto:(UIButton *)sender;
- (IBAction)selectPhoto:(id)sender;

@end

@implementation SHUMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupImagePicker];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.animationView startCanvasAnimation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Animation Function

- (void)animateButton:(UIButton *)button
{
    
    
}

#pragma mark - ImagePicker Method

- (void)setupImagePicker
{
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.mediaTypes = @[(__bridge NSString *)kUTTypeImage];
    _imagePickerController.delegate = self;
    _imagePickerController.allowsEditing = YES;
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
}

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
        [self performSegueWithIdentifier:@"segueToCheck" sender:self];
    }];;
}

- (IBAction)takePhoto:(UIButton *)sender {

}
- (IBAction)selectPhoto:(id)sender {
    [self presentViewController:_imagePickerController animated:YES completion:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segueToCheck"]) {
        UINavigationController *navController = segue.destinationViewController;
        SHUScanViewController *scanViewController = navController.viewControllers[0];
        
        scanViewController.capturedImage = _selectedPhoto;
    }
}
@end
