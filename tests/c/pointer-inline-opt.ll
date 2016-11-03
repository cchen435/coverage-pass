; ModuleID = 'pointer-inline-opt.bc'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@main.array_a = private unnamed_addr constant [10 x i32] [i32 5, i32 4, i32 3, i32 2, i32 0, i32 8, i32 6, i32 9, i32 1, i32 7], align 16
@main.array_b = private unnamed_addr constant [10 x i32] [i32 5, i32 4, i32 3, i32 2, i32 0, i32 8, i32 6, i32 9, i32 1, i32 7], align 16

; Function Attrs: nounwind uwtable
define void @swap(i32* %a, i32 %i, i32 %j) #0 {
entry:
  %idxprom = sext i32 %i to i64
  %arrayidx = getelementptr inbounds i32* %a, i64 %idxprom
  %0 = load i32* %arrayidx, align 4
  %idxprom1 = sext i32 %j to i64
  %arrayidx2 = getelementptr inbounds i32* %a, i64 %idxprom1
  %1 = load i32* %arrayidx2, align 4
  %idxprom3 = sext i32 %i to i64
  %arrayidx4 = getelementptr inbounds i32* %a, i64 %idxprom3
  store i32 %1, i32* %arrayidx4, align 4
  %idxprom5 = sext i32 %j to i64
  %arrayidx6 = getelementptr inbounds i32* %a, i64 %idxprom5
  store i32 %0, i32* %arrayidx6, align 4
  ret void
}

; Function Attrs: nounwind uwtable
define void @add(i32* %a, i32* %b, i32* %c, i32 %size) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %cmp = icmp slt i32 %i.0, %size
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32* %a, i64 %idxprom
  %0 = load i32* %arrayidx, align 4
  %idxprom1 = sext i32 %i.0 to i64
  %arrayidx2 = getelementptr inbounds i32* %b, i64 %idxprom1
  %1 = load i32* %arrayidx2, align 4
  %add = add nsw i32 %0, %1
  %idxprom3 = sext i32 %i.0 to i64
  %arrayidx4 = getelementptr inbounds i32* %c, i64 %idxprom3
  store i32 %add, i32* %arrayidx4, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: nounwind uwtable
define i32 @sort(i32* %a, i32 %size) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc7, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc8, %for.inc7 ]
  %sub = sub nsw i32 %size, 1
  %cmp = icmp slt i32 %i.0, %sub
  br i1 %cmp, label %for.body, label %for.end9

for.body:                                         ; preds = %for.cond
  %add = add nsw i32 %i.0, 1
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %j.0 = phi i32 [ %add, %for.body ], [ %inc, %for.inc ]
  %cmp2 = icmp slt i32 %j.0, %size
  br i1 %cmp2, label %for.body3, label %for.end

for.body3:                                        ; preds = %for.cond1
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32* %a, i64 %idxprom
  %0 = load i32* %arrayidx, align 4
  %idxprom4 = sext i32 %j.0 to i64
  %arrayidx5 = getelementptr inbounds i32* %a, i64 %idxprom4
  %1 = load i32* %arrayidx5, align 4
  %cmp6 = icmp sgt i32 %0, %1
  br i1 %cmp6, label %if.then, label %if.end

if.then:                                          ; preds = %for.body3
  %idxprom.i = sext i32 %i.0 to i64
  %arrayidx.i = getelementptr inbounds i32* %a, i64 %idxprom.i
  %2 = load i32* %arrayidx.i, align 4
  %idxprom1.i = sext i32 %j.0 to i64
  %arrayidx2.i = getelementptr inbounds i32* %a, i64 %idxprom1.i
  %3 = load i32* %arrayidx2.i, align 4
  %idxprom3.i = sext i32 %i.0 to i64
  %arrayidx4.i = getelementptr inbounds i32* %a, i64 %idxprom3.i
  store i32 %3, i32* %arrayidx4.i, align 4
  %idxprom5.i = sext i32 %j.0 to i64
  %arrayidx6.i = getelementptr inbounds i32* %a, i64 %idxprom5.i
  store i32 %2, i32* %arrayidx6.i, align 4
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body3
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %inc = add nsw i32 %j.0, 1
  br label %for.cond1

for.end:                                          ; preds = %for.cond1
  br label %for.inc7

for.inc7:                                         ; preds = %for.end
  %inc8 = add nsw i32 %i.0, 1
  br label %for.cond

for.end9:                                         ; preds = %for.cond
  ret i32 0
}

; Function Attrs: nounwind uwtable
define i32 @main(i32 %argc, i8** %argv) #0 {
entry:
  %array_a = alloca [10 x i32], align 16
  %array_b = alloca [10 x i32], align 16
  %array_c = alloca [10 x i32], align 16
  %0 = bitcast [10 x i32]* %array_a to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* %0, i8* bitcast ([10 x i32]* @main.array_a to i8*), i64 40, i32 16, i1 false)
  %1 = bitcast [10 x i32]* %array_b to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* bitcast ([10 x i32]* @main.array_b to i8*), i64 40, i32 16, i1 false)
  %arraydecay = getelementptr inbounds [10 x i32]* %array_a, i32 0, i32 0
  br label %for.cond.i

