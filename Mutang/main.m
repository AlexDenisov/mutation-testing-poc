//
//  main.m
//  Mutang
//
//  Created by AlexDenisov on 29/03/16.
//  Copyright © 2016 lowlevelbits. All rights reserved.
//

#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

@import LLVM_C;
@import LLVM_Utils;
@import LLVM_Support_DataTypes;

LLVMModuleRef newModule(const char *path) {
    LLVMMemoryBufferRef buffer;
    char *message;
    if (LLVMCreateMemoryBufferWithContentsOfFile(path, &buffer, &message)) {
        printf("Can't create buffer: %s\n", message);
        exit(1);
    }

    LLVMModuleRef module;
    if (LLVMParseBitcode2(buffer, &module)) {
        printf("Can't get Bitcode\n");
        exit(1);
    }

    LLVMDisposeMemoryBuffer(buffer);

    return module;
}

LLVMValueRef firstTestFromModule(LLVMModuleRef module) {
    LLVMValueRef currentFunction = LLVMGetFirstFunction(module);

    while (currentFunction) {
        const char *name = LLVMGetValueName(currentFunction);
        if (LLVMIsDeclaration(currentFunction)) {
            // skip declarations, since we interested only in functions with body
            currentFunction = LLVMGetNextFunction(currentFunction);
            continue;
        }

        if (strncmp(name, "test", strlen("test")) == 0) {
            break;
        }

        currentFunction = LLVMGetNextFunction(currentFunction);
    }

    return currentFunction;
}

bool hasSources(const char *functionName) {
    if (strncmp(functionName, "llvm", strlen("llvm")) == 0) {
        return false;
    }

    return true;
}

const char *firstMutationFunctionNameForTestFunction(LLVMValueRef testFunction) {
    assert(LLVMIsAFunction(testFunction));
    assert(LLVMCountBasicBlocks(testFunction));

    LLVMBasicBlockRef basicBlock = LLVMGetFirstBasicBlock(testFunction);

    while (basicBlock) {
        LLVMValueRef instruction = LLVMGetFirstInstruction(basicBlock);
        while (instruction) {
            if (LLVMIsACallInst(instruction)) {
                assert(LLVMGetNumOperands(instruction));

                int functionOperand = LLVMGetNumOperands(instruction) - 1;
                LLVMValueRef functionDeclaration = LLVMGetOperand(instruction, functionOperand);

                const char *functionName = LLVMGetValueName(functionDeclaration);
                if (hasSources(functionName)) {
                    return functionName;
                }
            }

            instruction = LLVMGetNextInstruction(instruction);
        }

        basicBlock = LLVMGetNextBasicBlock(basicBlock);
    }

    return "";
}

LLVMModuleRef copyOfModuleWithoutFunction(LLVMModuleRef module, const char *name) {
    LLVMModuleRef copyOfModule = LLVMCloneModule(module);
    LLVMValueRef function = LLVMGetNamedFunction(copyOfModule, name);

    LLVMDeleteFunction(function);

    return copyOfModule;
}

LLVMModuleRef copyOfModuleWithFunctionOnly(LLVMModuleRef module, const char *functionName) {
    LLVMModuleRef copyOfModule = LLVMCloneModule(module);

    LLVMValueRef currentFunction = LLVMGetFirstFunction(copyOfModule);

    while (currentFunction) {
        const char *name = LLVMGetValueName(currentFunction);
        if (LLVMIsDeclaration(currentFunction)) {
            // skip declarations, since we interested only in functions with body
            currentFunction = LLVMGetNextFunction(currentFunction);
            continue;
        }

        if (strcmp(name, functionName)) {
            LLVMValueRef functionToDelete = currentFunction;
            currentFunction = LLVMGetNextFunction(currentFunction);
            LLVMDeleteFunction(functionToDelete);
            continue;
        }

        currentFunction = LLVMGetNextFunction(currentFunction);
    }

    return copyOfModule;
}

