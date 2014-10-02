Require Import Syntax.
Require Import List.
Require Import Coq.Reals.Rdefinitions.
Require Import Coq.Reals.Ranalysis1.
Require Import Coq.Reals.RIneq.
Require Import String.
Require Import Sumbool.

(************************************************)
(* The semantics of differential dynamic logic. *)
(************************************************)
Open Scope R_scope.

(* Semantics of real valued terms *)
Fixpoint eval_term (t:Term) (st:state) : R :=
  match t with
  | VarT x => st x
  | RealT r => r
  | PlusT t1 t2 => (eval_term t1 st) +
                   (eval_term t2 st)
  | MinusT t1 t2 => (eval_term t1 st) -
                    (eval_term t2 st)
  | MultT t1 t2 => (eval_term t1 st) *
                   (eval_term t2 st)
  end.

(*Fixpoint eval_fterm (t:FTerm) (st:state) (r:time)
  : R :=
  match t with
  | VarFT x => st x
  | TimeFT => r
  | RealFT r => r
  | PlusFT t1 t2 => (eval_fterm t1 st r) +
                   (eval_fterm t2 st r)
  | MinusFT t1 t2 => (eval_fterm t1 st r) -
                    (eval_fterm t2 st r)
  | MultFT t1 t2 => (eval_fterm t1 st r) *
                   (eval_fterm t2 st r)
  end.*)

Definition Req_dec_sig : forall (r1 r2:R),
  {r1 = r2} + {r1 <> r2}.
Admitted.

Definition Rneq_dec_sig : forall (r1 r2:R),
  {r1 <> r2} + {r1 = r2}.
Admitted.

(* Semantics of comparison operators *)
Definition eval_comp (t1 t2:Term) (st:state)
           (op:CompOp) : bool :=
  let (e1, e2) :=
      (eval_term t1 st, eval_term t2 st) in
  let dec : sigT
              (fun op => forall r1 r2,
                           {op r1 r2} + {~op r1 r2})
      := match op with
           | Gt => existT _ Rgt Rgt_dec
           | Ge => existT _ Rge Rge_dec
           | Lt => existT _ Rlt Rlt_dec
           | Le => existT _ Rle Rle_dec
           | Eq => existT _ eq Req_dec_sig
         end in
  proj1_sig (bool_of_sumbool ((projT2 dec) e1 e2)).

(*Definition eval_fcomp (t1 t2:FTerm) (st:state)
           (op:CompOp) (r:time) : bool :=
  let (e1, e2) :=
      (eval_fterm t1 st r, eval_fterm t2 st r) in
  let dec : sigT
              (fun op => forall r1 r2,
                           {op r1 r2} + {~op r1 r2})
      := match op with
           | Gt => existT _ Rgt Rgt_dec
           | Ge => existT _ Rge Rge_dec
           | Lt => existT _ Rlt Rlt_dec
           | Le => existT _ Rle Rle_dec
           | Eq => existT _ eq Req_dec_sig
         end in
  proj1_sig (bool_of_sumbool ((projT2 dec) e1 e2)).
*)

(* Semantics of conditionals *)
Fixpoint eval_cond (c:Cond) (st:state) : bool :=
  match c with
  | T => true
  | F => false
  | CompC t1 t2 op => eval_comp t1 t2 st op
  | AndC c1 c2 => andb (eval_cond c1 st)
                       (eval_cond c2 st)
  | OrC c1 c2 => orb (eval_cond c1 st)
                     (eval_cond c2 st)
  end.

(* Expresses the property the a differentiable formula
   is a solution to a list of differential equations
   in the range 0 to r. *)
Definition solves_diffeqs (f : R -> state)
  (diffeqs : list (Var * Term)) (r : R)
  (is_derivable : forall x, derivable (fun t => f t x)) :=
  forall x d,
      List.In (x, d) diffeqs ->
      forall z, R0 <= z <= r ->
        derive (fun t => f t x) (is_derivable x) z =
        eval_term d (f z).

(* Expresses the property that f, in the range 0 to r,
   does not change any variables without differential
   equations in diffeqs. *)
