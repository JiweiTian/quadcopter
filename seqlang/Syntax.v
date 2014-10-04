Require Import String.
Require Import List.
Require Import Coq.Reals.Rdefinitions.
Require Import Coq.Reals.RIneq.

(************************************************)
(* The syntax of differential dynamic logic.    *)
(************************************************)
Section Syntax.
  Definition Var := string.

  (* All variables are real-valued. *)
  Definition state := Var -> R.

  Definition time := nonnegreal.

  Inductive Term :=
  | VarT : Var -> Term
  | RealT : R -> Term
  | PlusT : Term -> Term -> Term
  | MinusT : Term -> Term -> Term
  | MultT : Term -> Term -> Term.

  Inductive CompOp :=
  | Gt : CompOp
  | Ge : CompOp
  | Lt : CompOp
  | Le : CompOp
  | Eq : CompOp.

  (* Conditionals *)
  Inductive Cond :=
  | CompC : Term -> Term -> CompOp -> Cond
  | AndC : Cond -> Cond -> Cond
  | OrC : Cond -> Cond -> Cond
  | NegC : Cond -> Cond.

  Inductive DiffEq :=
  | DiffEqC : Var -> Term -> DiffEq.

  (* Programs containing discrete and continuous parts. *)
  Inductive HybridProg :=
  (* No-op *)
  | Skip : HybridProg
  (* A discrete progam constructor for assignment *)
  | Assign : Var -> Term -> HybridProg
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
  | Continuous : list DiffEq -> time -> HybridProg
  (* Sequencing programs *)
  | Seq : HybridProg -> HybridProg -> HybridProg
  (* Branching *)
  | Ite : Cond -> HybridProg -> HybridProg -> HybridProg
  (* Non-deterministic repetition *)
  | Rep : HybridProg -> HybridProg.

(* Formulas expressing correctness properties of hybrid
   programs. *)
Inductive Formula :=
| CompF : Term -> Term -> CompOp -> Formula
| AndF : Formula -> Formula -> Formula
| OrF : Formula -> Formula -> Formula
| Imp : Formula -> Formula -> Formula
| Prog : HybridProg -> Formula
| Always : Formula -> Formula
| Eventually : Formula -> Formula.

End Syntax.

(************************************************)
(* Some notation for the logic.                 *)
(************************************************)
Delimit Scope HP_scope with HP.

(*Term notation *)
Definition NatC (n:nat) : R :=
  INR n.
Coercion NatC : nat >-> R.
Definition ConstC (c:R) : Term :=
  RealT c.
Coercion ConstC : R >-> Term.
(*Notation " # a " := (RealT string a) (at level 0) : HP_scope.*)
Definition VarC (x:string) : Term :=
  VarT x.
Coercion VarC : string >-> Term.
(*Notation " ` a " := (VarT string a) (at level 0) : HP_scope.*)
(*Definition T0 := RealT string 0.
Definition T1 := RealT string 1.*)
Infix "+" := (PlusT) : HP_scope.
Infix "-" := (MinusT) : HP_scope.
Notation "-- x" := (MinusT (RealT R0) x)
                     (at level 0) : HP_scope.
Infix "*" := (MultT) : HP_scope.
Fixpoint pow (t : Term) (n : nat) :=
  match n with
  | O => RealT 1
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
Notation "x ::= t" := (Assign x t)
                        (at level 60) : HP_scope.
Notation "x ' ::= t" := (DiffEqC x t) (at level 60) : HP_scope.
Notation "[ x1 , .. , xn ]" := (cons x1 .. (cons xn nil) .. )
    (at level 70) : HP_scope.
Notation "diffeqs @ b" := (Continuous diffeqs b)
                            (at level 75) : HP_scope.
Notation "p1 ; p2" := (Seq p1 p2)
  (at level 80, right associativity) : HP_scope.
Notation "'IFF' c 'THEN' p1 'ELSE' p2" :=
  (Ite c p1 p2) (at level 90) : HP_scope.
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