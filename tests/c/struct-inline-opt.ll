; ModuleID = 'struct-inline-opt.bc'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%struct.rect = type { i32, i32 }

; Function Attrs: nounwind uwtable
define i32 @area(i64 %r.coerce) #0 {
entry:
  %r = alloca %struct.rect, align 8
  %0 = bitcast %struct.rect* %r to i64*
  store i64 %r.coerce, i64* %0, align 1
  %a = getelementptr inbounds %struct.rect* %r, i32 0, i32 0
  %1 = load i32* %a, align 4
  %b = getelementptr inbounds %struct.rect* %r, i32 0, i32 1
  %2 = load i32* %b, align 4
  %mul = mul nsw i32 %1, %2
  ret i32 %mul
}

; Function Attrs: nounwind uwtable
define i32 @main(i32 %argc, i8** %argv) #0 {
entry:
  %r.i = alloca %struct.rect, align 8
  %r = alloca %struct.rect, align 4
  %a = getelementptr inbounds %struct.rect* %r, i32 0, i32 0
  store i32 20, i32* %a, align 4
  %b = getelementptr inbounds %struct.rect* %r, i32 0, i32 1
  store i32 30, i32* %b, align 4
  %0 = bitcast %struct.rect* %r to i64*
  %1 = load i64* %0, align 1
  %2 = bitcast %struct.rect* %r.i to i8*
  call void @llvm.lifetime.start(i64 8, i8* %2)
  %3 = bitcast %struct.rect* %r.i to i64*
  store i64 %1, i64* %3, align 1
  %a.i = getelementptr inbounds %struct.rect* %r.i, i32 0, i32 0
  %4 = load i32* %a.i, align 4
  %b.i = getelementptr inbounds %struct.rect* %r.i, i32 0, i32 1
  %5 = load i32* %b.i, align 4
  %mul.i = mul nsw i32 %4, %5
  %6 = bitcast %struct.rect* %r.i to i8*
  call void @llvm.lifetime.end(i64 8, i8* %6)
  ret i32 0
}

; Function Attrs: nounwind
declare void @llvm.lifetime.start(i64, i8* nocapture) #1

; Function Attrs: nounwind
declare void @llvm.lifetime.end(i64, i8* nocapture) #1

attributes #0 = { nounwind uwtable "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind }

!llvm.ident = !{!0}

!0 = metadata !{metadata !"clang version 3.5.2 (tags/RELEASE_352/final)"}
