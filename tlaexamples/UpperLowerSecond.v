Require Import Coq.Reals.Rdefinitions.
Require Import TLA.TLA.
Require Import Examples.System.
Require Import Examples.SecondDerivShimCtrlToMiddle.
Require Import ChargeTactics.Lemmas.
Require Import Coq.Strings.String.
Local Open Scope string_scope.
Require Import BasicProofRules.
Require Import Coq.Lists.List.

Set Implicit Arguments.
Set Strict Implicit.

Module Type UpperLowerSecondParams.
  Parameter ub : R.

  Parameter d : R.
  Axiom d_gt_0 : (d > 0)%R.

  Parameter amin : R.
  Axiom amin_lt_0 : (amin < 0)%R.

  Parameter ubv : R.
End UpperLowerSecondParams.

Module UpperLowerSecond (P : UpperLowerSecondParams).
  Module Params <: SecondDerivShimParams.
    Definition ub := P.ub.
    Definition d := P.d.
    Definition d_gt_0 := P.d_gt_0.
    Definition amin := P.amin.
    Definition amin_lt_0 := P.amin_lt_0.
    Definition ubv := P.ubv.
  End Params.

  Module Monitor := SecondDerivShimCtrl Params.

  Let mirror :=
    (("y",--"y")::("v",--"v")::("a",--"a")::
     ("Y",--"Y")::("V",--"V")::("A",--"A")::nil).

  Definition SpecMirrorR :
    { x : SysRec &
          PartialSysD x |--
                      Rename (to_RenameMap mirror)
                             (PartialSysD Monitor.SpecR) }.
  Proof.
    discharge_PartialSys_rename_formula.
  Defined.

  Definition SpecR :=
    SysCompose Monitor.SpecR (projT1 SpecMirrorR).

  Definition ProgRefined :=
    Monitor.ProgRefined //\\
    rename_formula (to_RenameMap mirror) Monitor.ProgRefined.

  Lemma ProgRefined_ok :
    ProgRefined |-- SpecR.(Prog).
  Proof.
    unfold ProgRefined, SpecR, Monitor.ProgRefined.
    Opaque Monitor.SafeAcc Monitor.Default.
    simpl. restoreAbstraction. unfold Monitor.Ctrl.
    charge_tauto.
    Transparent Monitor.SafeAcc Monitor.Default.
  Qed.

  Definition Safe :=
    "y" <= Params.ub //\\ --Params.ub <= "y".

  Lemma UpperLower_safe :
    []"v" <= Params.ubv //\\ []"v" >= --Params.ubv
    |-- PartialSysD SpecR -->> []Safe.
  Proof.
    apply PartialCompose.
    - charge_intros. pose proof Monitor.ctrl_safe.
      unfold Monitor.Safe in *.
      charge_apply H. charge_tauto.
    - charge_intros.
      pose proof (projT2 SpecMirrorR). cbv beta in H.
      rewrite H. clear.
      pose proof Monitor.ctrl_safe.
      apply (Proper_Rename (to_RenameMap mirror)
                           (to_RenameMap mirror)) in H;
        [ | reflexivity ].
      rewrite Rename_impl in H.
      repeat rewrite <- (Rename_ok (Always _)) in H
        by is_st_term_list. simpl rename_formula in H.
      tlaCutByHyp H.
      { charge_apply H. 
        charge_split; try charge_tauto.
        clear. rewrite landC. tlaRevert.
        apply forget_prem. repeat rewrite Always_and.
        apply always_imp. solve_linear. }
      { clear. apply forget_prem. apply always_imp.
        solve_linear. }
  Qed.

  Lemma UpperLower_enabled :
    |-- Enabled (Discr SpecR.(Prog) SpecR.(maxTime)).
  Proof.
    simpl. restoreAbstraction.
    enable_ex_st.
    pose proof P.amin_lt_0. pose proof P.d_gt_0.
    destruct (RIneq.Rge_dec (st "y") R0).
    { smart_repeat_eexists; solve_linear. }
    { smart_repeat_eexists;
      repeat split.
      { right. intros. apply RIneq.Rgt_ge in H1.
        contradiction. }
      { right. instantiate (1:=(-Params.amin)%R).
        solve_linear. }
      { reflexivity. } }
  Qed.

  Lemma UpperLower_full :
    |-- SysSafe SpecR.
  Proof.
    apply SysSafe_rule. apply always_tauto.
    apply UpperLower_enabled.
  Qed.

End UpperLowerSecond.
