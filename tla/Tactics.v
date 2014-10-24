Require Import Coq.micromega.Psatz.
Require Import TLA.Syntax.
Require Import TLA.Semantics.
Require Import TLA.Lib.
Require Import TLA.ProofRules.
Require Import Rdefinitions.

Ltac solve_linear :=
  simpl; intros; unfold eval_comp in *;
  simpl in *; intuition; try psatzl R.

Ltac solve_nonlinear :=
  simpl; intros; unfold eval_comp in *;
  simpl in *; intuition; try psatz R.

Open Scope HP_scope.

Ltac find_zeros eqs :=
  match eqs with
    | nil => constr:(@nil Var)
    | cons (DiffEqC ?y (ConstC (NatC O))) ?eqs =>
      let rest := find_zeros eqs in
      constr:(cons y rest)
    | cons _ ?eqs =>
      let rest := find_zeros eqs in
      rest
  end.

Ltac extract_unchanged eqs :=
  let xs := find_zeros eqs in
  let rec aux l :=
      match l with
        | nil => idtac
        | cons ?y ?l => apply zero_deriv
                        with (cp:=eqs) (x:=y);
                        try (aux l)
      end in
  aux xs.

Ltac get_var_inv F x :=
  match F with
    | And ?F1 _ =>
      get_var_inv F1 x
    | And _ ?F2 =>
      get_var_inv F2 x
    | Comp (next_term x) (next_term ?e) Eq => constr:(Comp x e Eq)
  end.

Ltac get_inv eqs F :=
  let xs := find_zeros eqs in
  let rec aux l :=
      match l with
        | nil => constr:(TRUE)
        | cons ?y ?l =>
          let y := constr:(TermC y) in
          let vinv := get_var_inv F y in
          let rest := aux l in
          constr:(And vinv rest)
        | cons _ ?l =>
          let rest := aux l in
          rest
      end in
  aux xs.

Ltac prove_diff_inv known :=
  match goal with
      |- context [ Continuous ?eqs ] =>
      match goal with
          |- (|- _ --> Comp (next_term ?t1) (next_term ?t2) ?op) =>
          apply diff_ind with
          (Hyps:=known) (G:=Comp t1 t2 op) (cp:=eqs); try solve [solve_linear]
      end
  end.

Close Scope HP_scope.