for.cond.i:                                       ; preds = %for.end.i, %entry
  %i.0.i = phi i32 [ 0, %entry ], [ %inc8.i, %for.end.i ]
  %cmp.i = icmp slt i32 %i.0.i, 9
  br i1 %cmp.i, label %for.body.i, label %sort.exit

for.body.i:                                       ; preds = %for.cond.i
  %add.i = add nsw i32 %i.0.i, 1
  br label %for.cond1.i

for.cond1.i:                                      ; preds = %if.end.i, %for.body.i
  %j.0.i = phi i32 [ %add.i, %for.body.i ], [ %inc.i, %if.end.i ]
  %cmp2.i = icmp slt i32 %j.0.i, 10
  br i1 %cmp2.i, label %for.body3.i, label %for.end.i

for.body3.i:                                      ; preds = %for.cond1.i
  %idxprom.i = sext i32 %i.0.i to i64
  %arrayidx.i = getelementptr inbounds i32* %arraydecay, i64 %idxprom.i
  %2 = load i32* %arrayidx.i, align 4
  %idxprom4.i = sext i32 %j.0.i to i64
  %arrayidx5.i = getelementptr inbounds i32* %arraydecay, i64 %idxprom4.i
  %3 = load i32* %arrayidx5.i, align 4
  %cmp6.i = icmp sgt i32 %2, %3
  br i1 %cmp6.i, label %if.then.i, label %if.end.i

if.then.i:                                        ; preds = %for.body3.i
  %idxprom.i.i = sext i32 %i.0.i to i64
  %arrayidx.i.i = getelementptr inbounds i32* %arraydecay, i64 %idxprom.i.i
  %4 = load i32* %arrayidx.i.i, align 4
  %idxprom1.i.i = sext i32 %j.0.i to i64
  %arrayidx2.i.i = getelementptr inbounds i32* %arraydecay, i64 %idxprom1.i.i
  %5 = load i32* %arrayidx2.i.i, align 4
  %idxprom3.i.i = sext i32 %i.0.i to i64
  %arrayidx4.i.i = getelementptr inbounds i32* %arraydecay, i64 %idxprom3.i.i
  store i32 %5, i32* %arrayidx4.i.i, align 4
  %idxprom5.i.i = sext i32 %j.0.i to i64
  %arrayidx6.i.i = getelementptr inbounds i32* %arraydecay, i64 %idxprom5.i.i
  store i32 %4, i32* %arrayidx6.i.i, align 4
  br label %if.end.i

if.end.i:                                         ; preds = %if.then.i, %for.body3.i
  %inc.i = add nsw i32 %j.0.i, 1
  br label %for.cond1.i

for.end.i:                                        ; preds = %for.cond1.i
  %inc8.i = add nsw i32 %i.0.i, 1
  br label %for.cond.i

sort.exit:                                        ; preds = %for.cond.i
  %arraydecay1 = getelementptr inbounds [10 x i32]* %array_a, i32 0, i32 0
  %arraydecay2 = getelementptr inbounds [10 x i32]* %array_b, i32 0, i32 0
  %arraydecay3 = getelementptr inbounds [10 x i32]* %array_c, i32 0, i32 0
  br label %for.cond.i3

for.cond.i3:                                      ; preds = %for.body.i7, %sort.exit
  %i.0.i1 = phi i32 [ 0, %sort.exit ], [ %inc.i8, %for.body.i7 ]
  %cmp.i2 = icmp slt i32 %i.0.i1, 10
  br i1 %cmp.i2, label %for.body.i7, label %add.exit

for.body.i7:                                      ; preds = %for.cond.i3
  %idxprom.i4 = sext i32 %i.0.i1 to i64
  %arrayidx.i5 = getelementptr inbounds i32* %arraydecay1, i64 %idxprom.i4
  %6 = load i32* %arrayidx.i5, align 4
  %idxprom1.i = sext i32 %i.0.i1 to i64
  %arrayidx2.i = getelementptr inbounds i32* %arraydecay2, i64 %idxprom1.i
  %7 = load i32* %arrayidx2.i, align 4
  %add.i6 = add nsw i32 %6, %7
  %idxprom3.i = sext i32 %i.0.i1 to i64
  %arrayidx4.i = getelementptr inbounds i32* %arraydecay3, i64 %idxprom3.i
  store i32 %add.i6, i32* %arrayidx4.i, align 4
  %inc.i8 = add nsw i32 %i.0.i1, 1
  br label %for.cond.i3

add.exit:                                         ; preds = %for.cond.i3
  ret i32 0
}

; Function Attrs: nounwind
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture, i8* nocapture readonly, i64, i32, i1) #1

attributes #0 = { nounwind uwtable "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind }

!llvm.ident = !{!0}

!0 = metadata !{metadata !"clang version 3.5.2 (tags/RELEASE_352/final)"}
