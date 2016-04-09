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
#include <errno.h>

#include <git2.h>
#include <git2/diff.h>

GIT_EXTERN(int) git_diff_print_callback__to_file_handle(
                                                        const git_diff_delta *delta,
                                                        const git_diff_hunk *hunk,
                                                        const git_diff_line *line,
                                                        void *payload); /**< payload must be a `FILE *` */

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

char *sourceForModule(LLVMModuleRef module) {
  const char *directory = LLVMGetModuleDirectory(module);
  const char *filename = LLVMGetModuleFilename(module);

  char fullname[100];
  strcpy(fullname, directory);
  strcat(fullname, "/");
  strcat(fullname, filename);

  FILE *sourceFile = fopen(fullname, "rb");
  if (!sourceFile) {
    printf("can't open file %s: %s\n", fullname, strerror(errno));
    return NULL;
  }

  fseek(sourceFile, 0, SEEK_END);
  long size = ftell(sourceFile);
  fseek(sourceFile, 0, SEEK_SET);

  char *source = calloc(size, sizeof(char));
  fread(source, sizeof(char), size, sourceFile);

  fclose(sourceFile);

  return source;
}

char *highlevelMutantRepresentation(const char *originalSource, struct MutationPoint mutationPoint) {
  assert(LLVMHasMetadata(mutationPoint.instruction));

  LLVMValueRef metadata = LLVMGetMetadata(mutationPoint.instruction, 0);

  const unsigned int line = LLVMGetDILocationLineNumber(metadata);
  const unsigned int column = LLVMGetDILocationColumn(metadata);

  char *mutationSource = calloc(strlen(originalSource), sizeof(char));
  strcpy(mutationSource, originalSource);

  unsigned int currentLine = 1;

  char *curChar = mutationSource;
  while ( (*(curChar++) != '\0') ) {
    if (currentLine == line) {
      *(curChar + column - 1) = '-';
      break;
    }

    if (*curChar == '\n') {
      currentLine++;
    }
  }

  return mutationSource;
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
  __unused struct MutationPoint mutatedPoint = makeMutationAtMutationPoint(mutationPoint);

  char *originalSource = sourceForModule(moduleWithMutation);
  char *mutantSource = highlevelMutantRepresentation(originalSource, mutationPoint);

  git_libgit2_init();

  git_patch *patch;

  git_patch_from_buffers(&patch,
                         originalSource, strlen(originalSource), LLVMGetModuleFilename(moduleWithMutation),
                         mutantSource, strlen(mutantSource), LLVMGetModuleFilename(moduleWithMutation),
                         NULL);

  git_patch_print(patch, git_diff_print_callback__to_file_handle, NULL);

  git_patch_free(patch);

  git_libgit2_shutdown();

  free(originalSource);
  free(mutantSource);

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
  LLVMDisposeModule(testeeModuleWithoutTestee);

  return 0;
}
