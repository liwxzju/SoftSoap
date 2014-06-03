//
//  ViewController.m
//  Demo
//
//  Created by Andrea on 16/04/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

#import "SHUTableViewController.h"
#import "SHUContentViewController.h"
#import "SHUAnimationTableViewCell.h"
#import "AMWaveTransition.h"

@interface SHUTableViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *numberArray;

@end

@implementation SHUTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.view setBackgroundColor:[UIColor colorWithPatternImage:_bgImage]];
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    
    _numberArray = @[[UIImage imageNamed:@"11"],
                     [UIImage imageNamed:@"12"],
                     [UIImage imageNamed:@"13"],
                     [UIImage imageNamed:@"14"],
                     [UIImage imageNamed:@"15"],
                     [UIImage imageNamed:@"16"]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHUAnimationTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    NSDictionary* dict = [[self.data[indexPath.row] objectForKey:@"item"] objectForKey:@"info"];
    
    cell.contentNameLabel.text = dict[@"商品名称"];
    
    if ([cell.contentNameLabel.text length] >= 6) {
       cell.contentNameLabel.text = [cell.contentNameLabel.text substringToIndex:6];
    }
    
    cell.url = [[self.data[indexPath.row] objectForKey:@"item"] objectForKey:@"url"];
    cell.bgImageView.image = _numberArray[indexPath.row];
    
    cell.animationView.type = CSAnimationTypeZoomOut;
    cell.animationView.delay = 0.8f;
    cell.animationView.duration = 1.0f;
    
    [cell.animationView startCanvasAnimation];
    
    [cell setBackgroundColor:[UIColor clearColor]];
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHUAnimationTableViewCell *cell = (SHUAnimationTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    _url = cell.url;
    
    [self performSegueWithIdentifier:@"segueToContent" sender:self];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC
{
    if (operation != UINavigationControllerOperationNone) {
        return [AMWaveTransition transitionWithOperation:operation];
    }
    return nil;
}

- (NSArray*)visibleCells
{
    return [self.tableView visibleCells];
}

- (IBAction)closeView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segueToContent"]) {
        SHUContentViewController *contentViewController = segue.destinationViewController;
        contentViewController.bgImage = self.bgImage;
        contentViewController.url = _url;
    }
}


@end
