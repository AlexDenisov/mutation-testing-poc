//
// Created by AlexDenisov on 29/03/16.
// Copyright (c) 2016 lowlevelbits. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProgramModule : NSObject

@property (copy) NSString *fullpath;

+ (instancetype)moduleAtPath:(NSString *)path;

- (NSArray *)functionNames;

- (void)dump;

@end
