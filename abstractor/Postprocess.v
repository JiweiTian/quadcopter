Require Import Logic.Syntax.
Require Import Logic.Semantics.
Require Import Logic.ProofRules.
Require Import String.
Local Open Scope HP_scope.
Local Open Scope string_scope.
Require Import List.
Require Import Strings.String.
Import ListNotations.
Require Import Rdefinitions.
Require Import RelDec.
Require Import Coq.Reals.Rbase.
Require Import Z3.Tactic.
Require Import Abstractor.Embed.
Require Import FloatEmbed.
Require Import Logic.Automation.
Require Import Coq.Classes.Morphisms.
Require Import ExtLib.Tactics.

Lemma Z3Test : forall (a : R), (a + 1 = 3)%R%type -> ((a + 2 = 3)%R /\ ((1+1)%R=2%R)%R)%type.
Proof.
  intros.
  (* z3 solve. *)
  Abort.

(* Implementation of postprocessing automation for the Abstractor,
   using the Z3 plugin to simplify the terms produced b ythe abstractor *)

(* test case: proportional controller *)

(* c is constant and goal is 0 *)

Definition proportional_controller : fcmd :=
  FAsn "a" (FMinus (FConst fzero) (FVar "x")).

Definition proportional_controller_ivs : list (Var * Var) :=
  [("a", "a"); ("x", "x")].

(* "Pushing" Embed through connectives *)
Lemma lequiv_formula_iff :
  forall (P Q : Formula),
    (forall tr, eval_formula P tr <-> eval_formula Q tr) <->
    (P -|- Q).
Proof.
  intros.
  split.
  - intros. split; breakAbstraction; intros; apply H; assumption.
  - intros. unfold lequiv in H. destruct H.
    breakAbstraction.
    split; intros; [apply H | apply H0]; assumption.
Qed.

Ltac shatterAbstraction :=
  try apply lequiv_formula_iff; unfold lequiv in *; breakAbstraction.  

Lemma embed_push_TRUE :
  Embed (fun _ _ => True) -|- TRUE.
Proof.
  shatterAbstraction. tauto.
Qed.

Lemma embed_push_FALSE :
  Embed (fun _ _ => False) -|- FALSE.
Proof.
  shatterAbstraction. tauto.
Qed.

Lemma embed_push_And :
  forall (P1 P2 : _ -> _ -> Prop) (F1 F2 : Formula),
    Embed P1 -|- F1 -> Embed P2 -|- F2 ->
    Embed (fun x y => P1 x y /\ P2 x y) -|- F1 //\\ F2.
Proof.
  shatterAbstraction. intuition.
Qed.

Lemma embed_push_Or :
  forall (P1 P2 : _ -> _ -> Prop) (F1 F2 : Formula),
    Embed P1 -|- F1 -> Embed P2 -|- F2 ->
    Embed (fun x y => P1 x y \/ P2 x y) -|- F1 \\// F2.
Proof.
  shatterAbstraction. intuition.
Qed.

Lemma embed_push_Imp :
  forall (P1 P2 : _ -> _ -> Prop) (F1 F2 : Formula),
    Embed P1 -|- F1 -> Embed P2 -|- F2 ->
    Embed (fun x y => P1 x y -> P2 x y) -|- F1 -->> F2.
Proof.
  shatterAbstraction. intuition.
Qed.

Ltac fwd := forward_reason.

Lemma embed_push_Exists :
  forall (T : Type) (P : T -> state -> state -> Prop) (F : T -> Formula),
    (forall (t : T), Embed (P t) -|- F t) ->
    Embed (fun x y => exists (t : T), (P t x y)) -|- lexists F.
Proof.
  shatterAbstraction.
  intuition.
  fwd. specialize (H x). fwd.
  eexists. eauto.
  fwd. specialize (H x). fwd.
  eexists. eauto.
Qed.

Lemma embed_push_Forall :
  forall (T : Type) (P : T -> state -> state -> Prop) (F : T -> Formula),
    (forall (t : T), Embed (P t) -|- F t) ->
    Embed (fun x y => forall (t : T), (P t x y)) -|- lforall F.
Proof.
  intros.
  shatterAbstraction. intuition.
  eapply H. apply H0.
  eapply H. apply H0.  
Qed.

Lemma embed_push_Const : forall P, Embed (fun _ _ => P) -|- PropF P.
Proof.
  shatterAbstraction; tlaIntuition.
Qed.

