; ModuleID = 'sum.c'
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.11.0"

; Function Attrs: nounwind ssp uwtable
define i32 @someUnusedFucntion() #0 !dbg !4 {
entry:
  ret i32 42, !dbg !15
}

; Function Attrs: nounwind ssp uwtable
define i32 @sum(i32 %a, i32 %b) #0 !dbg !8 {
entry:
  %a.addr = alloca i32, align 4
  %b.addr = alloca i32, align 4
  store i32 %a, i32* %a.addr, align 4
  call void @llvm.dbg.declare(metadata i32* %a.addr, metadata !16, metadata !17), !dbg !18
  store i32 %b, i32* %b.addr, align 4
  call void @llvm.dbg.declare(metadata i32* %b.addr, metadata !19, metadata !17), !dbg !20
  %0 = load i32, i32* %a.addr, align 4, !dbg !21
  %1 = load i32, i32* %b.addr, align 4, !dbg !22
  %add = add nsw i32 %0, %1, !dbg !23
  ret i32 %add, !dbg !24
}

; Function Attrs: nounwind readnone
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

attributes #0 = { nounwind ssp uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="core2" "target-features"="+cx16,+fxsr,+mmx,+sse,+sse2,+sse3,+ssse3" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind readnone }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!11, !12, !13}
!llvm.ident = !{!14}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "clang version 3.9.0 (http://llvm.org/git/clang.git 32fcd42fc53548a16473f398bbb61299b7cd3ffa) (http://llvm.org/git/llvm.git ba0d0e16636b305f26a3b9970eadd409960f7d7a)", isOptimized: false, runtimeVersion: 0, emissionKind: 1, enums: !2, subprograms: !3)
!1 = !DIFile(filename: "sum.c", directory: "/Users/alexdenisov/Projects/LLVM/Mutang/laboratory")
!2 = !{}
!3 = !{!4, !8}
!4 = distinct !DISubprogram(name: "someUnusedFucntion", scope: !1, file: !1, line: 1, type: !5, isLocal: false, isDefinition: true, scopeLine: 1, isOptimized: false, variables: !2)
!5 = !DISubroutineType(types: !6)
!6 = !{!7}
!7 = !DIBasicType(name: "int", size: 32, align: 32, encoding: DW_ATE_signed)
!8 = distinct !DISubprogram(name: "sum", scope: !1, file: !1, line: 5, type: !9, isLocal: false, isDefinition: true, scopeLine: 5, flags: DIFlagPrototyped, isOptimized: false, variables: !2)
!9 = !DISubroutineType(types: !10)
!10 = !{!7, !7, !7}
!11 = !{i32 2, !"Dwarf Version", i32 2}
!12 = !{i32 2, !"Debug Info Version", i32 3}
!13 = !{i32 1, !"PIC Level", i32 2}
!14 = !{!"clang version 3.9.0 (http://llvm.org/git/clang.git 32fcd42fc53548a16473f398bbb61299b7cd3ffa) (http://llvm.org/git/llvm.git ba0d0e16636b305f26a3b9970eadd409960f7d7a)"}
!15 = !DILocation(line: 2, column: 3, scope: !4)
!16 = !DILocalVariable(name: "a", arg: 1, scope: !8, file: !1, line: 5, type: !7)
!17 = !DIExpression()
!18 = !DILocation(line: 5, column: 13, scope: !8)
!19 = !DILocalVariable(name: "b", arg: 2, scope: !8, file: !1, line: 5, type: !7)
!20 = !DILocation(line: 5, column: 20, scope: !8)
!21 = !DILocation(line: 6, column: 10, scope: !8)
!22 = !DILocation(line: 6, column: 14, scope: !8)
!23 = !DILocation(line: 6, column: 12, scope: !8)
!24 = !DILocation(line: 6, column: 3, scope: !8)
