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

void dumpMetadataRecursively(LLVMValueRef mdNode) {
  if (!mdNode) {
    return;
  }

//  LLVMDumpValue(mdNode);

  if (DILocationKind == LLVMGetMetadataKind(mdNode)) {
    printf("%s/%s:%d,%d\n", LLVMGetDILocationDirectory(mdNode), LLVMGetDILocationFilename(mdNode), LLVMGetDILocationLineNumber(mdNode), LLVMGetDILocationColumn(mdNode));
  }


  if (LLVMIsAMDString(mdNode)) {
//    unsigned int size = 0;
//    const char *s = LLVMGetMDString(mdNode, &size);
//    printf("%d %s\n", LLVMGetMetadataKind(mdNode), s);
    return;
  }

  unsigned int numDebugOperands = LLVMGetMDNodeNumOperands(mdNode);
  if (numDebugOperands) {
    LLVMValueRef *debugOperands = calloc(numDebugOperands, sizeof(LLVMValueRef));
    LLVMGetMDNodeOperands(mdNode, debugOperands);

    for (int i = 0; i < numDebugOperands; i++) {
      dumpMetadataRecursively(debugOperands[i]);
    }

    free(debugOperands);
  }
}

struct MutationPoint {
  LLVMValueRef function;
  LLVMBasicBlockRef basicBlock;
  LLVMValueRef instruction;
};

struct MutationPoint mutationPointForMutationFromFunction(LLVMValueRef function) {
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

  struct MutationPoint mutationPoint = { .function = function, .basicBlock = basicBlock, .instruction = instruction };
  
  return mutationPoint;
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

//    if (LLVMHasMetadata(instruction)) {
//      LLVMValueRef debugMetadata = LLVMGetMetadata(instruction, 0);
//      dumpMetadataRecursively(LLVMGetCurrentDebugLocation(builder));
//    }


    LLVMValueRef mutant = LLVMBuildNSWSub(builder, LLVMGetOperand(instruction, 0), LLVMGetOperand(instruction, 1), LLVMGetValueName(instruction));

    LLVMReplaceAllUsesWith(instruction, mutant);
    LLVMInstructionEraseFromParent(instruction);
  }

  return mutationModule;
}

struct MutationPoint makeMutationAtMutationPoint(struct MutationPoint mutationPoint) {
  LLVMValueRef function = mutationPoint.function;
  LLVMBasicBlockRef basicBlock = mutationPoint.basicBlock;
  LLVMValueRef instruction = mutationPoint.instruction;

  LLVMBuilderRef builder = LLVMCreateBuilder();
  LLVMPositionBuilder(builder, basicBlock, instruction);

  LLVMValueRef mutant = LLVMBuildNSWSub(builder, LLVMGetOperand(instruction, 0), LLVMGetOperand(instruction, 1), LLVMGetValueName(instruction));

  LLVMReplaceAllUsesWith(instruction, mutant);
  LLVMInstructionEraseFromParent(instruction);

  struct MutationPoint mutatedPoint = { .function = function, .basicBlock = basicBlock, .instruction = mutant };

  return mutatedPoint;
}

unsigned long long runFunction(LLVMValueRef function, LLVMModuleRef modules[], int modulesSize, LLVMModuleRef extraModule) {
  LLVMModuleRef firstModule = modules[0];

  char *error = NULL;
  LLVMExecutionEngineRef executionEngine;
  if (LLVMCreateExecutionEngineForModule(&executionEngine, firstModule, &error) != 0 ) {
    printf("Can't initialize engine: %s\n", error);
    // TODO: cleanup all allocated memory ;)
    exit(1);
  }

  for (int i = 1; i < modulesSize; i++) {
    LLVMAddModule(executionEngine, modules[i]);
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

  char moduleWithTestPath[100];
  char moduleWithTesteePath[100];

  const char *laboratoryPath = argv[1];

  strcpy(moduleWithTestPath, laboratoryPath);
  strcpy(moduleWithTesteePath, laboratoryPath);

  strcat(moduleWithTestPath, "/main.bc");
  strcat(moduleWithTesteePath, "/sum.bc");

  const LLVMModuleRef moduleWithTest = newModule(moduleWithTestPath);
  const LLVMModuleRef moduleWithTestee = newModule(moduleWithTesteePath);

  LLVMValueRef testFunction = firstTestFromModule(moduleWithTest);
  const char *mutationFunctionName = firstMutationFunctionNameForTestFunction(testFunction);

  LLVMModuleRef testeeModuleWithoutTestee = copyOfModuleWithoutFunction(moduleWithTestee, mutationFunctionName);

  LLVMModuleRef moduleWithMutation = copyOfModuleWithFunctionOnly(moduleWithTestee, mutationFunctionName);

  LLVMValueRef functionForMutation = LLVMGetNamedFunction(moduleWithMutation, mutationFunctionName);

  struct MutationPoint mutationPoint = mutationPointForMutationFromFunction(functionForMutation);
  struct MutationPoint mutatedPoint = makeMutationAtMutationPoint(mutationPoint);

  LLVMLinkInMCJIT();
  LLVMInitializeNativeTarget();
  LLVMInitializeNativeAsmPrinter();

  LLVMModuleRef modules[] = { moduleWithTest, testeeModuleWithoutTestee };

  unsigned long long initialResult = runFunction(testFunction, modules, 2, moduleWithTestee);
  unsigned long long mutatedResult = runFunction(testFunction, modules, 2, moduleWithMutation);

  if (initialResult != mutatedResult) {
    printf("mutant killed\n");
  } else {
    printf("mutant survived\n");
  }

  LLVMDisposeModule(moduleWithTest);
  LLVMDisposeModule(moduleWithTestee);
  LLVMDisposeModule(moduleWithMutation);
  return 0;
}
