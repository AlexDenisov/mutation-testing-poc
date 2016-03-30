//
// Created by AlexDenisov on 29/03/16.
// Copyright (c) 2016 lowlevelbits. All rights reserved.
//

#import "Driver.h"
#import "ProgramModule.h"

@implementation Driver

- (void)startInLaboratory:(NSString *)laboratory {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSError *error = nil;
    NSArray *content = [fileManager contentsOfDirectoryAtPath:laboratory error:&error];

    if (error) {
        NSLog(@"%@", error);
        exit(1);
    }

    for (NSString *filename in content) {
        if (![[filename pathExtension] isEqualToString:@"bc"]) {
            continue;
        }

        NSString *fullPath = [laboratory stringByAppendingPathComponent:filename];
        ProgramModule *module = [ProgramModule moduleAtPath:fullPath];
        [module dump];
    }
}

@end
