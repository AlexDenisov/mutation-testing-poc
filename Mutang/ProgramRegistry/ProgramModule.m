//
// Created by AlexDenisov on 29/03/16.
// Copyright (c) 2016 lowlevelbits. All rights reserved.
//

#import "ProgramModule.h"
#import "ProgramFunction.h"

@import LLVM_C;

@interface ProgramModule ()

@property LLVMModuleRef module;

@end

@implementation ProgramModule

+ (instancetype)moduleAtPath:(NSString *)path {
    LLVMMemoryBufferRef buffer;
    char *message;
    if (LLVMCreateMemoryBufferWithContentsOfFile(path.UTF8String, &buffer, &message)) {
        printf("Can't create buffer: %s\n", message);
        exit(1);
    }

    LLVMModuleRef module;
    if (LLVMGetBitcodeModule(buffer, &module, &message)) {
        printf("Can't get Bitcode: %s\n", message);
        exit(1);
    }

    LLVMDisposeMemoryBuffer(buffer);

    ProgramModule *programModule = [ProgramModule new];

    programModule.module = module;
    programModule.fullpath = path;

    return programModule;
}

- (NSArray *)functionNames {

    NSArray *functions = @[];

    LLVMValueRef currentFunction = LLVMGetFirstFunction(self.module);

    while (currentFunction) {
        const char *name = LLVMGetValueName(currentFunction);
        if (LLVMIsDeclaration(currentFunction)) {
            // skip declarations, since we interested only in functions with body
            currentFunction = LLVMGetNextFunction(currentFunction);
            continue;
        }

        ProgramFunction *function = [ProgramFunction functionFromModule:self withName:@(name)];
        functions = [functions arrayByAddingObject:function];
        currentFunction = LLVMGetNextFunction(currentFunction);
    }

    return functions;
}

- (void)dump {
    printf("%s\n", self.fullpath.UTF8String);
    for (ProgramFunction *function in self.functionNames) {
        printf("\t%s\n", function.description.UTF8String);
    }
}

@end
