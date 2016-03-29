//
//  main.m
//  Mutang
//
//  Created by AlexDenisov on 29/03/16.
//  Copyright © 2016 lowlevelbits. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "llvm-c/Core.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        LLVMModuleRef module = LLVMModuleCreateWithName("Hello World!");
        LLVMDumpModule(module);
        LLVMDisposeModule(module);
    }
    return 0;
}