Definition vars_unchanged (f : R -> state)
  (diffeqs : list (Var * Term)) (r : R)
  (is_derivable : forall x, derivable (fun t => f t x)) :=
  forall x,
      ~(exists d, List.In (x, d) diffeqs) ->
      forall z, R0 <= z <= r ->
        derive (fun t => f t x) (is_derivable x) z = R0.
(* Is this equivalent to the following? I think not. *)
(*        f z x = s x.*)

(* Prop expressing that f is a solution to diffeqs in
   [0,r]. *)
Definition is_solution (f : R -> state)
  (diffeqs : list (Var * Term)) (r : R) :=
  exists is_derivable,
    (* (2) f is a solution to diffeqs *)
   solves_diffeqs f diffeqs r is_derivable /\
    (* (3) f does not change other variables *)
   vars_unchanged f diffeqs r is_derivable.

(* Updates state s by setting x to the value of t. *)
Definition update_st (a:Assign) (s:state) :=
  fun y => if string_dec (fst a) y
           then eval_term (snd a) s
           else s y.

(* Semantics of discrete jumps. DiscreteProg p s1 s2 b
   holds if, starting in state s1, p runs in time
   b and produces state s2. *)
(*Inductive DiscreteJumpCmd :
  state -> state -> DiscreteCmd -> Prop :=
(*| SkipD : forall s, DiscreteJump Skip s s R0*)
| Assign : forall x t s,
   DiscreteJumpCmd s (update_st s x t) (Assign x t)
| CondTest : forall c s,
   eval_cond c s -> DiscreteJumpCmd s s (CondTest c).*)

(*Definition DiscreteJump s1 s2 p c : Prop :=
  eval_cond c s1 /\
  Forall (fun a:Assign =>
            let (x, t) := a in s2 x = eval_term t s1)
         p (*/\
  forall x, ~(exists t, List.In (x, t) p) ->
            s2 x = s1 x*).*)

Definition add_nonnegreal (r1 r2:nonnegreal) :=
  mknonnegreal (nonneg r1 + nonneg r2)
    (Rplus_le_le_0_compat _ _ (cond_nonneg r1)
                          (cond_nonneg r2)).

Definition T0 :=
  (mknonnegreal R0 (Rle_refl _)).

Definition convert_ptime (t:ptime) : time.
Admitted.

Fixpoint DiscreteJump' (s:state) (p:DiscreteProg)
  (t:time) : state * time :=
  match p with
    | nil => (s, T0)
    | cons (c, bc, a, ba) p' =>
      if eval_cond c s
      then (fold_right update_st s a,
            add_nonnegreal (convert_ptime bc)
              (add_nonnegreal (convert_ptime ba) t))
      else DiscreteJump' s p'
             (add_nonnegreal (convert_ptime bc) t)
  end.

Definition DiscreteJump (s:state) (p:DiscreteProg) :
  state * time := DiscreteJump' s p T0.

(*Inductive DiscreteJump :
  DiscreteProg -> state -> state -> time -> Prop :=
| P_Assign : forall p b s,
   DiscreteJump (C_Assign p b) s
                (fold_right update_st s p) b
| P_Ite_T : forall s1 s2 c b p1 b1 p2,
   eval_cond c s1 ->
   DiscreteJump p1 s1 s2 b1 ->
   DiscreteJump (C_Ite c b p1 p2) s1 s2
                (add_nonnegreal b1 b)
| P_Ite_F : forall s1 s2 c b p1 p2 b2,
   ~eval_cond c s1 ->
   DiscreteJump p2 s1 s2 b2 ->
   DiscreteJump (C_Ite c b p1 p2) s1 s2
                (add_nonnegreal b2 b).
*)
Definition merge_fun (f1 f2 f3:time->state) b :=
  (forall r, R0 <= (nonneg r) <= (nonneg b) ->
             f3 r = f1 r) /\
  (forall r, R0 <= (nonneg r) ->
             f3 (add_nonnegreal r b) = f2 r).

(* Semantics of hybrid programs. Intuitively,
   Behavior p f b should hold if p terminates in
   time b and f describes its behavior. *)
