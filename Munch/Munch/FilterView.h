//
//  FilterView.h
//  Munch
//
//  Created by Enoch Ng on 2016-06-01.
//  Copyright © 2016 Enoch Ng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FilterView : UIView <UICollectionViewDelegate, UICollectionViewDataSource>

-(void)setUpCategoryArray:(NSArray *)array;

@end
