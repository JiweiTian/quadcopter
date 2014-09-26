Require Import String.
Require Import List.
Require Import Coq.Reals.Rdefinitions.
Require Import RIneq.

(************************************************)
(* The syntax of differential dynamic logic.    *)
(************************************************)
Definition Var := string.
(* All variables are real-valued. *)
Definition state := Var -> R.

(* Real-valued terms built using variables, constants
   and arithmetic. *)
Inductive Term :=
| VarT : Var -> Term
| RealT : R -> Term
| PlusT : Term -> Term -> Term
| MinusT : Term -> Term -> Term
| MultT : Term -> Term -> Term.

(* Same as terms, but can contain time
   "Formula Term" *)
(*Inductive FTerm :=
| TimeFT : FTerm
| VarFT : Var -> FTerm
| RealFT : R -> FTerm
| PlusFT : FTerm -> FTerm -> FTerm
| MinusFT : FTerm -> FTerm -> FTerm
| MultFT : FTerm -> FTerm -> FTerm.
*)
Inductive CompOp :=
| Gt : CompOp
| Ge : CompOp
| Lt : CompOp
| Le : CompOp
| Eq : CompOp.

(* Conditionals *)
Inductive Cond :=
| T : Cond
| F : Cond
| CompC : Term -> Term -> CompOp -> Cond
| AndC : Cond -> Cond -> Cond
| OrC : Cond -> Cond -> Cond.

(* Programs containing discrete and continuous parts. *)
(*Inductive DiscreteCmd :=
(* No-op *)
(*| Skip : DiscreteProg*)
(* A discrete progam constructor for assignment *)
| Assign : Var -> Term (*-> R*) -> DiscreteCmd
(* A discrete test. *)
| CondTest : Cond -> (*R ->*) DiscreteCmd.*)

Definition Assign := (Var * Term)%type.

Definition time := nonnegreal.
Definition ptime := posreal.

(*Definition DiscreteProg := (Cond * list Assign * R)%type.*)

Definition DiscreteProgBranch :=
  (Cond * ptime * list Assign * ptime) % type.

Definition DiscreteProg :=
  list DiscreteProgBranch.

Definition DiffEq := (Var * Term)%type.

Inductive HybridProg :=
(* A continuous program constructor that takes a list
   of differential equations and a time bound. Each
   differential equation is a pair of a variable and
   a real valued term. For example, if variables are
   strings, then the system of differential equations

    x' = 4
    y' = x

   would be represented as

    DiffEq [ ("x", RealT 4); ("y", VarT "x") ]

   The time bound specifies the maximum time for which
   the system evolves according to the differential
   equations.
 *)
(*| DiffEqHP1 : list DiffEq -> R -> HybridProg*)
(* A discrete program running in parallel with a
   continuous one. *)
| DiffEqHP : list DiffEq -> Cond -> DiscreteProg -> HybridProg
(* Sequencing programs *)
(*| Seq : HybridProg -> HybridProg -> HybridProg*)
(* Non-deterministic branching *)
(*| Branch : HybridProg -> HybridProg -> HybridProg*)
(* Non-deterministic repetition *)
| Rep : HybridProg -> HybridProg.

(* A language for more easily expressing discrete
   programs with a single continuous dynamics. *)
(*Inductive FullDiscrete :=
| Atomic : DiscreteProg -> FullDiscrete
(*| SeqI : FullDiscrete -> FullDiscrete -> FullDiscrete*)
| Ite : Cond -> R -> FullDiscrete -> FullDiscrete -> FullDiscrete.

Fixpoint conditionalize (hp:HybridProg) (c:Cond) (b:R) :=
  match hp with
    | DiffEqHP eqs p =>
       DiffEqHP eqs (AndC c (fst (fst p)),
                     snd (fst p), (b + (snd p))%R)
    | Branch hp1 hp2 => Branch (conditionalize hp1 c b)
                               (conditionalize hp2 c b)
    | Rep hp' => Rep (conditionalize hp' c b)
  end.

Definition neg_op (op:CompOp) : CompOp :=
  match op with
    | Gt => Le
    | Ge => Lt
    | Lt => Ge
    | Le => Gt
    | Eq => Neq
    | Neq => Eq
  end.

Fixpoint neg_cond (c:Cond) : Cond :=
  match c with
    | T => F
    | F => T
    | CompC t1 t2 op => CompC t1 t2 (neg_op op)
    | AndC c1 c2 => OrC (neg_cond c1) (neg_cond c2)
    | OrC c1 c2 => AndC (neg_cond c1) (neg_cond c2)
  end.

Fixpoint desugar (p:FullDiscrete) (cd:list DiffEq) :=
  match p with
    | Atomic p => DiffEqHP cd p
