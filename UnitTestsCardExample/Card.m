//
//  Card.m
//  UnitTestsCardExample
//
//  Created by Fulop Barna on 30/10/14.
//  Copyright (c) 2014 Fulop Barna. All rights reserved.
//

#import "Card.h"

@interface Card()

@end

@implementation Card

- (int)match:(NSArray *)otherCards
{
    int score = 0;
    for (Card *card in otherCards)
    {
        if ([card.contents isEqualToString:self.contents])
        {
            score = 1;
        }
    }
    return score;
}

@end
