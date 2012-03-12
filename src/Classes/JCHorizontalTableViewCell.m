//
//  JCHorizontalTableViewCell.m
//
//  Copyright 2012 jaceyroo.com
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  
//  Created by Crawfjs on 3/12/12.
//

#import "JCHorizontalTableViewCell.h"

@interface JCHorizontalTableViewCell() {
    
}
@property (atomic, retain) NSNumber *cellidx;
@end


@implementation JCHorizontalTableViewCell

@synthesize imageView,cellidx;

- (id)initWithFrame:(CGRect)frame {
    if ( (self = [super initWithFrame:frame]) ) {
        self.imageView = [[[UIImageView alloc] initWithFrame:frame] autorelease];
        self.imageView.userInteractionEnabled = YES;
        [self addSubview:self.imageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)didDisappear {
    self.imageView.image = nil;
}

- (void)dealloc {
    self.imageView = nil;
    self.cellidx = nil;
    [super dealloc];
}

@end
