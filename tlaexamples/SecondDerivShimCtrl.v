Require Import Coq.Reals.Rdefinitions.
Require Import Coq.Reals.RIneq.
Require Import TLA.TLA.
Require Import TLA.DifferentialInduction.
Require Import TLA.ContinuousProofRules.
Require Import TLA.BasicProofRules.
Require Import TLA.ArithFacts.
Require Import Examples.System.
Require Import Examples.SecondDerivUtil.

Open Scope HP_scope.
Open Scope string_scope.

Module Type SecondDerivShimParams <: SdistParams.

  (* The upper bound on y. *)
  Parameter ub : R.
  (* Max time between executions of the
     controller. *)
  Parameter d : R.
  Parameter d_gt_0 : (d > 0)%R.
  (* Our breaking acceleration. *)
  Parameter amin : R.
  Parameter amin_lt_0 : (amin < 0)%R.

  Parameter WC : Formula.

End SecondDerivShimParams.

Module SecondDerivShimCtrl (Import Params : SecondDerivShimParams).

  Module SdistUtil := SdistUtil(Params).
  Import SdistUtil.

  (* The continuous dynamics of the system *)
  Definition w : state->Formula :=
    fun st' =>
      st' "y" = "v" //\\ st' "v" = "a" //\\
      AllConstant ("a"::"Y"::"V"::"T"::nil)%list st'.

  Definition Ctrl : Formula :=
         (Max "A" 0 (fun mx => "Ymax" + tdist "Vmax" mx d +
                               sdist ("Vmax" + mx*d)
          <= ub) //\\ "a"! = "A")
    \\// ("a"! = amin).

  Definition History : Formula :=
    "Y"! = "y" //\\ "V"! = "v" //\\ "T"! = "t"!.

  Definition Safe : Formula :=
    "y" <= ub.

  Definition tdiff : Term :=
    "T" - "t".

  Definition I : Formula :=
    Syntax.Forall R
           (fun t =>
              0 <= t <= d -->>
              (0 <= "v" + "a"*t  -->>
               "y" + tdist "v" "a" t +
               sdist ("v" + "a"*t) <= ub) //\\
              ("v" + "a"*t < 0 -->>
               "y" + tdist "v" "a" t <= ub)) //\\
    "T" = "t" //\\ "Y" = "y" //\\ "V" = "v" //\\
    0 <= "t" <= d.

  Definition SpecR : SysRec :=
    {| Init := I;
       Prog := Ctrl //\\ History //\\ Unchanged ("v"::"y"::nil)%list;
       world := w;
       unch := (("a":Term)::("Y":Term)::("V":Term)::
                ("T":Term)::("v":Term)::("y":Term)::nil)%list;
       maxTime := d |}.

  Definition Spec := SysD SpecR.

  Definition IndInv : Formula :=
    "y" - "Y" <= tdist "V" "a" tdiff //\\
    "v" - "V" <= "a"*tdiff //\\
    Syntax.Forall R
           (fun t =>
              ((0 <= t <= d //\\ 0 <= "V" + "a"*t) -->>
                    "Y" + (tdist "V" "a" t) +
                    (sdist ("V" + "a"*t)) <= ub) //\\
              ((0 <= t <= d //\\ "V" + "a"*t < 0) -->>
                     "Y" + (tdist "V" "a" t) <= ub)) //\\
   "t" <= "T" <= d.

  Lemma ind_inv_init :
    I |-- IndInv.
  Proof.
    breakAbstraction; simpl; unfold eval_comp;
    simpl; intros. destruct H.
    decompose [and] H0. clear H0.
    rewrite H1 in *; clear H1;
    rewrite H2 in *; clear H2;
    rewrite H3 in *; clear H3.
    solve_linear; specialize (H x);
    solve_linear.
  Qed.
  
  (* A proof that the inductive safety condition
     Inv implies the safety contition
     we actually care about, Safe. *)
  Lemma inv_safe : IndInv //\\ TimeBound d |-- Safe.
  Proof.
    pose proof amin_lt_0.
    pose proof d_gt_0.
    tlaAssert (0 <= tdiff <= d);
    [ solve_linear | tlaIntro ].
    breakAbstraction; simpl; unfold eval_comp; simpl; intros.
    repeat match goal with
           | H : _ /\ _ |- _ => destruct H
           end.
    specialize (H7 (fst (Stream.hd tr) "T" - fst (Stream.hd tr) "t"))%R.
    destruct (Rle_dec R0 
                      (fst (Stream.hd tr) "V"+
                       fst (Stream.hd tr) "a"*
                       (fst (Stream.hd tr) "T" - fst (Stream.hd tr) "t"))%R);
      intuition.
    - eapply Rle_trans; eauto.
      rewrite <- Rplus_0_r with (r:=fst (Stream.hd tr) "y").
      apply Rplus_le_compat.
      + solve_linear.
      + rewrite Rmult_assoc.
        apply Rmult_0_le; solve_linear.
        apply pow_0_le.
        assert (/ amin < 0)%R by solve_linear.
        solve_linear.
    - assert
        ((fst (Stream.hd tr) "V" +
          fst (Stream.hd tr) "a" *
          (fst (Stream.hd tr) "T" - fst (Stream.hd tr) "t") < 0)%R)
        by solve_linear.
      eapply Rle_trans; eauto.
      solve_linear.
  Qed.

  Lemma SysSafe_ctrl : forall P, P |-- SysSafe SpecR.
  Proof.
    intros.
    apply SysSafe_rule; apply always_tauto.
    enable_ex_st; repeat eexists; solve_linear.
  Qed.

  Theorem ctrl_safe :
    []"Vmax" >= "v" //\\ []"Ymax" >= "y" |-- Spec -->> []Safe.
  Proof.
    pose proof amin_lt_0 as amin_lt_0.
    pose proof d_gt_0 as d_gt_0.
    tlaIntro.
    eapply Sys_by_induction
    with (IndInv:=IndInv) (A:="Vmax" >= "v" //\\ "Ymax" >= "y").
    - tlaIntuition.
    - unfold Spec, SpecR. tlaAssume.
    - tlaIntuition.
    - apply SysSafe_ctrl.
    - charge_apply ind_inv_init. charge_tauto.
    - tlaIntuition.
    - charge_apply inv_safe. charge_tauto.
    - unfold InvariantUnder, IndInv, Max. simpl.
      restoreAbstraction. unfold tdist, sdist.
      solve_linear; rewrite_next_st; solve_linear;
      specialize (H3 x); solve_linear.
    - simpl BasicProofRules.next. restoreAbstraction.
      repeat charge_split;
      try (apply lforallR; intro).
      { match goal with
          |- _ |-- ?GG => eapply diff_ind
                          with (Hyps:="v" - "V" <= "a"*tdiff)
                                 (G:=unnext GG)
        end; try solve [ tlaIntuition |
                         unfold World; tlaAssume |
                         solve_linear ].
        eapply diff_ind with (Hyps:=TRUE);
          try solve [ tlaIntuition |
                         unfold World; tlaAssume |
                         solve_linear ]. solve_nonlinear.
        solve_nonlinear. }
      { match goal with
          |- _ |-- ?GG => eapply diff_ind
                          with (Hyps:=TRUE)
                                 (G:=unnext GG)
        end; try solve [ tlaIntuition |
                         unfold World; tlaAssume |
                         solve_linear ]. solve_nonlinear. }
      { match goal with
          |- _ |-- ?GG => eapply diff_ind
                          with (Hyps:=TRUE)
                                 (G:=unnext GG)
        end; try solve [ tlaIntuition |
                         unfold World; tlaAssume |
                         solve_linear ].
        - unfold IndInv;
          simpl; restoreAbstraction; unfold tdist, sdist;
          solve_linear; rewrite_next_st; solve_linear;
          specialize (H5 x); solve_linear.
        - simpl deriv_formula. restoreAbstraction.
          charge_intros; repeat charge_split;
          charge_intros.
          { eapply zero_deriv with (x:="a");
            [ charge_tauto | tlaIntuition | ].
            eapply zero_deriv with (x:="V");
              [ charge_tauto | tlaIntuition | ].
            solve_linear; rewrite_next_st;
            solve_linear. }
          { solve_linear. rewrite H6. rewrite H4. rewrite H7.
            solve_linear. }
          { eapply zero_deriv with (x:="a");
            [ charge_tauto | tlaIntuition | ].
            eapply zero_deriv with (x:="V");
              [ charge_tauto | tlaIntuition | ].
            solve_linear; rewrite_next_st;
            solve_linear. }
          { solve_linear. rewrite H6. rewrite H4. rewrite H7.
            solve_linear. } }
      { match goal with
          |- _ |-- ?GG => eapply diff_ind
                          with (Hyps:=TRUE)
                                 (G:=unnext GG)
        end; try solve [ tlaIntuition |
                         unfold World; tlaAssume |
                         solve_linear ]. }
      { unfold World. eapply zero_deriv with (x:="T");
            [ charge_tauto | tlaIntuition | ].
        solve_linear. }
    - repeat charge_split.
      { solve_linear; rewrite_next_st; R_simplify; solve_linear. }
      { solve_linear; rewrite_next_st; R_simplify; solve_linear. }
      { fold BasicProofRules.next. unfold Discr, Ctrl, Max.
        decompose_hyps.
        { tlaAssert ("A" <= 0 \\// "A" >= 0);
          [ solve_linear | tlaIntro ].
          repeat decompose_hyps.
          apply lforallR. intro x.
          charge_split.
          - simpl. restoreAbstraction. charge_intros.
            tlaAssert (tdist "V"! "a"! x +
                       (sdist ("V"! + "a"!*x)) <=
                       tdist "Vmax" 0 d + sdist ("Vmax" + 0 * d)).
            + pose proof (tdist_sdist_incr "V"! "Vmax" "a"! 0 x d).
              charge_apply H. solve_linear.
            + solve_linear.
          - simpl. restoreAbstraction. charge_intros.
            tlaAssert ("Vmax" >= 0 \\// "Vmax" <= 0);
              [ solve_linear | tlaIntro ].
            decompose_hyps.
            + simpl. restoreAbstraction.
              tlaAssert (tdist "v" "A" x <= tdist "Vmax" 0 d).
              * pose proof (tdist_incr "v" "Vmax" "A" 0 x d).
                charge_apply H. solve_linear. rewrite_real_zeros.
                apply Rmult_0_le; solve_linear.
              * tlaIntro. solve_linear.
                eapply Rle_trans; eauto.
                repeat rewrite Rplus_assoc.
                apply Rplus_le_compat.
                { solve_linear. }
                { rewrite_next_st. eapply Rle_trans; eauto.
                  repeat rewrite <- Rplus_assoc. apply Rplus_le_r.
                  rewrite Rmult_assoc.
                  apply Rmult_0_le; solve_linear.
                  apply pow_0_le.
                  clear - amin_lt_0.
                  assert (/ amin < 0)%R by solve_linear.
                  solve_linear. }
            + tlaAssert ("y" <= ub).
              { rewrite <- inv_safe. charge_tauto. }
              { tlaAssert (tdist "v" "A" x <= 0).
                - pose proof (tdist_vel_neg "v" "A" x).
                  charge_apply H. solve_linear.
                  solve_nonlinear.
                - solve_linear. rewrite_next_st. solve_linear. }
          - tlaIntro. charge_split.
            + simpl; restoreAbstraction. tlaIntro.
              tlaAssert (tdist "V"! "a"! x +
                         (sdist ("V"! + "a"!*x)) <=
                         tdist "Vmax" "A" d +
                         sdist ("Vmax" + "A" * d)).
              *  pose proof (tdist_sdist_incr "V"! "Vmax"
                                              "a"! "A" x d).
                 charge_apply H. solve_linear.
              * solve_linear.
            + tlaAssert ("y" <= ub).
              * rewrite <- inv_safe. charge_tauto.
              * simpl; restoreAbstraction. tlaIntro.
                reason_action_tac. intuition.
                repeat match goal with
                       | [ H : eq (fst post _) _ |- _ ]
                         => try rewrite H in *; clear H
                       end.
                assert (fst pre "v" <= 0)%R;
                  [ solve_nonlinear | intros ].
                clear - H2 H3 H4 H1 H5. solve_nonlinear. }
          - unfold IndInv. unfold History.
            tlaIntro. charge_split; simpl; restoreAbstraction.
            + charge_intros.
              tlaAssert (0 <= "V" + "a" * tdiff).
              * solve_nonlinear.
              * tlaAssert (0 <= tdiff <= d);
                [ solve_linear | charge_intros ].
                reason_action_tac. intuition.
                specialize (H11 (fst pre "T" - fst pre "t"))%R.
                intuition.
                eapply Rle_trans; eauto.
                repeat match goal with
                       | [ H : eq (fst post _) _ |- _ ]
                         => rewrite H in *; clear H
                       end.
                rewrite Rplus_assoc.
                apply Rplus_le_compat.
                { solve_linear. }
                { pose proof (sdist_tdist_tdist "v" x).
                  breakAbstraction. unfold eval_comp in *;
                                    simpl in *.
                  specialize (H15 (Stream.Cons pre
                                               (Stream.Cons
                                                  post tr))).
                  intuition. simpl in *. eapply Rle_trans; eauto.
                  pose proof (sdist_incr "v" ("V" + "a"*tdiff)).
                  breakAbstraction. unfold eval_comp in *;
                                    simpl in *.
                  specialize (H15 (Stream.Cons pre
                                               (Stream.Cons
                                                  post tr))).
                  intuition. simpl in *.
                  apply H15; solve_nonlinear. }
            + tlaAssert ("v" >= 0 \\// "v" <= 0);
              [ solve_linear | tlaIntro ].
              decompose_hyps.
              { reason_action_tac. intuition.
                intuition.
                specialize (H9 (fst pre "T" - fst pre "t"))%R.
                intuition.
                repeat match goal with
                       | [ H : eq (fst post _) _ |- _ ]
                         => rewrite H in *; clear H
                       end.
                repeat match type of H23 with
                       | ?H -> _ =>
                         let HH := fresh "H" in
                         assert H as HH by solve_linear;
                           specialize (H23 HH); clear HH
                       end.
                eapply Rle_trans; eauto.
                apply Rplus_le_compat.
                { solve_linear. }
                { pose proof (sdist_tdist "v" x).
                  breakAbstraction. unfold eval_comp in *;
                                    simpl in *.
                  specialize (H13 (Stream.Cons pre
                                               (Stream.Cons
                                                  post tr))).
                  intuition. simpl in *. eapply Rle_trans; eauto.
                  pose proof (sdist_incr "v" ("V" + "a"*tdiff)).
                  breakAbstraction. unfold eval_comp in *;
                                    simpl in *.
                  specialize (H13 (Stream.Cons pre
                                               (Stream.Cons
                                                  post tr))).
                  intuition. simpl in *. apply H13;
                                         solve_nonlinear. } }
            { tlaAssert ("y" <= ub).
              - rewrite <- inv_safe. charge_tauto.
              - reason_action_tac. intuition.
                repeat match goal with
                     | [ H : eq (fst post _) _ |- _ ]
                       => rewrite H in *; clear H
                     end.
                eapply Rle_trans; eauto.
                clear - H3 amin_lt_0 H2 H6.
                solve_nonlinear. } }
      { solve_linear. }
      { solve_linear. }
  Qed.


(* This was an idea for showing that the system
   is a refinement of another system that does not have
   a continuous evolution but instead replaces the continous
   evolution with the solution to the differential equations.
   This is specified by Evolve. However, I couldn't
   figure out how to prove refinement. *)

(*
  Definition Evolve : Formula :=
         "y"! = "y" + tdist "v" "a" ("t" - "t"!)
    //\\ "v"! = "v" + "a"*("t" - "t"!).

  Definition AbstractNext :=
         Evolve
    \\// (Ctrl //\\ History).

  Definition AbstractSys : Formula :=
    I //\\ []AbstractNext.

  Theorem refinement :
    |-- Spec -->> AbstractSys.
  Proof.
    unfold Spec, SpecR, AbstractSys. charge_intros.
    charge_split.
    - charge_assumption.
    - unfold SysD. simpl. restoreAbstraction.
      unfold sysD. tlaRevert. apply BasicProofRules.always_imp.
      unfold Next, AbstractNext. charge_intros.
      decompose_hyps.
      + apply lorR1. unfold Evolve.
        *)

End SecondDerivShimCtrl.

Close Scope HP_scope.
Close Scope string_scope.