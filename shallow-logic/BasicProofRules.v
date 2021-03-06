Require Import Coq.omega.Omega.
Require Import ExtLib.Structures.Applicative.
Require Import ExtLib.Structures.Functor.
Require Import ExtLib.Structures.CoFunctor.
Require Import ChargeCore.Logics.ILogic.
Require Import ChargeCore.Logics.ILEmbed.
Require Import ChargeCore.Tactics.Tactics.
Require Import SLogic.Stream.
Require Import SLogic.Logic.
Require Import SLogic.Lifting.
Require Import SLogic.Instances.
Require Import SLogic.LTLNotation.

Section with_state.

  Variable state : Type.

  Let StateProp := StateProp state.
  Let ActionProp := ActionProp state.
  Let TraceProp := TraceProp state.

  Let next := @next state.
  Let starts := @starts state.
  Let always := @always state.
  Let eventually := @eventually state.

  Local Transparent ILInsts.ILFun_Ops.
  Local Transparent ILInsts.ILPre_Ops.

  (** Always Facts **)

  Lemma always_and : forall P Q,
      always P //\\ always Q -|- always (P //\\ Q).
  Proof.
    unfold always, Logic.always. simpl.
    split; repeat red.
    { intuition. }
    { intros; split; apply H. }
  Qed.

  Lemma always_or : forall P Q,
      always P \\// always Q |-- always (P \\// Q).
  Proof.
    unfold always, Logic.always. simpl.
    repeat red; intuition.
  Qed.

  Lemma always_impl : forall P Q,
      always (P -->> Q) |-- always P -->> always Q.
  Proof.
    unfold always, Logic.always. simpl.
    repeat red; intuition.
  Qed.

  Lemma always_tauto
    : forall G P, |-- P -> G |-- always P.
  Proof.
    compute; intuition.
  Qed.

  Lemma always_now :
    forall (P : TraceProp),
      always P |-- P.
  Proof.
    unfold always. simpl. intros.
    apply (H 0).
  Qed.

  Lemma always_idemp :
    forall (P : TraceProp),
      always (always P) -|- always P.
  Proof.
    unfold always, Logic.always. split; simpl; intros.
    { apply (H 0 n). }
    { specialize (H (n + n0)).
      erewrite Proper_trace_eq_iff; [ apply H | ].
      symmetry. apply nth_suf_plus. auto. }
  Qed.

  Lemma always_pre_post :
    forall (I : StateProp),
      always (starts (pre I)) -|-
      always (starts ((pre I) //\\ (post I))).
  Proof.
    intros; split; cbv beta iota zeta delta - [nth_suf];
    intros.
    { split; [ auto | ].
      specialize (H (n + 1)). unfold nth_suf in *.
      rewrite <- plus_n_O in H. assumption. }
    { apply H. }
  Qed.

  (* Facts about pre and starts *)
  Lemma pre_entails : forall (A B : StateProp),
      pre (A -->> B) |-- pre A -->> pre B.
  Proof.
    unfold pre. simpl. auto.
  Qed.

  Lemma starts_post :
    forall (P : ActionProp) (Q : StateProp),
      (forall st, P st |-- Q) ->
      |-- starts P -->> starts (post Q).
  Proof.
    unfold starts, post, Logic.starts.
    simpl; intros; eauto.
  Qed.

  Lemma and_forall : forall {T} (F G : T -> Prop),
      ((forall x, F x) /\ (forall x, G x)) <->
      (forall x, F x /\ G x).
  Proof. intros. clear. firstorder. Qed.

  Lemma starts_and :
    forall P Q, starts P //\\ starts Q -|- starts (P //\\ Q).
  Proof.
    intros. apply and_forall. intros.
    unfold starts, Logic.starts.
    simpl. intuition.
  Qed.

  Lemma starts_or :
    forall P Q, starts P \\// starts Q -|- starts (P \\// Q).
  Proof.
    unfold starts, Logic.starts; simpl; intros;
    split; simpl; eauto.
  Qed.

  Lemma starts_impl :
    forall P Q, starts P -->> starts Q -|- starts (P -->> Q).
  Proof.
    unfold starts, Logic.starts; simpl; intros;
    split; simpl; intros; eauto.
  Qed.

  Lemma starts_ex : forall T (P : T -> _),
      Exists x : T, starts (P x) -|- starts (lexists P).
  Proof.
    unfold starts; simpl; intros; split; simpl; eauto.
  Qed.

  Lemma starts_all : forall T (P : T -> _),
      Forall x : T, starts (P x) -|- starts (lforall P).
  Proof.
    unfold starts; simpl; intros; split; simpl; eauto.
  Qed.

  Lemma starts_tauto : forall (P : ActionProp),
      |-- P ->
      |-- starts P.
  Proof.
    compute. auto.
  Qed.

  Lemma pre_and :
    forall (P Q : StateProp),
      pre P //\\ pre Q -|- pre (P //\\ Q).
  Proof. reflexivity. Qed.

  Lemma pre_or :
    forall (P Q : StateProp),
      pre P \\// pre Q -|- pre (P \\// Q).
  Proof. reflexivity. Qed.

  Lemma post_and :
    forall (P Q : StateProp),
      post P //\\ post Q -|- post (P //\\ Q).
  Proof. reflexivity. Qed.

  Lemma post_or :
    forall (P Q : StateProp),
      post P \\// post Q -|- post (P \\// Q).
  Proof. reflexivity. Qed.

  Lemma next_and :
    forall (P Q : TraceProp),
      next P //\\ next Q -|- next (P //\\ Q).
  Proof. reflexivity. Qed.

  Lemma next_or :
    forall (P Q : TraceProp),
      next P \\// next Q -|- next (P \\// Q).
  Proof. reflexivity. Qed.

  Lemma next_starts_pre :
    forall (F : StateProp),
      next (starts (pre F)) -|- starts (post F).
  Proof. reflexivity. Qed.

  Lemma reason_action :
    forall (P : ActionProp),
      (forall st1 st2, P st1 st2) ->
      |-- starts P.
  Proof. intros. apply starts_tauto. simpl. auto. Qed.

  Lemma Exists_with_st :
    forall (T : Type) (G : TraceProp)
           (P : T -> TraceProp) (y : StateVal state T),
      (forall x : T, G |--
         starts (pre (lift2 eq (pure x) y)) -->> P x) ->
      G |-- Exists x : T, P x.
  Proof.
    unfold starts, Logic.starts, pre. simpl. intros.
    exists (y (hd t)). auto.
  Qed.

  (** This is standard discrete induction over time **)
  Lemma dind_lem : forall (P : TraceProp),
      |-- P -->> always (P -->> next P) -->> always P.
  Proof.
    unfold always, Logic.always, next, Logic.next.
    intros. do 3 red.
    intros. red. simpl.
    intros. induction n.
    { assumption. }
    { unfold tl in *. apply H1 in IHn.
      unfold nth_suf in *.
      erewrite Proper_trace_eq_iff.
      { exact IHn. }
      { unfold trace_eq. simpl. intros.
        rewrite <- plus_n_Sm. reflexivity. } }
  Qed.

  Theorem discrete_induction
    : forall G P T,
      G |-- always T ->
      G |-- P ->
      G |-- always (P -->> T -->> next P) ->
      G |-- always P.
  Proof.
    intros G P T. intros.
    generalize (dind_lem P).
    intros.
    charge_apply H2.
    charge_split.
    { assumption. }
    { apply Lemmas.lcut with (R:=G).
      { charge_assumption. }
      { rewrite H at 1. rewrite H1.
        rewrite <- Lemmas.uncurry.
        rewrite landC. rewrite Lemmas.uncurry.
        rewrite always_impl. charge_tauto. } }
  Qed.

End with_state.

Section simulations.
  Variables T U V : Type.
  Variable f : U -> T.
  Variable g : T -> V.

  Lemma focusS_compose :
    forall P,
      focusS f (focusS g P) -|- focusS (fun u => g (f u)) P.
  Proof. reflexivity. Qed.

  Lemma focusA_compose :
    forall P,
      focusA f (focusA g P) -|- focusA (fun u => g (f u)) P.
  Proof. reflexivity. Qed.

  Lemma focusT_compose :
    forall P,
      focusT f (focusT g P) -|- focusT (fun u => g (f u)) P.
  Proof. reflexivity. Qed.

  Lemma focusS_lift1 :
    forall (T U : Type) (op : T -> U) e,
    focusS f (lift1 op e) = lift1 op (focusS f e).
  Proof. reflexivity. Qed.

  Lemma focusS_lift2 :
    forall (T U V : Type) (op : T -> U -> V) e1 e2,
    focusS f (lift2 op e1 e2) =
    lift2 op (focusS f e1) (focusS f e2).
  Proof. reflexivity. Qed.

  Lemma focusS_lift3 :
    forall (T U V R : Type) (op : T -> U -> V -> R) e1 e2 e3,
    focusS f (lift3 op e1 e2 e3) =
    lift3 op (focusS f e1) (focusS f e2) (focusS f e3).
  Proof. reflexivity. Qed.

  Lemma focusA_lift1 :
    forall (T U : Type) (op : T -> U) e,
    focusA f (lift1 op e) = lift1 op (focusA f e).
  Proof. reflexivity. Qed.

  Lemma focusA_lift2 :
    forall (T U V : Type) (op : T -> U -> V) e1 e2,
    focusA f (lift2 op e1 e2) =
    lift2 op (focusA f e1) (focusA f e2).
  Proof. reflexivity. Qed.

  Lemma focusA_lift3 :
    forall (T U V R : Type) (op : T -> U -> V -> R) e1 e2 e3,
    focusA f (lift3 op e1 e2 e3) =
    lift3 op (focusA f e1) (focusA f e2) (focusA f e3).
  Proof. reflexivity. Qed.

  Lemma focusT_lift1 :
    forall (T U : Type) (op : T -> U) e,
    focusT f (lift1 op e) = lift1 op (focusT f e).
  Proof. reflexivity. Qed.

  Lemma focusT_lift2 :
    forall (T U V : Type) (op : T -> U -> V) e1 e2,
    focusT f (lift2 op e1 e2) =
    lift2 op (focusT f e1) (focusT f e2).
  Proof. reflexivity. Qed.

  Lemma focusT_lift3 :
    forall (T U V R : Type) (op : T -> U -> V -> R) e1 e2 e3,
    focusT f (lift3 op e1 e2 e3) =
    lift3 op (focusT f e1) (focusT f e2) (focusT f e3).
  Proof. reflexivity. Qed.

  Let focusS := focusS f (V:=Prop).
  Let focusA := focusA f (V:=Prop).
  Let focusT := focusT f (V:=Prop).

  (* TODO: what about focus and enabled? *)

  Lemma focusA_pre :
    forall P, focusA (pre P) = pre (focusS P).
  Proof. reflexivity. Qed.

  Lemma focusA_post :
    forall P, focusA (post P) = post (focusS P).
  Proof. reflexivity. Qed.

  Lemma focusT_starts :
    forall P, focusT (starts P) = starts (focusA P).
  Proof. reflexivity. Qed.

  Lemma focusS_ltrue :
    focusS ltrue = ltrue.
  Proof. reflexivity. Qed.

  Lemma focusA_ltrue :
    focusA ltrue = ltrue.
  Proof. reflexivity. Qed.

  Lemma focusT_ltrue :
    focusT ltrue = ltrue.
  Proof. reflexivity. Qed.

  Lemma focusS_lfalse :
    focusS lfalse = lfalse.
  Proof. reflexivity. Qed.

  Lemma focusA_lfalse :
    focusA lfalse = lfalse.
  Proof. reflexivity. Qed.

  Lemma focusT_lfalse :
    focusT lfalse = lfalse.
  Proof. reflexivity. Qed.

  Lemma focusS_and :
    forall P Q,
      focusS (P //\\ Q) = (focusS P //\\ focusS Q).
  Proof. reflexivity. Qed.

  Lemma focusA_and :
    forall P Q,
      focusA (P //\\ Q) = (focusA P //\\ focusA Q).
  Proof. reflexivity. Qed.

  Lemma focusT_and :
    forall P Q,
      focusT (P //\\ Q) = (focusT P //\\ focusT Q).
  Proof. reflexivity. Qed.

  Lemma focusS_or :
    forall P Q,
      focusS (P \\// Q) = (focusS P \\// focusS Q).
  Proof. reflexivity. Qed.

  Lemma focusA_or :
    forall P Q,
      focusA (P \\// Q) = (focusA P \\// focusA Q).
  Proof. reflexivity. Qed.

  Lemma focusT_or :
    forall P Q,
      focusT (P \\// Q) = (focusT P \\// focusT Q).
  Proof. reflexivity. Qed.

  Lemma focusS_impl :
    forall P Q,
      focusS (P -->> Q) = (focusS P -->> focusS Q).
  Proof. reflexivity. Qed.

  Lemma focusA_impl :
    forall P Q,
      focusA (P -->> Q) = (focusA P -->> focusA Q).
  Proof. reflexivity. Qed.

  Lemma focusT_impl :
    forall P Q,
      focusT (P -->> Q) = (focusT P -->> focusT Q).
  Proof. reflexivity. Qed.

  Lemma focusS_embed :
    forall P,
      focusS (embed P) = embed P.
  Proof. reflexivity. Qed.

  Lemma focusA_embed :
    forall P,
      focusA (embed P) = embed P.
  Proof. reflexivity. Qed.

  Lemma focusT_embed :
    forall P,
      focusT (embed P) = embed P.
  Proof. reflexivity. Qed.

  Lemma focusS_lforall :
    forall T P,
      focusS (lforall (T:=T) P) =
      lforall (fun t => focusS (P t)).
  Proof. reflexivity. Qed.

  Lemma focusA_lforall :
    forall T P,
      focusA (lforall (T:=T) P) =
      lforall (fun t => focusA (P t)).
  Proof. reflexivity. Qed.

  Lemma focusT_lforall :
    forall T P,
      focusT (lforall (T:=T) P) =
      lforall (fun t => focusT (P t)).
  Proof. reflexivity. Qed.

  Lemma focusS_lexists :
    forall T P,
      focusS (lexists (T:=T) P) =
      lexists (fun t => focusS (P t)).
  Proof. reflexivity. Qed.

  Lemma focusA_lexists :
    forall T P,
      focusA (lexists (T:=T) P) =
      lexists (fun t => focusA (P t)).
  Proof. reflexivity. Qed.

  Lemma focusT_lexists :
    forall T P,
      focusT (lexists (T:=T) P) =
      lexists (fun t => focusT (P t)).
  Proof. reflexivity. Qed.

  Lemma focusT_always :
    forall P,
      focusT (always P) = always (focusT P).
  Proof. reflexivity. Qed.

  Lemma focusT_eventually :
    forall P,
      focusT (eventually P) = eventually (focusT P).
  Proof. reflexivity. Qed.

End simulations.

Hint Rewrite -> focusS_compose focusA_compose focusT_compose
     focusS_lift1 focusS_lift2 focusS_lift3 focusA_lift1
     focusA_lift2 focusA_lift3 focusT_lift1 focusT_lift2
     focusT_lift3 focusA_pre focusA_post focusT_starts
     focusS_ltrue focusA_ltrue focusT_ltrue focusS_lfalse
     focusA_lfalse focusT_lfalse focusS_and focusA_and
     focusT_and focusS_or focusA_or focusT_or focusS_impl
     focusA_impl focusT_impl focusS_embed focusA_embed
     focusT_embed focusS_lforall focusA_lforall focusT_lforall
     focusS_lexists focusA_lexists focusT_lexists
     focusT_always focusT_eventually :
  rw_focus.

Hint Rewrite -> focusT_compose focusT_lift1 focusT_lift2
     focusT_lift3 focusT_starts focusT_ltrue focusT_lfalse
     focusT_and focusT_or focusT_impl focusT_embed
     focusT_lforall focusT_lexists focusT_always
     focusT_eventually :
  rw_focusT.

Ltac rewrite_focus :=
  autorewrite with rw_focus.

Ltac rewrite_focusT :=
  autorewrite with rw_focusT.

Section temporal_exists.

  Context {T U : Type}.

  Local Transparent ILInsts.ILFun_Ops.
  Local Transparent ILInsts.ILPre_Ops.

  (* This is rule E2 from the original TLA paper. *)
  Theorem texistsL :
    forall (P : TraceProp U) (Q : TraceProp (T * U)),
      Q |-- focusT snd P ->
      texists _ Q |-- P.
  Proof.
    intros. unfold texists.
    simpl. intros.
    destruct H0.
    eapply H in H0. auto.
  Qed.

  (* This is rule E1 from the original TLA paper. *)
  Theorem texistsR :
    forall (Q : TraceProp (T * U)) (f : StateVal U T),
      focusT (fun u => (f u, u)) Q |-- texists _ Q.
  Proof.
    intros Q f. unfold texists, Logic.texists, focusT.
    simpl. intros tr Hfocus.
    exists (fun n => f (tr n)).
    assumption.
  Qed.

  Theorem texists_texists :
    forall (V : Type) (P : TraceProp (V * (T * U))),
      texists T (texists V P) -|-
      texists (V * T) (cofmap (fun st =>
                                 (fst (fst st),
                                  (snd (fst st), snd st)))
                              P).
  Proof.
    intros V P. split; unfold texists; simpl; intros.
    { destruct H as [trT [trV H]].
      exists (trace_zip pair trV trT).
      unfold focusT, trace_zip in *. simpl in *.
      unfold fmap_trace, trace_ap, forever in *. simpl in *.
      assumption. }
    { destruct H as [trVT H].
      exists (fmap snd trVT). exists (fmap fst trVT).
      unfold focusT, trace_zip in *. simpl in *.
      unfold fmap_trace, trace_ap, forever in *. simpl in *.
      assumption. }
  Qed.

End temporal_exists.

Local Transparent ILInsts.ILFun_Ops.
Local Transparent ILInsts.ILPre_Ops.

Lemma trace_prop_land_texists :
  forall (T U : Type) (P : TraceProp U)
         (Q : TraceProp (T * U)),
    (P //\\ TExists T, Q) -|-
    TExists T, (focusT snd P) //\\ Q.
Proof.
  intros T U P Q. unfold texists.
  split; simpl; intros.
  { destruct H as [HP [tr' HQ]]. eauto. }
  { destruct H as [tr' [HP HQ]]. eauto. }
Qed.

Section history_variables.
  Local Open Scope LTL_scope.

  Theorem add_history {T U} (P : TraceProp T)
          (x : StateVal T U)
  : P -|- TExists (list U) ,
             focusT snd P //\\
             [!(fst `= pure nil)] //\\
             [][fst! `= !snd#x `:: !fst].
  Proof.
    split.
    - cbv beta iota zeta delta
          - [ Stream.hd Stream.tl plus Stream.nth_suf pre
                        post fst snd trace ].
      intros. compute. fold plus.
      exists (fmap_trace (List.map x) (prefix t)).
      split.
      + exact H.
      + split.
        * reflexivity.
        * intros.
          clear. induction n.
          { compute. reflexivity. }
          { cbv beta iota zeta delta
            - [ fmap_trace List.map plus prefix ] in *.
          replace (S n + 0) with (n + 1) by omega.
          rewrite IHn; clear IHn.
          replace (S n + 1) with (S (S n)) by omega.
          replace (n + 0) with (n) by omega.
          replace (n + 1) with (S n) by omega.
          reflexivity. }
    - apply texistsL. charge_tauto.
  Qed.

End history_variables.

Local Transparent ILInsts.ILFun_Ops.
Local Transparent ILInsts.ILPre_Ops.

Lemma focusT_snd_texists :
  forall (V T U : Type) (P : TraceProp (V * U)),
    texists _ (focusT (fun p => (fst p, snd (snd p))) P) |--
    focusT (snd (A:=T)) (texists V P).
Proof.
  intros. unfold focusT, texists. simpl. intros.
  destruct H as [tr' H].
  eexists. exact H.
Qed.

(* This is the proof rule described informally at
   the beginning of section 8.3.2 of the original
   TLA paper. *)
Theorem refinement_mapping :
  forall (T U V : Type) (Q : TraceProp (T * U))
         (P : TraceProp (V * U))
         (f : StateVal (T * U) V),
    Q |-- focusT (fun tu => (f tu, snd tu)) P ->
    texists _ Q |-- texists _ P.
Proof.
  intros. apply texistsL. rewrite <- focusT_snd_texists.
  rewrite <- texistsR. rewrite H.
  rewrite focusT_compose. instantiate (1:=f). reflexivity.
Qed.
