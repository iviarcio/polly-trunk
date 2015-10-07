; RUN: opt %loadPolly -polly-scops -analyze < %s | FileCheck %s
;
; CHECK:         Invariant Accesses: {
; CHECK-NEXT:            ReadAccess := [Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:                [tmp, tmp5] -> { Stmt_for_body[i0] -> MemRef_LB[0] };
; CHECK-NEXT:            Execution Context: [tmp, tmp5] -> {  :  }
; CHECK-NEXT:            ReadAccess := [Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:                [tmp, tmp5] -> { Stmt_do_cond[i0, i1] -> MemRef_UB[0] };
; CHECK-NEXT:            Execution Context: [tmp, tmp5] -> {  :  }
; CHECK-NEXT:            ReadAccess := [Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:                [tmp, tmp5] -> { Stmt_if_then[i0, i1] -> MemRef_V[0] };
; CHECK-NEXT:            Execution Context: [tmp, tmp5] -> {  : (tmp5 >= 1 + tmp and tmp5 >= 6) or tmp >= 6 }
; CHECK-NEXT:            ReadAccess := [Reduction Type: NONE] [Scalar: 0]
; CHECK-NEXT:                [tmp, tmp5] -> { Stmt_if_else[i0, i1] -> MemRef_U[0] };
; CHECK-NEXT:            Execution Context: [tmp, tmp5] -> {  : tmp <= 5 }
; CHECK-NEXT:    }
;
;    void f(int *restrict A, int *restrict V, int *restrict U, int *restrict UB,
;           int *restrict LB) {
;      for (int i = 0; i < 100; i++) {
;        int j = /* invariant load */ *LB;
;        do {
;          if (j > 5)
;            A[i] += /* invariant load */ *V;
;          else
;            A[i] += /* invariant load */ *U;
;        } while (j++ < /* invariant load */ *UB);
;      }
;    }
;
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

define void @f(i32* noalias %A, i32* noalias %V, i32* noalias %U, i32* noalias %UB, i32* noalias %LB) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 100
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %tmp = load i32, i32* %LB, align 4
  br label %do.body

do.body:                                          ; preds = %do.cond, %for.body
  %j.0 = phi i32 [ %tmp, %for.body ], [ %inc, %do.cond ]
  %cmp1 = icmp sgt i32 %j.0, 5
  br i1 %cmp1, label %if.then, label %if.else

if.then:                                          ; preds = %do.body
  %tmp1 = load i32, i32* %V, align 4
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp2 = load i32, i32* %arrayidx, align 4
  %add = add nsw i32 %tmp2, %tmp1
  store i32 %add, i32* %arrayidx, align 4
  br label %if.end

if.else:                                          ; preds = %do.body
  %tmp3 = load i32, i32* %U, align 4
  %arrayidx3 = getelementptr inbounds i32, i32* %A, i64 %indvars.iv
  %tmp4 = load i32, i32* %arrayidx3, align 4
  %add4 = add nsw i32 %tmp4, %tmp3
  store i32 %add4, i32* %arrayidx3, align 4
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  br label %do.cond

do.cond:                                          ; preds = %if.end
  %inc = add nsw i32 %j.0, 1
  %tmp5 = load i32, i32* %UB, align 4
  %cmp5 = icmp slt i32 %j.0, %tmp5
  br i1 %cmp5, label %do.body, label %do.end

do.end:                                           ; preds = %do.cond
  br label %for.inc

for.inc:                                          ; preds = %do.end
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}