(*    | SeqI p1 p2 => Seq (desugar p1 cd) (desugar p2 cd)*)
    | Ite c b p1 p2 =>
        Branch (conditionalize (desugar p1 cd) c b)
               (conditionalize (desugar p2 cd) (neg_cond c) b)
(*      Branch (Seq (DiffEqHP2 cd (CondTest c b)) (desugar p1 cd))
             (Seq (DiffEqHP2 cd (CondTest (NegC c) b))
                  (desugar p1 cd))*)
  end.*)

(* Formulas expressing correctness properties of hybrid
   programs. *)
Inductive Formula :=
| TT : Formula
| FF : Formula
| CompF : Term -> Term -> CompOp -> Formula
| AndF : Formula -> Formula -> Formula
| OrF : Formula -> Formula -> Formula
| Imp : Formula -> Formula -> Formula
| Prog : HybridProg -> Formula
| Always : Formula -> Formula
| Eventually : Formula -> Formula.

(************************************************)
(* Some notation for the logic.                 *)
(************************************************)
Delimit Scope HP_scope with HP.

(*Term notation *)
Notation " # a " := (RealT a) (at level 0) : HP_scope.
Notation " ` a " := (VarT a) (at level 0) : HP_scope.
Definition T0 := RealT 0.
Definition T1 := RealT 1.
Infix "+" := (PlusT) : HP_scope.
Infix "-" := (MinusT) : HP_scope.
Notation "-- x" := (MinusT (RealT R0) x)
                     (at level 0) : HP_scope.
Infix "*" := (MultT) : HP_scope.
Fixpoint pow (t : Term) (n : nat) :=
  match n with
  | O => T1
  | S n => MultT t (pow t n)
  end.
Notation "t ^^ n" := (pow t n) (at level 10) : HP_scope.

(* This type class allows us to define a single notation
   for comparison operators and logical connectives in
   the context of a formula and conditionals. *)
Class Comparison (T : Type) : Type :=
{ Comp : Term -> Term -> CompOp -> T }.

Definition Gt' {T I} x y := @Comp T I x y Gt.
Infix ">" := (Gt') : HP_scope.
Definition Eq' {T I} x y := @Comp T I x y Eq.
Infix "=" := (Eq') : HP_scope.
Definition Ge' {T I} x y := @Comp T I x y Ge.
Infix ">=" := (Ge') : HP_scope.
Definition Le' {T I} x y := @Comp T I x y Le.
Infix "<=" := (Le') : HP_scope.
Definition Lt' {T I} x y := @Comp T I x y Lt.
Infix "<" := (Lt') : HP_scope.

Class PropLogic (T : Type) : Type :=
{ And : T -> T -> T;
  Or : T -> T -> T }.

Infix "/\" := (And) : HP_scope.
Infix "\/" := (Or) : HP_scope.

Instance FormulaComparison : Comparison Formula :=
{ Comp := CompF }.

Instance CondComparison : Comparison Cond :=
{ Comp := CompC }.

Instance FormulaPropLogic : PropLogic Formula :=
{ And := AndF;
  Or := OrF }.

Instance CondPropLogic : PropLogic Cond :=
{ And := AndC;
  Or := OrC }.

(* HybridProg notation *)
Notation "x ::= t" := (x, t)
                        (at level 60) : HP_scope.
Notation "x ' ::= t" := (x, t)
                          (at level 60) : HP_scope.
Notation "[ x1 , .. , xn ]" :=
  (cons x1 .. (cons xn nil) .. )
    (at level 70) : HP_scope.
(* This rule interferes with the assignment rule.
   Need to figure that out. *)
(*Notation " diffeqs @ b " :=
  (DiffEqHP1 diffeqs b)
    (at level 0) : HP_scope.*)
(*Notation "p1 ; p2" := (SeqI p1 p2)
  (at level 80, right associativity) : HP_scope.*)
Notation "'IFF' c @ bc 'THEN' p1 @ b1 'ELSE' p2 @ b2" :=
  ((c, bc, p1, b1) :: (T, bc, p2, b2) :: nil)
    (at level 90) : HP_scope.
(*Infix "||" := (desugar) : HP_scope.*)
Notation "[[ cp & c ]] || dp" :=
  (DiffEqHP cp c dp) (at level 85) : HP_scope.
Notation "p **" := (Rep p)
                     (at level 90) : HP_scope.

(* Formula notation *)
Notation "f1 --> f2" := (Imp f1 f2)
                          (at level 97) : HP_scope.
Notation "| p |" := (Prog p)
                      (at level 95) : HP_scope.
Notation "[] f" := (Always f)
                     (at level 95) : HP_scope.
Notation "<> f" := (Eventually f)
                     (at level 95) : HP_scope.