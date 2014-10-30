//
//  Card.h
//  UnitTestsCardExample
//
//  Created by Fulop Barna on 30/10/14.
//  Copyright (c) 2014 Fulop Barna. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Card : NSObject

@property (strong, nonatomic) NSString *contents;
@property (nonatomic, getter=isChosen) BOOL chosen;
@property (nonatomic, getter=isMatched) BOOL matched;

- (int)match:(NSArray *)otherCards;

@end
