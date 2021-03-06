Require Import Coq.Reals.Rdefinitions.
Require Import Coq.micromega.Psatz.
Require Import ExtLib.Structures.Applicative.
Require Import ChargeCore.Logics.ILogic.
Require Import ChargeCore.Tactics.Tactics.
Require Import SLogic.Logic.
Require Import SLogic.LTLNotation.
Require Import SLogic.BasicProofRules.
Require Import SMTC.Tactic.

Ltac specialize_arith_hyp H :=
  repeat match type of H with
         | ?G -> _ =>
           let HH := fresh "H" in
           assert G as HH by (psatzl R);
             specialize (H HH); clear HH
         end.

Ltac destruct_ite :=
  match goal with
  | [ |- context [ if ?e then _ else _ ] ]
    => destruct e
  end.

Ltac charge_revert :=
  lazymatch goal with
  | [ |- ltrue |-- _ ] => fail
  | [ |- _ ] =>
    first
      [ simple eapply landAdj | simple eapply Lemmas.landAdj_true ]
  end.

Ltac reason_action_tac :=
  repeat rewrite always_now;
  repeat rewrite <- landA;
  repeat charge_revert;
  repeat rewrite starts_impl;
  apply reason_action;
  let pre_st := fresh "pre_st" in
  let post_st := fresh "post_st" in
  intros pre_st post_st.

Ltac clear_not_always :=
  repeat rewrite landA;
  repeat match goal with
           | [ |- always ?A //\\ ?B |-- _ ] =>
             rewrite landC with (P:=always A); charge_revert
           | [ |- ?A //\\ ?B |-- _  ]=>
             apply landL2
           | [ |- always _ |-- _ ] => fail 1
           | [ |- _ |-- _ ] => charge_clear
         end; charge_intros.

Local Open Scope LTL_scope.

Ltac exists_val_now name :=
  match goal with
  |- _ |-- Exists x : _, [!(pure x `= ?e)] //\\ _ =>
  apply Exists_with_st with (y:=e); intro name;
  charge_intros; charge_split; [ charge_assumption | ]
  end.

(* Runs z3 on the goal, and admits the goal if z3 succeeds. *)
Ltac z3_prove :=
  smt solve; admit.
