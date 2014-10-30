//
//  Deck.h
//  UnitTestsCardExample
//
//  Created by Fulop Barna on 30/10/14.
//  Copyright (c) 2014 Fulop Barna. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Card.h"

@interface Deck : NSObject

- (void)addCard:(Card *)card atTop:(BOOL)atTop;
- (void)addCard:(Card *)card;
- (Card *)drawRandomCard;

@end
