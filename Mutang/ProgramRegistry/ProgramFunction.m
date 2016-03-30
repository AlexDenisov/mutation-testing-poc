//
// Created by AlexDenisov on 29/03/16.
// Copyright (c) 2016 lowlevelbits. All rights reserved.
//

#import "ProgramFunction.h"

@implementation ProgramFunction

+ (instancetype)functionFromModule:(ProgramModule *)module withName:(NSString *)functionName {
    ProgramFunction *function = [ProgramFunction new];

    function.name = functionName;
    function.module = module;

    return function;
}

- (NSString *)description {
    return self.name;
}

@end