LLVMValueRef mutationAdditionInstruction(LLVMValueRef function) {
    LLVMBasicBlockRef basicBlock = LLVMGetFirstBasicBlock(function);

    while (basicBlock) {
        LLVMValueRef instruction = LLVMGetFirstInstruction(basicBlock);
        while (instruction) {
            if (LLVMIsABinaryOperator(instruction)) {

                return instruction;
            }

            instruction = LLVMGetNextInstruction(instruction);
        }

        basicBlock = LLVMGetNextBasicBlock(basicBlock);
    }

    return NULL;
}

LLVMModuleRef moduleWithMutatedFunction(LLVMModuleRef module, const char *functionName) {
    LLVMModuleRef mutationModule = copyOfModuleWithFunctionOnly(module, functionName);

    LLVMValueRef function = LLVMGetNamedFunction(mutationModule, functionName);

    LLVMBasicBlockRef basicBlock = LLVMGetFirstBasicBlock(function);
    LLVMValueRef instruction = NULL;

    while (basicBlock) {
        instruction = LLVMGetFirstInstruction(basicBlock);
        while (instruction) {
            if (LLVMIsABinaryOperator(instruction)) {
                break;
            }

            instruction = LLVMGetNextInstruction(instruction);
        }

        if (instruction) {
            break;
        }

        basicBlock = LLVMGetNextBasicBlock(basicBlock);
    }

    if (basicBlock && instruction) {
        LLVMBuilderRef builder = LLVMCreateBuilder();
        LLVMPositionBuilder(builder, basicBlock, instruction);

        LLVMValueRef mutant = LLVMBuildNSWSub(builder, LLVMGetOperand(instruction, 0), LLVMGetOperand(instruction, 1), LLVMGetValueName(instruction));

        LLVMReplaceAllUsesWith(instruction, mutant);
        LLVMInstructionEraseFromParent(instruction);
    }

    return mutationModule;
}

unsigned long long runFunction(LLVMValueRef function, LLVMModuleRef module, LLVMModuleRef extraModule) {
    char *error = NULL;
    LLVMExecutionEngineRef executionEngine;
    if (LLVMCreateExecutionEngineForModule(&executionEngine, module, &error) != 0 ) {
        printf("Can't initialize engine: %s\n", error);
        // TODO: cleanup all allocated memory ;)
        exit(1);
    }

    LLVMAddModule(executionEngine, extraModule);

    LLVMGenericValueRef value = LLVMRunFunction(executionEngine, function, 0, NULL);
    unsigned long long result = LLVMGenericValueToInt(value, 0);

    LLVMModuleRef _dummy;

    LLVMRemoveModule(executionEngine, extraModule, &_dummy, NULL);

    return result;
}

int main(int argc, const char * argv[]) {
    assert(argc == 2);

    char testModulePath[100];
    char mutationModulePath[100];

    const char *laboratoryPath = argv[1];

    strcpy(testModulePath, laboratoryPath);
    strcpy(mutationModulePath, laboratoryPath);

    strcat(testModulePath, "/main.bc");
    strcat(mutationModulePath, "/sum.bc");

    LLVMModuleRef testModule = newModule(testModulePath);
    LLVMModuleRef mutationModule = newModule(mutationModulePath);

    LLVMValueRef testFunction = firstTestFromModule(testModule);
    const char *mutationFunctionName = firstMutationFunctionNameForTestFunction(testFunction);

    LLVMModuleRef mutationlessModule = copyOfModuleWithoutFunction(mutationModule, mutationFunctionName);

    LLVMModuleRef moduleWithMutation = moduleWithMutatedFunction(mutationModule, mutationFunctionName);

    if (LLVMLinkModules2(testModule, mutationlessModule)) {
        printf("something went wrong\n");
        exit(1);
    }

    LLVMLinkInMCJIT();
    LLVMInitializeNativeTarget();
    LLVMInitializeNativeAsmPrinter();

    unsigned long long initialResult = runFunction(testFunction, testModule, mutationModule);
    unsigned long long mutatedResult = runFunction(testFunction, testModule, moduleWithMutation);

    if (initialResult != mutatedResult) {
        printf("mutant killed\n");
    } else {
        printf("mutant survived\n");
    }

    LLVMDisposeModule(testModule);
    LLVMDisposeModule(mutationModule);
    LLVMDisposeModule(moduleWithMutation);
    return 0;
}
