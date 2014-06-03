//
//  SHUAnimationTableViewCell.m
//  SoftSoap
//
//  Created by 王澍宇 on 14-5-25.
//  Copyright (c) 2014年 王澍宇. All rights reserved.
//

#import "SHUAnimationTableViewCell.h"

@implementation SHUAnimationTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