(* Relation expressing a side-condition that must be used to push embed through arithmetic facts *)
Definition evals_to (f : Term) (f' : state -> state -> R) : Prop :=
  (eval_term f = f')%type.

Notation "f =|> g" := (evals_to f g) (at level 60).

(* comparison pushing *)
Lemma embed_push_Eq :
  forall l r l' r',
    l =|> l' ->
    r =|> r' ->
    Embed (fun x y => l' x y = r' x y)%type -|-
          Comp l r Eq.
Proof.
  intros.
  unfold evals_to in *. 
  shatterAbstraction. subst. reflexivity.
Qed.

Lemma embed_push_Gt :
  forall l r l' r',
    l =|> l' ->
    r =|> r' ->
    Embed (fun x y => Rgt (l' x y) (r' x y))%type -|-
          Comp l r Gt.
Proof.
  intros. unfold evals_to in *. shatterAbstraction. subst. reflexivity.
Qed.

Lemma embed_push_Ge :
  forall l r l' r',
    l =|> l' ->
    r =|> r' ->
    Embed (fun x y => Rge (l' x y) (r' x y))%type -|-
          Comp l r Ge.
Proof.
  intros.
  unfold evals_to in *. 
  shatterAbstraction. subst. reflexivity.
Qed.

Lemma embed_push_Lt :
  forall l r l' r',
    l =|> l' ->
    r =|> r' ->
    Embed (fun x y => Rlt (l' x y) (r' x y))%type -|-
          Comp l r Lt.
Proof.
  intros. unfold evals_to in *. shatterAbstraction. subst. reflexivity.
Qed.

Lemma embed_push_Le :
  forall l r l' r',
    l =|> l' ->
    r =|> r' ->
    Embed (fun x y => Rle (l' x y) (r' x y))%type -|-
          Comp l r Le.
Proof.
  intros. unfold evals_to in *. shatterAbstraction. subst. reflexivity.
Qed.

(* arithmetic pushing *)
Lemma arith_push_plus :
  forall l r l' r',
    l =|> l' ->
    r =|> r' ->
    PlusT l r =|> (fun x y => l' x y + r' x y)%R.
Proof.
  intros. unfold evals_to in *. shatterAbstraction. subst. reflexivity.
Qed.

Lemma arith_push_minus :
  forall l r l' r',
    l =|> l' ->
    r =|> r' ->
    MinusT l r =|> (fun x y => l' x y - r' x y)%R.
Proof.
  intros. unfold evals_to in *. shatterAbstraction. subst. reflexivity.
Qed.

Lemma arith_push_mult :
  forall l r l' r',
    l =|> l' ->
    r =|> r' ->
    MultT l r =|> (fun x y => l' x y * r' x y)%R.
Proof.
  intros. unfold evals_to in *. shatterAbstraction. subst. reflexivity.
Qed.

Lemma arith_push_inv :
  forall l l',
    l =|> l' ->
    InvT l =|> (fun x y => / (l' x y))%R.
Proof.
  intros. unfold evals_to in *. shatterAbstraction. subst. reflexivity.
Qed.

Lemma arith_push_cos :
  forall l l',
    l =|> l' ->
    CosT l =|> (fun x y => Rtrigo_def.cos (l' x y))%R.
Proof.
  intros. unfold evals_to in *. shatterAbstraction. subst. reflexivity.
Qed.

Lemma arith_push_sin :
  forall l l',
    l =|> l' ->
    SinT l =|> (fun x y => Rtrigo_def.sin (l' x y))%R.
Proof.
  intros. unfold evals_to in *. shatterAbstraction. subst. reflexivity.
Qed.

(* var, real *)
Lemma arith_push_VarNow :
  forall (x : Var),
    VarNowT x =|> fun st _ => st x.
Proof.
  reflexivity.
Qed.

Lemma arith_push_VarNext :
  forall (x : Var),
    VarNextT x =|> fun _ st' => st' x.
Proof.
  reflexivity.
Qed.

(* special cases for 0 and 1: want to compile these into nats,
   since nat are easier to work with *)
Lemma arith_push_Nat_zero :
    NatT 0 =|> fun _ _ => 0%R.
Proof. reflexivity. Qed.

Lemma arith_push_Nat_one :
    NatT 1 =|> fun _ _ => 1%R.
Proof. reflexivity. Qed.

Lemma arith_push_Nat :
  forall (n : nat),
    NatT n =|> fun _ _ => INR n.
Proof. reflexivity. Qed.

Lemma arith_push_Real :
  forall (r : R),
    RealT r =|> fun _ _ => r.
Proof. reflexivity. Qed.

(* for solving goals containing fupdate *)
Check fm_update.

(*
Lemma arith_push_fm_update_eq :
  forall (t: state -> state -> R) (v : Var) (X : Term) (f : state -> state -> state),
    X =|> t ->
    X =|> (fun x y : state => fupdate (f x y) v (t x y) v).
Proof.
  intros. unfold evals_to in *.
  rewrite H. unfold fupdate.
  rewrite rel_dec_eq_true; eauto with typeclass_instances.
Qed.

Lemma arith_push_fupdate_neq :
  forall (t: state -> state -> R) (v v' : Var) (X : Term) (f : state -> state -> istate),
    v <> v' ->
    X =|> (fun x y : state => f x y v') ->
    X =|> (fun x y : state => fupdate (f x y) v (t x y) v').
Proof.
  intros.
  unfold fupdate, evals_to in *. rewrite H0.
  rewrite rel_dec_neq_false; eauto with typeclass_instances.
Qed.
*)


Create HintDb embed_push discriminated.
Create HintDb arith_push discriminated.

Hint Rewrite
     embed_push_TRUE embed_push_FALSE
     embed_push_And embed_push_Or embed_push_Imp
     embed_push_Exists embed_push_Forall
     embed_push_Const
  : embed_push.

Hint Rewrite
     embed_push_Eq embed_push_Gt embed_push_Ge embed_push_Lt embed_push_Le
     using solve [eauto 20 with arith_push]
                         : embed_push.

(* for the "<>" goals created by arith_push_fupdate_neq *)
Hint Extern
     0 (_ <> _) => congruence : arith_push.

(* Other miscellaneous rewriting lemmas *)
Lemma AnyOf_singleton :
  forall (P : Prop), AnyOf [P] -|- P.
Proof.
  shatterAbstraction. tauto.
Qed.

Lemma AnyOf_weaken :
  forall (P : Prop) (Ps : list Prop),
    AnyOf Ps |-- AnyOf (P :: Ps).
Proof.
  shatterAbstraction. tauto.
Qed.

Lemma and_True_snip1 :
  forall (P : Prop),
    True //\\ P -|- P.
Proof.
  shatterAbstraction. tauto.
Qed.

Lemma and_True_snip2 :
  forall (P : Prop),
    P //\\ True -|- P.
Proof.
  shatterAbstraction. tauto.
Qed.

Lemma or_False_snip1 :
  forall (P : Prop),
    P \\// False -|- P.
Proof.
  shatterAbstraction. tauto.
Qed.

Lemma or_False_snip2 :
  forall (P : Prop),
    False \\// P -|- P.
Proof.
  shatterAbstraction. tauto.
Qed.

(* Very simple program for testing. We want to prove that x stays >0 *)
Definition float_one := Source.nat_to_float 1.
Definition simple_prog : fcmd :=
  FAsn "x" (FPlus (FConst float_one) (FVar "x")).

Definition simple_prog_ivs : list (Var) :=
  [("x")].

Definition simpler_prog : fcmd :=
  FAsn "x" (FConst float_one).

Lemma PropF_revert :
  forall (P : Prop) (G Q : Syntax.Formula),
    (P -> G |-- Q) ->
    (G |-- PropF P -->> Q).
Proof.
  tlaIntuition.
Qed.

Lemma PropF_pull :
  forall (P : Prop) (G Q : Syntax.Formula),
    P ->
    (G |-- Q) ->
    (PropF P -->> G |-- Q).
Proof.
  tlaIntuition.
Qed.

Require Import Bound.
Require Import Source.
Definition FP2RP (vs : list Var) (P : fstate -> Prop) : state -> Prop :=
  (fun st =>
     exists (fst : fstate), vmodels vs fst st /\ P fst).

(* Version of HoareA_embed_ex we can use for rewriting. *)
Require Import ExtLib.Tactics.
Import FloatEmbed.
Lemma Hoare__embed_rw :
  forall (c : fcmd)
         (vs : list string),
    (*var_spec_valid' vs ->*)
    (*varmap_check_fcmd vs c ->*)
    fembed_ex vs c |--
                Forall Q : fstate -> Prop,
  let P := fwp c Q in
  Embed (fun st st' : state =>
           (exists fst : fstate,
             vmodels vs fst st /\
             (P fst -> exists fst' : fstate, vmodels vs fst' st' /\ Q fst'))).
Proof.
  intros.
  breakAbstraction.
  intros.
  fwd.
  exists x0.
  split; auto.
  intros.
  eapply fwp_correct in H2.
  fwd.
  specialize (H3 _ H1).
  exists x1.
  split; auto.
Qed.

Definition FP2RP' (vs : list Var) (P : fstate -> Prop) (Q : Prop) : state -> Prop :=
  (fun st =>
     exists (fst : fstate), vmodels vs fst st /\ (P fst -> Q)).

Check FloatEmbed.embed_ex.

Lemma Hoare__embed_rw' :
  forall (c : fcmd)
         (vs : list Var),
    (*varmap_check_fcmd vs c ->*)
    FloatEmbed.embed_ex vs c |--
                Forall Q : fstate -> Prop,
  let P := fwp c Q in
  Embed (fun st st' : state =>
           FP2RP' vs P (exists fst' : fstate, vmodels vs fst' st' /\ Q fst') st).
Proof.
  generalize (Hoare__embed_rw); intro HHer.
  simpl in HHer.
  simpl.
  unfold FP2RP'.
  eapply HHer.
Qed.
Axiom Always_proper : Proper (lentails ==> lentails) Syntax.Always.
Existing Instance Always_proper.

(* Used to begin rewriting in our goal. *)
Lemma lequiv_rewrite_left :
  forall (A B C : Formula),
    A -|- C -> C |-- B -> A |-- B.
Proof.
  shatterAbstraction. intuition.  
Qed.

(* Convert a predicate over float states to a predicate over real states *)

(*
Definition FP2RP (P : fstate -> Prop) : state -> Prop :=
  (fun st =>
     exists (fst : fstate),
       (forall (v : Var) (f : float), fstate_lookup fst v = Some f ->
                                      exists r, F2OR f = Some r /\ st v = r) /\
       P fst).
 *)

(* Here is the thing I am trying to figure out *)
(*
Lemma FP2RP_rewrite :
  forall ivs,
  _ /\ (isFloat ivs _) -|- FP2RP ivs (fun st => ... (F2R x...)).
*)

(* this theorem is not true so try something that is, like always set x to 5; need invariant that x is float
   simple_prog_ivs will be given to is_float
 *)


(* Automation for rewriting Embeds *)
Hint Extern
     0 (_ =|> (fun _ _ => ?X)) => first [ apply arith_push_Nat_zero | apply arith_push_Nat_one
                                          | apply arith_push_Nat | apply arith_push_Real]
                                  : arith_push.

Hint Resolve
     arith_push_plus arith_push_minus arith_push_mult arith_push_inv
     arith_push_sin arith_push_cos
     arith_push_VarNow arith_push_VarNext
     (*arith_push_fupdate_eq arith_push_fupdate_neq*)
  : arith_push.

(* Automation for pushing through embed rewriting *)
Ltac crunch_embeds :=
  progress repeat
           match goal with
           | |- Embed (fun x y => vmodels _ _ _) -|- _ => reflexivity
           | |- Embed (fun x y => _ -> _) -|- _ => eapply embed_push_Imp
           | |- Embed (fun x y => _ \/ _) -|- _ => eapply embed_push_Or
           | |- Embed (fun x y => _ /\ _) -|- _ => eapply embed_push_And
           | |- Embed (fun x y => exists z, _) -|- _ => eapply embed_push_Exists; intro
           | |- Embed (fun x y => forall z, _) -|- _ => eapply embed_push_Forall; intro
           | |- Embed (fun x y => _ = _) -|- _ => eapply embed_push_Eq; eauto with arith_push
           | |- Embed (fun x y => (_ < _)%R) -|- _ => eapply embed_push_Lt; eauto with arith_push
           | |- Embed (fun x y => (_ <= _)%R) -|- _ => eapply embed_push_Le; eauto with arith_push
           | |- Embed (fun x y => (_ > _)%R) -|- _ => eapply embed_push_Gt; eauto with arith_push
           | |- Embed (fun x y => (_ >= _)%R) -|- _ => eapply embed_push_Ge; eauto with arith_push
           | |- Embed (fun x y => ?X) -|- _ => eapply embed_push_Const
           end.

(* Small logic lemmas for the subsequent theorem *)
Lemma lentail_cut1 :
  forall (A B C : Formula),
    C |-- A ->
    A -->> B |-- C -->> B.
Proof.
  intros. breakAbstraction. intuition.
Qed.

Lemma lentail_cut2 :
  forall (A B C D : Formula),
    C |-- A ->
    B |-- D ->
    (A -->> B |-- C -->> D).
Proof.
  intros. tlaIntuition.
Qed.

Lemma land_comm_left :
  forall (A B C : Formula),
    A //\\ B |-- C ->
    B //\\ A |-- C.
Proof.
  tlaIntuition.
Qed.

Lemma limpl_comm1 :
  forall (A B C D : Formula),
    A |-- B -->> C -->> D ->
    A |-- C -->> B -->> D.
Proof.
  tlaIntuition.
Qed.


(*Fact fwp_simple : |-- "x" > 0 //\\ [](oembed_fcmd simple_prog_ivs simple_prog_ivs simple_prog) -->> []("x" > 0).*)
Fact fwp_simpler : |-- "x" > 0 //\\ [](FloatEmbed.embed_ex simple_prog_ivs simpler_prog) -->> []("x" > 0).
Proof.
  erewrite -> Hoare__embed_rw.
  charge_intros.
  eapply discr_indX.
  { red; intuition. }
  { charge_assumption. }
  { charge_assumption. }
  {
    (* rhs *)
    rewrite landforallDL. eapply lforallL.
    instantiate (1 := (fun fst => exists f, fstate_lookup fst "x" = Some f /\ exists r, F2OR f = Some r /\ (r > 0)%R)).
    tlaRevert.
    simpl fwp.
    eapply lequiv_rewrite_left.

    {
      crunch_embeds.
    }


    apply lexistsL.
    intro.
    
    apply land_comm_left.
    apply landAdj.
    apply limpl_comm1.
    apply lentail_cut2.

    Require Import Coq.micromega.Psatz.
    {
      idtac.
      breakAbstraction.
      intros.
      exists float_one.
      split; try reflexivity.
      left.
      split; auto. 
      intros.
      generalize fstate_lookup_update_match; intro Hflum.
      symmetry in Hflum.
      rewrite Hflum.
      exists x0.
      split; try reflexivity.
      exists x1.
      split; auto.
      unfold F2OR, FloatToR in H0.
      destruct x0; try congruence.
      - lazy in H0. lazy in H1. (* contradiction *) psatz R.
      - lazy in H1. psatz R.
    }
    {
      breakAbstraction.
      intros.
      fwd.
      unfold vmodels, models in H.
      specialize (H "x"). fwd. unfold simple_prog_ivs in H. simpl in H.
      destruct H; auto. fwd.
      rewrite fstate_lookup_fm_lookup in H1.
      rewrite H1 in H. inversion H; subst.
      unfold asReal in H5. rewrite H2 in H5. inversion H5. lra.
    }
  }
Qed.

(*
Definition varValidPre (v : Var) : Syntax.Formula :=
  Embed (fun pre _ =>
           exists (f : float), (eq (F2OR f) (Some (pre v)))).

Definition varValidPost (v : Var) : Syntax.Formula :=
  Embed (fun _ post =>
           exists (f : float), (eq (F2OR f) (Some (post v)))).

Definition varValidBoth (v : Var) : Syntax.Formula :=
  varValidPre v //\\ varValidPost v.           
 *)

(* Embed (...) can't be a state formula, so here are versions that
   do not use it. *)

(* TODO: we can't encode these definitions in the current version of RTLA, I think. *)
(*
Definition varValidPre (v : Var) : Syntax.Formula :=
  Embed (fun pre _ =>
           exists (f : float), (eq (F2OR f) (Some (pre v)))).

Definition varValidPost (v : Var) : Syntax.Formula :=
  Embed (fun _ post =>
           exists (f : float), (eq (F2OR f) (Some (post v)))).

Definition varValidBoth (v : Var) : Syntax.Formula :=
  varValidPre v //\\ varValidPost v.           
 *)

(* Predicate capturing that the given variable is a float in the pre-state *)
(* todo, possibly: lift to variable maps? *)
Definition preVarIsFloat (v : Var) : Syntax.Formula :=
  Syntax.Exists float (fun (f : float) =>
                  Comp (RealT (FloatToR f)) (VarNowT v) Eq //\\
                       PropF (exists (r : R), eq (F2OR f) (Some r))).

Lemma sf_preVarIsFloat :
  forall (v : Var),
    is_st_formula (preVarIsFloat v).
Proof.
  intros.
  simpl.
  intuition.
Qed.

Lemma F2OR_FloatToR :
  forall (f : float) (r r' : R),
    F2OR f = Some r ->
    FloatToR f = r' ->
    r = r'.
Proof.
  intros.
  unfold F2OR, FloatToR in *.
  destruct f; try congruence.
Qed.

(* generalized version of Enabled_action, needed to prove
   enabledness goals *)
Lemma Enabled_action_gen
  : forall P Q : Syntax.Formula,
    (forall (st : state) (tr : trace),
        Semantics.eval_formula Q (Stream.Cons st tr) ->
        exists st' : state,
          Semantics.eval_formula P (Stream.Cons st (Stream.forever st'))) ->
    Q |-- Enabled P.
Proof.
  tlaIntuition.
  destruct tr.
  eapply H in H0.
  simpl.
  fwd.
  eauto.
Qed.

Lemma PropF_tauto :
  forall (P : Prop) F,
    P -> F |-- PropF P.
Proof.
  tlaIntuition.
Qed.

Check embed_ex.

(* to prove this we need a lemma about "states being iso on certain variables" *)
(* need to add weakest precondition hypothesis *)
Check fwp.
Lemma float_embed_ex_enabled :
  forall (vs : list Var) (prg : ast) (fst fst' : fstate) (st' : state),
    fwp prg (fun fst' => models vs fst' st') fst ->
    forall (st : state) (tr : trace),
      models vs fst st ->
      Semantics.eval_formula (Enabled (embed_ex vs prg)) (Stream.Cons st tr).
Proof.
  breakAbstraction.
  intros.
  apply fwp_correct in H. fwd.
  specialize (H1 _ H).
  exists (Stream.forever st').
  eauto.
Qed.

(*
Fact fwp_simpler_full : preVarIsFloat "x" //\\ "x" > 0 //\\
                                [](embed_ex simple_prog_ivs simpler_prog \\//
                                               (Enabled (embed_ex simple_prog_ivs simpler_prog) -->> lfalse))
                                |-- [](preVarIsFloat "x" //\\ "x" > 0).
Proof.
  eapply discr_indX.
  { red. simpl. intuition. }
  { charge_assumption. }
  { tlaIntuition. }

  tlaRevert.
  eapply lorL.
  {
    erewrite -> Hoare__embed_rw.
    eapply lforallL.
    instantiate (1 := (fun fst => exists f, fstate_lookup fst "x" = Some f /\ exists r, F2OR f = Some r /\ (r > 0)%R)).
    simpl fwp.
    cbv zeta.
    eapply lequiv_rewrite_left.
    { crunch_embeds. }
    apply lexistsL.
    intros.
    charge_intros.
    etransitivity.
    {
      charge_use.
      tlaRevert.
      apply landL1. (* get rid of the fact we used *)
      charge_intro.
      apply (lexistsR float_one).
      charge_split; [apply PropF_tauto; reflexivity|].
      charge_left.
      charge_split; [apply PropF_tauto; constructor|].
      charge_intros.
      apply (lexistsR x0).
      rewrite <- (fstate_lookup_update_match).
      charge_split; [apply PropF_tauto; reflexivity|].
      apply (lexistsR x1).
      charge_split; [charge_assumption|].
      match goal with
      | |- context[Fcore_defs.F2R ?X] => 
        let X2 := eval compute in (Fcore_defs.F2R X) in change (Fcore_defs.F2R X) with X2
      end.
      
      breakAbstraction.
      intros.
      lra.
    }
    {
      apply lexistsL. intros.
      breakAbstraction.
      intros. fwd.
      split.
      { do 2 red in H.
        specialize (H "x"). fwd.
        simpl in H. destruct H; auto. fwd.
        rewrite fstate_lookup_fm_lookup in H0. rewrite H0 in H. inversion H; subst.
        unfold asReal in H4. rewrite H1 in H4. inversion H4; subst.
        exists x3.
        split.
        - unfold F2OR in H1. destruct x3; congruence.
        - eauto.
      }
      {
        do 2 red in H.
        specialize (H "x"). fwd. simpl in H.
        destruct H; auto. fwd.
        rewrite fstate_lookup_fm_lookup in H0. rewrite H0 in H. inversion H; subst.
        unfold asReal in H4. rewrite H1 in H4. inversion H4; subst.
        assumption.
      }
    }
  }
  {
    (* enabledness tactic? *)
    charge_intro.
    transitivity lfalse; [| eapply lfalseL].
    charge_use.
    tlaRevert.
    eapply Lemmas.forget_prem.
    Require Import TLA.Tactics.
    charge_intro.
    eapply Enabled_action_gen.
    simpl.
    intros.
    clear tr.
    fwd.
    eapply (ex_state "x").
    eapply ex_state_any.
    unfold models.
    intros.
    
    (*intro st0. clear st0.*)
    generalize (F2OR_FloatToR _ _ _ H1 H); intro HF2OR.
    subst.

    eexists.
    exists ([("x", x)]).
    eexists.
    split.
    { split.
      - intros.
        simpl in H2. destruct H2; try contradiction. subst.
        exists x.
        split; auto.
      - intros. simpl.
        consider (string_dec s "x"); intros; subst; try reflexivity.
        simpl in H2.
        exfalso. auto.
    }
    { split; [|econstructor; simpl; reflexivity].
      intros. split.
      { intros.
        consider (string_dec "x" s); intros; subst.
        { unfold asReal. eexists. split; simpl; reflexivity. }
        { simpl in H2. destruct H2; [congruence|contradiction]. } }
      { intros.
        simpl.
        consider (string_dec s "x"); intros; subst; [|reflexivity].
        simpl in H2. destruct H2; auto. } } }
Qed.
*)

Lemma limpl_limpl_land :
  forall (A B C : Syntax.Formula),
    |-- A //\\ B -->> C ->
    |-- A -->> B -->> C.
Proof.
  tlaIntuition.
Qed.

(* velocity-shim controller *)
(*
Definition velshim : fcmd :=
  FIte (FMinus (FVar "ub") (FPlus (FMult (FVar "a") (FVar "d")) (FVar "vmax")))
       (FAsn "a" (FVar "a"))
       (FAsn "a" (FConst fzero)).
 *)

Definition f10 := Eval lazy in (concretize_float (nat_to_float 10)).

Definition velshim : fcmd :=
  FIte (FMinus (FConst f10) (FPlus (FMult (FVar "a") (FConst float_one)) (FVar "v")))
       (FAsn "a" (FConst fzero))
       (FAsn "a" (FVar "a")).

Print f10.
Locate f10.

Definition f9 := Eval lazy in (concretize_float (nat_to_float 9)).

Definition velshim2 : fcmd :=
  FIte (FMinus (FConst f9) (FPlus (FVar "a") (FVar "v")))
       (FAsn "a" (FConst fzero))
       (FAsn "a" (FVar "a")).

Definition velshim_vs : list (Var) :=
  ["a"; "v"].

(* TODO: prove thorem about always-enabledness of oembed_fcmd
     (true of any semantics embedded using oembedStep_maybenone, provided
     that any state has some other state it steps to) *)
(*
Lemma feval_never_stuck :
  forall (fs : fstate) (c : fcmd),
  exists (ofst : option fstate),
    feval fs c ofst.
Proof.
  intros fs c.
  generalize dependent fs.
  induction c.
  - intros.
    specialize (IHc1 fs). fwd.
    destruct x.
    + specialize (IHc2 f). fwd.
      eexists. econstructor 2; eassumption.
    + eexists. econstructor 3. eassumption.
  - intros. eexists. econstructor.
  - intros.
    consider (fexprD f fs); intros.
    + eexists. econstructor 4. eassumption.
    + eexists. econstructor 5. eassumption.
  - intros.
    consider (fexprD f fs); intros.
    + generalize (float_lt_ge_trichotomy f0 fzero); intro Htri.
      destruct Htri.
      * specialize (IHc1 fs). fwd. eexists. econstructor 6; eauto.
      * specialize (IHc2 fs). fwd. eexists. econstructor 7; eauto.
    + eexists. econstructor 8; eauto.
  - intros. eexists. econstructor.
  - intros. eexists. econstructor.
    Grab Existential Variables.
    apply fzero.
Qed.
*)

(*
(* TODO - prove these lemmas inline *)
Lemma oembed_fcmd_enabled :
  forall (ivs ovs : list (Var * Var)) (fc : fcmd),
    (|-- Enabled (oembed_fcmd ivs ovs fc)).
Proof.
  breakAbstraction.
  intros.
Abort.

(* Idea: oembedStep_maybenone will always be enabled so long as it is given an evaluation
   relation which is "never stuck" *)
Lemma oembedStep_maybenone_enabled :
  forall (var ast state : Type)
    (eval : state -> ast -> option state -> Prop)
    (asReal : state -> var -> option R)
    (pre_vars post_vars : list (Var * var))
    (prog : ast)
    (Heval : forall (a : ast) (st : state), exists (ost : option state), eval st a ost),
    (|-- Enabled (oembedStep_maybenone var ast state eval asReal pre_vars post_vars prog)).
Proof.
  intros.
  breakAbstraction.
  intros.
Abort.
*)

(* Used to expose post-states, since fwp by default does not let us talk about both
   pre- and post-states *)
Definition fstate_get_rval (v : Var) (P : R -> fstate -> Prop) (fs : fstate) : Prop :=
  match fstate_lookup fs v with
  | None => False
  | Some vf =>
    match F2OR vf with
    | None => False
    | Some vr => P vr fs
    end
  end.

(* Used to get pre-state variable values *)
Lemma inject_var :
  forall (s : Var) G P,
    (G |-- Forall x : R, (RealT x = VarNowT s)%HP -->> P) ->
    (G |-- P).
Proof.
  tlaIntuition.
  eapply H. eassumption.
  reflexivity.
Qed.

Ltac show_value val :=
  let x := eval compute in val in
      assert (val = x) by reflexivity.

Ltac try_it HH :=
  unfold premise;
  show_value error; show_value floatMin; show_value floatMax;
  intros;
  repeat match goal with
         | H: context[Fappli_IEEE.B2R ?x1 ?x2 ?x3] |- _ => 
           let X2 := eval lazy in (Fappli_IEEE.B2R x1 x2 x3) in change (Fappli_IEEE.B2R x1 x2 x3) with X2 in H
         end;
  repeat match goal with
         | H : context[Fcore_Raux.bpow ?x1 ?x2] |- _ =>
           let X2 := eval compute in (Fcore_Raux.bpow x1 x2) in
               change (Fcore_Raux.bpow x1 x2) with X2 in H
         end;
  repeat match type of HH with
         | context[nat_to_float ?x1]  =>
           idtac "1" x1 ; 
             let X2 := eval lazy in (nat_to_float x1) in
                 idtac "2" ;
               change (nat_to_float x1) with X2 in HH
         end;
  repeat match goal with
         | H : _ = _ |- _ => rewrite H in *
         end;
  try (z3 solve; admit).


(*
Fact fwp_velshim_full : preVarIsFloat "a" //\\ preVarIsFloat "v" //\\ 
                                      (embed_ex velshim_vs velshim)
                                                   (*(Enabled (embed_ex velshim_ivs velshim_ivs velshim) -->> lfalse))*)
                                      |-- (VarNextT "a" = 0 \\// "v" + ((VarNextT "a") * NatT 1) < NatT 10 )%HP.
 *)

Lemma land_curry1 :
  forall (A B C D : Syntax.Formula),
    A |-- (B //\\ C) -->> D ->
    A |-- B -->> C -->> D.
Proof.
  tlaIntuition.
Qed.

Ltac proveVarValid :=
  match goal with
  | |- isVarValid ?s ?v =>
    match goal with
    | H1: eq (fstate_lookup v s) (Some ?x) |- _ =>
      match goal with
      | H2: asReal x ?r |- _ =>
        unfold isVarValid, isFloatConstValid, F2OR; rewrite H1; unfold asReal in H2 ;
        consider x; simpl; auto; try congruence
      | H2: F2OR x = Some ?r |- _ =>
        unfold isVarValid, isFloatConstValid, F2OR; rewrite H1;
        consider x; simpl; auto; try congruence
      end
    end
  end.

Lemma fstate_lookup_fstate_lookup_force :
  forall (s : fstate) (v : Var) (f : float) (r : R),
    fstate_lookup s v = Some f ->
    asReal f r ->
    fstate_lookup_force s v = r.
Proof.
  intros.
  destruct f; unfold asReal, fstate_lookup_force in *; rewrite H; simpl in *; congruence.
Qed.

(* use firstN, skipN *)
Lemma hide_tail :
  forall {T : Type} (ls : list T),
    ls = match ls with
         | h :: t => h :: tl ls
         | nil => nil
         end.
Proof.
  induction ls; reflexivity.
Qed.

Check firstn.
Check firstn_skipn.      

(* use theorem to hide tail. then use cbv whitelist that doesn't
           reduce the tail *)

Definition bound_fexpr2 := bound_fexpr.
Opaque bound_fexpr2.

Transparent ILInsts.ILFun_Ops.
Require Import Coq.Logic.ClassicalFacts.
Axiom pe_ax : prop_extensionality.

(* Lemma used to automatically instantiate certain pattern of existentials *)
Lemma exists_eq_instantiate :
  forall {T : Type} (y : T) (P : T -> Prop),
    (exists x : T, Some x = Some y /\ P x) <-> P y.
Proof.
  intros.
  split.
  { intros. fwd. inversion H; subst; auto. }
  { intros. exists y. auto. }
Qed.

(* wrapped in propositional extensionality for faster rewriting *)
Lemma exists_eq_eq_instantiate :
  forall {T : Type} (y : T) (P : T -> Prop),
    (exists x : T, Some x = Some y /\ P x) = P y.
Proof.
  intros.
  apply pe_ax.
  apply exists_eq_instantiate.
Qed.

Ltac peel_bound_hyp H :=
  rewrite hide_tail in H;
  change bound_fexpr with bound_fexpr2 in H at 2;
  simpl in H;
  destruct H.

Ltac peel_bound_post H :=
  unfold land, lor, limpl, validFloat, lofst, lift2, error in H;
  repeat match goal with
         | H: context[Fcore_defs.F2R ?X] |- _ =>
           let Y := constr:(@Fcore_defs.F2R Fcore_Zaux.radix2 X) in
           let Y' := eval compute in Y in
               change Y with Y' in H
         end;
  repeat match goal with
         | H : context[Fcore_Raux.bpow ?x1 ?x2] |- _ =>
           let X2 := eval compute in (Fcore_Raux.bpow x1 x2) in
               change (Fcore_Raux.bpow x1 x2) with X2 in H
         end.

Ltac peel H :=
  peel_bound_hyp H;
  [peel_bound_post H | change bound_fexpr2 with bound_fexpr in H].

Lemma F2OR_FloatToR' :
  forall (f : float) (r : R),
    F2OR f = Some r ->
    FloatToR f = r.
Proof.
  destruct f; simpl; congruence.
Qed.

Lemma F2OR_weaken :
  forall f r, F2OR f = Some r -> FloatToR f = r.
Proof.
  destruct f; simpl; intros; congruence.
Qed.

Print velshim2.

Print feval.

(* used instead of admit for the goals we solve by Z3 *)
Axiom z3_says :
  forall (A : Prop), A.

(* first line is new stuff *)
(*
Fact fwp_velshim2_full : (Always ((VarNowT "a" < 100000%R)%HP //\\ (VarNowT "a" > (-100000)%R) //\\ (VarNowT "v" < 100000%R) //\\ (VarNowT "v" > (-100000)%R))) //\\
                                       preVarIsFloat "a" //\\ preVarIsFloat "v" //\\
                                       (embed_ex velshim_vs velshim2)
                                       |-- (VarNextT "a" = 0 \\// (VarNextT "v") + ((VarNextT "a") * NatT 1) < NatT 10)%HP.
 *)

Lemma AnyOf_app :
  forall (l1 l2 : list Prop),
    AnyOf (l1 ++ l2) <-> AnyOf l1 \/ AnyOf l2.
Proof.
  split.
  { induction l1; intros. 
    - auto.
    - simpl in *.
      destruct H; auto.
      rewrite or_assoc. auto. }
  { induction l1; intros.
    - simpl in *. destruct H; auto; contradiction.
    - simpl in *. rewrite or_assoc in H.
      destruct H; auto. }
Qed.

Ltac peel_bounds_hyp H n :=
  rewrite <- (firstn_skipn n) in H;
  apply AnyOf_app in H;
  change bound_fexpr with bound_fexpr2 in H at 2;
  simpl in H; (* simpl bound_fexpr? *)
  destruct H; [|change bound_fexpr2 with bound_fexpr in H].

Lemma pe_triv :
  forall (A : Prop),
    A -> (A = True).
Proof.
  intros.
  apply pe_ax. split; auto.
Qed.

Lemma varIsValid :
  forall (v : Var) (fs : fstate) (x : float),
    fstate_lookup fs v = Some x ->
    forall (r : R),
      F2OR x = Some r ->
      isVarValid v fs.
Proof.
  unfold isVarValid, isFloatConstValid, F2OR in *.
  intros. rewrite H. consider x; auto; congruence.
Qed.

Lemma varIsValid' :
  forall (v : Var) (fst : fstate),
    isVarValid v fst <->
    exists x, fstate_lookup fst v = Some x /\
         exists r, (eq (F2OR x) (Some r)).
Proof.
  split.
  {
    intros.
    unfold isVarValid, isFloatConstValid in *.
    consider (fstate_lookup fst v); intros; [|contradiction].
    consider f; intros; try contradiction.
    - eexists. split; [reflexivity|].
      eexists. simpl. reflexivity.
    - eexists. split; [reflexivity|].
      eexists. simpl. reflexivity.
  }
  {
    intros.
    fwd.
    unfold isVarValid, isFloatConstValid.
    rewrite H.
    unfold F2OR in *. consider x; intros; auto; congruence.
  }
Qed.

Lemma varIsValid'' :
  forall (v : Var) (fst : fstate),
    isVarValid v fst =
    exists x, fstate_lookup fst v = Some x /\
         exists r, (eq (F2OR x) (Some r)).
Proof.
  intros.
  apply pe_ax.
  apply varIsValid'.
Qed.


Theorem fwp_velshim2_full :
                                       preVarIsFloat "a" //\\ preVarIsFloat "v" //\\
                                       (embed_ex velshim_vs velshim2)
                                       |-- (VarNextT "a" = 0 \\// (VarNextT "v") + ((VarNextT "a") * NatT 1) < NatT 10)%HP.
Proof.
  rewrite landC. rewrite landA. rewrite landC. rewrite landA. rewrite landC.
  rewrite <- landC.
  tlaRevert.
  erewrite -> Hoare__embed_rw.
  {
    eapply lforallL.
    instantiate (1 := (fstate_get_rval "a" (fun a =>
                                              fstate_get_rval "v" (fun v _ => (a = 0 \/ v + a < 10)%R)))).
    cbv beta iota zeta delta [fwp velshim2 fexprD].
    eapply lequiv_rewrite_left.

    {
      crunch_embeds.
    }
    

    apply lexistsL. intros.

    apply land_comm_left.

    apply landAdj.
    apply land_curry1.

    apply lentail_cut2.

    { Opaque bound_fexpr.
      breakAbstraction.
      Transparent bound_fexpr.
      intros. forward_reason.
      unfold vmodels, velshim_vs, models in H.
      generalize (H "a"); intro Ha.
      destruct Ha as [Ha dead]; clear dead.
      destruct Ha; [left; reflexivity|].
      generalize (H "v"); intro Hv.
      destruct Hv as [Hv dead]; clear dead.
      destruct Hv; [intuition|].
      
      fwd. rewrite <- fstate_lookup_fm_lookup in H4, H5.
      cbv beta zeta iota delta
          [lift2 fplus fmult float_one fzero Fappli_IEEE.Bopp Fappli_IEEE.Bplus Fappli_IEEE.Bmult custom_prec custom_emax prec emax custom_nan].
      rewrite H4, H5.
      eexists.
      split; [reflexivity|].

      (* wtf?? *)


      split.
      {
        (* 9 - (a + v) < 0 -> 9 < a + v *)
        intros.
        eexists; split; [reflexivity|].
        simpl.
        left.
        split; auto.
        intros.
        unfold fstate_get_rval.
        rewrite <- fstate_lookup_update_match.
        rewrite H9.
        rewrite <- fstate_lookup_irrelevant_update; [|congruence].
        rewrite H5.
        unfold asReal in H6. rewrite H6.
        left. lra.
      }
      split.
      {
        (* 9 - (a + v) >= 0 -> 9 >= a + v *)
        intros.
        eexists; split; [reflexivity|].
        simpl.
        left.
        split; [proveVarValid |].
        intros.
        unfold fstate_get_rval.
        rewrite <- fstate_lookup_update_match.
        rewrite H9.
        rewrite <- fstate_lookup_irrelevant_update; [|congruence].
        rewrite H5.
        unfold asReal in H6.
        rewrite H6.

        

        (*peel_bounds_hyp H8 10.*)
        idtac.


        (* experimental evaluation *)

        (*
        cbv beta zeta iota delta [
              map cross bound_fexpr flat_map app lofst lift2
                  land lor limpl ILInsts.ILFun_Ops ILogicOps_Prop
                  bound_term fexpr_to_NowTerm combineTripleMinus combineTriplePlus combineTripleMult
                  eval_NowTerm
                  a_minus a_mult a_plus lb ub premise c_le c_lt c_ge c_gt
                  fzero f10
                  isFloatConstValid (*isVarValid*) fstate_lookup_force
                  Arithable_Applicative Fun.Applicative_Fun
                  Arithable_Lift Arithable_R
                  Comparable_Lift Comparable_R Comparable_Applicative
                  Applicative.pure Applicative.ap
                  simpleBound simpleBound2 simpleBound3 simpleBound4 simpleBound5
                  simpleBound6 simpleBound7 simpleBound8 simpleBound9 simpleBound10 simpleBound11 simpleBound12 simpleBound13
                  simpleBound14 simpleBound15 simpleBound16 simpleBound17 simpleBound18 simpleBound19 simpleBound20
                  simpleBound21 simpleBound22 simpleBound23 simpleBound24 simpleBound25 simpleBound26 simpleBound27
                  simpleBound28 simpleBound29 simpleBound30 simpleBound31 simpleBound32 simpleBound33
                  (*simpleBoundM1 simpleBoundM2 simpleBoundM3 simpleBoundM4*)
            ] in H8.
*)



        (* are if-statement fwp semantics wrong? do we need a
           "maybe-less/definitely-greater" kind of thing? *)
        
        Set Printing Depth 999. idtac.
                                     
        unfold maybe_ge0 in H8.
        simpl in H8.
        
        Ltac do_F2Rs :=
          match goal with
          | H: context[Fcore_defs.F2R ?X] |- _ =>
            let FR := fresh "FR" in
            let FRE := fresh "FRE" in
            remember (Fcore_defs.F2R X) as FR eqn: FRE;
              compute in FRE
          | |- context[Fcore_defs.F2R ?X] =>
            let FR := fresh "FR" in
            let FRE := fresh "FRE" in
            remember (Fcore_defs.F2R X) as FR eqn: FRE;
              compute in FRE
          end.

        do_F2Rs.

        (* find F2R's; remember them; pull them; compute them *)

        (* tactic for converting output of bound_term into a form Z3 can understand *)
        Ltac prepare_bound_hyp H :=
            unfold fstate_lookup_force, isVarValid, isFloatConstValid, asReal, lofst, error in *;
            repeat match goal with
                 | H1: eq (fstate_lookup ?x ?v) (Some _) |- _ => 
                   match goal with
                   | H2: context[match fstate_lookup x v with | _ => _ end] |- _ => rewrite H1 in H2
                   end
                 end;
            unfold floatMin, float_plus, floatToReal, error in H;
            repeat rewrite exists_eq_instantiate in H;
            unfold emax, emin, custom_emax, custom_emin, floatMax, f10 in H;
            repeat match goal with
                   | H' : context[Fcore_Raux.bpow ?x1 ?x2] |- _ =>
                     let X2 := eval compute in (Fcore_Raux.bpow x1 x2) in
                         change (Fcore_Raux.bpow x1 x2) with X2 in H'
                   end;
            repeat match goal with
               | H': context[Fcore_defs.F2R ?X] |- _ =>
                 let Y := constr:(@Fcore_defs.F2R Fcore_Zaux.radix2 X) in
                 let Y' := eval compute in Y in
                     change Y with Y' in H'
               end;
            repeat match goal with
                 | H1: (?x <= ?r <= ?x)%R |- _ => assert (x = r) by lra; clear H1
                   end;
            repeat match goal with
                   | H1 : eq (F2OR ?x) ?r |- _ =>
                     match goal with
                     | H2: eq (FloatToR x) ?r' |- _ =>
                       generalize (F2OR_FloatToR _ _ _ H1 H2); intro; clear H1
                     end end;
            repeat match goal with
                   | H1 : eq (F2OR ?x) ?r |- _ =>
                     apply F2OR_weaken in H1
                   end.
          
        (*z3 solve.*)
        (* you can use this tactic to solve this part but it's too slow *)
        (* experiment in minimizing proof term follows *)
        cbv beta zeta iota delta [
              map cross bound_fexpr flat_map app lofst lift2
                  land lor limpl ILInsts.ILFun_Ops ILogicOps_Prop
                  bound_term fexpr_to_NowTerm combineTripleMinus combineTriplePlus combineTripleMult
                  eval_NowTerm
                  a_minus a_mult a_plus lb ub premise c_le c_lt c_ge c_gt
                  fzero f10
                  isFloatConstValid (*isVarValid*) fstate_lookup_force
                  Arithable_Applicative Fun.Applicative_Fun
                  Arithable_Lift Arithable_R
                  Comparable_Lift Comparable_R Comparable_Applicative
                  Applicative.pure Applicative.ap
                  simpleBound simpleBound2 simpleBound3 simpleBound4 simpleBound5
                  simpleBound6 simpleBound7 simpleBound8 simpleBound9 simpleBound10 simpleBound11 simpleBound12 simpleBound13
                  simpleBound14 simpleBound15 simpleBound16 simpleBound17 simpleBound18 simpleBound19 simpleBound20
                  simpleBound21 simpleBound22 simpleBound23 simpleBound24 simpleBound25 simpleBound26 simpleBound27
                  simpleBound28 simpleBound29 simpleBound30 simpleBound31 simpleBound32 simpleBound33
                  (*simpleBoundM1 simpleBoundM2 simpleBoundM3 simpleBoundM4*)
            ] in H8.
        
        unfold fstate_lookup_force in *.


        unfold isVarValid in *.
        Set Printing Depth 999.
        idtac.

        repeat match goal with
               | H : fstate_lookup _ _ = Some _ |- _ =>
                 rewrite H in *; clear H
               end.

        unfold asReal in *.
        
        repeat match goal with
               | H : F2OR ?X = Some ?Y |- _ =>
                 apply F2OR_FloatToR' in H
               end.
        show_value floatMin.
        show_value floatMax.
        show_value error.

        assert (-100 < FloatToR x4 < 100)%R by admit.
        assert (-100 < FloatToR x5 < 100)%R by admit.

        simpl in H8.

        z3 solve. admit.
      }
      {

        simpl.

        repeat match goal with
               | |- context[isVarValid ?str ?sta] =>
                 let HV := fresh "Hvalid" in
                 assert (isVarValid str sta) as HV by proveVarValid;
                   rewrite (pe_triv _ HV)
               end.

        unfold fstate_lookup_force.
        repeat match goal with
               | H : fstate_lookup _ _ = Some _ |- _ =>
                 rewrite H in *; clear H
               end.

        unfold asReal in *.
        repeat match goal with
               | H : F2OR ?X = Some ?Y |- _ =>
                 apply F2OR_FloatToR' in H
               end.
        show_value floatMin.
        show_value floatMax.
        show_value error.
        unfold lift2, lofst.
        do_F2Rs.

        (* These will be solvable with arithmetic soon after some tweaks
           to the backend (bound.v) *)

        assert (-1000 < FloatToR x4 < 1000)%R by admit.
        assert (-1000 < FloatToR x5 < 1000)%R by admit.

        z3 solve. admit.
      }
      }
      {
        breakAbstraction.
        intros.
        unfold fstate_get_rval in *.
        fwd.
        consider (fstate_lookup x0 "a"); intros; try contradiction.
        consider (F2OR f); intros; try contradiction.
        consider (fstate_lookup x0 "v"); intros; try contradiction.        
        consider (F2OR f0); intros; try contradiction.
        unfold vmodels, models in *.
        generalize (H "a"); generalize (H "v"); intros.
        unfold velshim_vs in *.
        simpl in *.
        destruct H5; destruct H6.
        destruct H5;  auto.
        destruct H6; auto.
        fwd.
        rewrite <- fstate_lookup_fm_lookup in H5, H6.
        unfold asReal in *.
        rewrite H5 in H2. inversion H2.
        rewrite H6 in H0. inversion H0.
        subst.
        rewrite H1 in H9. inversion H9.
        rewrite H3 in H10. inversion H10.
        z3 solve.
        admit.
      }
Admitted.        

