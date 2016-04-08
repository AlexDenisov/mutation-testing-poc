; ModuleID = 'sum.c'
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.11.0"

; Function Attrs: nounwind ssp uwtable
define i32 @someUnusedFucntion() #0 !dbg !4 {
entry:
  ret i32 42, !dbg !11
}

; Function Attrs: nounwind ssp uwtable
define i32 @sum(i32 %a, i32 %b) #0 !dbg !6 {
entry:
  %a.addr = alloca i32, align 4
  %b.addr = alloca i32, align 4
  store i32 %a, i32* %a.addr, align 4
  store i32 %b, i32* %b.addr, align 4
  %0 = load i32, i32* %a.addr, align 4, !dbg !12
  %1 = load i32, i32* %b.addr, align 4, !dbg !13
  %add = add nsw i32 %0, %1, !dbg !14
  ret i32 %add, !dbg !15
}

attributes #0 = { nounwind ssp uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="core2" "target-features"="+cx16,+fxsr,+mmx,+sse,+sse2,+sse3,+ssse3" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!7, !8, !9}
!llvm.ident = !{!10}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang version 3.9.0 (http://llvm.org/git/clang.git 32fcd42fc53548a16473f398bbb61299b7cd3ffa) (http://llvm.org/git/llvm.git ba0d0e16636b305f26a3b9970eadd409960f7d7a)", isOptimized: false, runtimeVersion: 0, emissionKind: 2, enums: !2, subprograms: !3)
!1 = !DIFile(filename: "sum.c", directory: "/Users/alexdenisov/Projects/LLVM/Mutang/laboratory")
!2 = !{}
!3 = !{!4, !6}
!4 = distinct !DISubprogram(name: "someUnusedFucntion", scope: !1, file: !1, line: 1, type: !5, isLocal: false, isDefinition: true, scopeLine: 1, isOptimized: false, variables: !2)
!5 = !DISubroutineType(types: !2)
!6 = distinct !DISubprogram(name: "sum", scope: !1, file: !1, line: 5, type: !5, isLocal: false, isDefinition: true, scopeLine: 5, flags: DIFlagPrototyped, isOptimized: false, variables: !2)
!7 = !{i32 2, !"Dwarf Version", i32 2}
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !{i32 1, !"PIC Level", i32 2}
!10 = !{!"clang version 3.9.0 (http://llvm.org/git/clang.git 32fcd42fc53548a16473f398bbb61299b7cd3ffa) (http://llvm.org/git/llvm.git ba0d0e16636b305f26a3b9970eadd409960f7d7a)"}
!11 = !DILocation(line: 2, column: 3, scope: !4)
!12 = !DILocation(line: 6, column: 10, scope: !6)
!13 = !DILocation(line: 6, column: 14, scope: !6)
!14 = !DILocation(line: 6, column: 12, scope: !6)
!15 = !DILocation(line: 6, column: 3, scope: !6)
