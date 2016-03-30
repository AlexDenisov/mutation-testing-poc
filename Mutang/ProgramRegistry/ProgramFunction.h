//
// Created by AlexDenisov on 29/03/16.
// Copyright (c) 2016 lowlevelbits. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ProgramModule;

@interface ProgramFunction : NSObject

@property (weak) ProgramModule *module;
@property (copy) NSString *name;

+ (instancetype)functionFromModule:(ProgramModule *)module withName:(NSString *)functionName;

@end