Inductive Behavior :
  HybridProg -> (time->state) -> time -> Prop :=
(* Semantics of a discrete program running in
   parallel with a continuous one. *)
| DiscreteB : forall fcp f cp c p (b:nonnegreal),
   DiscreteJump (f T0) p = (f b, b) ->
   (* fcp solves the system of differential eqns. *)
   is_solution fcp cp (nonneg b) ->
   (* the condition holds along solution to diffeq*)
   (forall r, (nonneg r) < (nonneg b) ->
              eval_cond c (fcp r) = true) -> 
   (* f agrees with fcp in [0,b) *)
   (forall r, (nonneg r) < (nonneg b) ->
              f r = fcp r) ->
   (* the state doesn't change after b *)
(*   (forall r, b < r -> f r = f b) ->*)
   Behavior (DiffEqHP cp c p) f b

(* Semantics of continuous evolution. The system can
   transition continuously from state s1 to state s2
   according to differential equations diffeqs if
   there exists some function (f : R -> state) which
     1) is equal to s1 at time 0 and equal to s2 at
        some later time
     2) is a solution to diffeqs    
     3) only changes values of variables whose
        derivative is specified in diffeqs
  The system evolves for at most b time units.
*)
(*| DiffEqB : forall f diffeqs r b,
   (* Should it be R0 < r or R0 <= r ? *)
   R0 < r <= b ->
   is_solution f diffeqs r ->
   (* The state doesn't change after r *)
   (forall t, r < t -> f t = f r) ->
   Behavior (DiffEqHP1 diffeqs b) f r*)

(* Semantics of sequencing. Nothing special here. *)
(*| SeqB : forall f1 f2 f3 b1 b2 p1 p2,
   Behavior p1 f1 b1 ->
   Behavior p2 f2 b2 ->
   merge_fun f1 f2 f3 b1 ->
   Behavior (Seq p1 p2) f3 (b1 + b2)*)

(* Branching semantics when first branch is taken. *)
(*| Branch1B : forall f b p1 p2,
   Behavior p1 f b ->
   Behavior (Branch p1 p2) f b

(* Branching semantics when second branch is taken. *)
| Branch2B : forall f b p1 p2,
   Behavior p2 f b ->
   Behavior (Branch p1 p2) f b*)

(* Repetition semantics with 0 repetitions. *)
| Rep0 : forall beh p,
   Behavior (Rep p) beh (mknonnegreal R0 (Rle_refl _))

(* Repetition semantics with at least 1 repetition. *)
| RepN : forall f1 b1 fN bN f p,
   (0 <= (nonneg b1))%R ->
   (0 <= (nonneg bN))%R ->
   Behavior p f1 b1 ->
   Behavior (Rep p) fN bN ->
   merge_fun f1 fN f b1 ->
   Behavior (Rep p) f (add_nonnegreal b1 bN).

(* Semantics of formulas. A formula valid with respect
   to a given behavior. When we state correctness
   properties of programs, we will quantify over the
   behavior.  *)
Fixpoint eval_formula (f:Formula) (beh:time->state)
  : Prop :=
  match f with
  | TT => True
  | FF => False
  | CompF t1 t2 op =>
    eval_comp t1 t2 (beh T0) op = true
  | AndF f1 f2 =>
    eval_formula f1 beh /\ eval_formula f2 beh
  | OrF f1 f2 =>
    eval_formula f1 beh \/ eval_formula f2 beh
  | Imp f1 f2 =>
    eval_formula f1 beh -> eval_formula f2 beh
  | Prog p => exists b, Behavior p beh b /\
                        forall t, b <= nonneg t ->
                                  beh b = beh t
  | Always f' =>
    forall t,
      eval_formula f' (fun r => beh
            (add_nonnegreal r t))
  | Eventually f' =>
    exists t, eval_formula f' (fun r => beh
            (add_nonnegreal r t))
  end.

(* Adding some notation for evaluation of formulas. *)
Notation "|- f" := (forall beh, eval_formula f beh)
                     (at level 100) : HP_scope.

Close Scope R_scope.