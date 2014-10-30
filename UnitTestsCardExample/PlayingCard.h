//
//  PlayingCard.h
//  UnitTestsCardExample
//
//  Created by Fulop Barna on 30/10/14.
//  Copyright (c) 2014 Fulop Barna. All rights reserved.
//

#import "Card.h"

@interface PlayingCard : Card

@property (strong, nonatomic) NSString *suit;
@property (nonatomic) NSUInteger rank;

+ (NSArray *)validSuits;
+ (NSUInteger)maxRank;

@end
