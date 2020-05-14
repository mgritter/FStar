(*
   Copyright 2020 Microsoft Research

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*)
module Steel.PCM.Memory
module F = FStar.FunctionalExtensionality
open FStar.FunctionalExtensionality
open Steel.PCM
module H = Steel.PCM.Heap

noeq
type lock_state : Type u#(a + 1) =
  | Invariant : H.slprop u#a -> lock_state

let lock_store : Type u#(a+1) = list (lock_state u#a)

noeq
type mem : Type u#(a + 1) =
  {
    ctr: nat;
    heap: H.heap u#a;
    locks: lock_store u#a;
  }

let heap_of_mem (x:mem) : H.heap = x.heap

let mem_of_heap (h:H.heap) : mem = {
  ctr = 0;
  heap = h;
  locks = []
}

let core_mem (m:mem) : mem = mem_of_heap (heap_of_mem m)

let disjoint (m0 m1:mem u#h)
  : prop
  = m0.ctr == m1.ctr /\
    H.disjoint m0.heap m1.heap /\
    m0.locks == m1.locks

let disjoint_sym m0 m1 = ()

let join m0 m1 = {
  ctr = m0.ctr;
  heap = H.join m0.heap m1.heap;
  locks = m0.locks
}

let join_commutative m0 m1 =
  H.join_commutative m0.heap m1.heap

let disjoint_join m0 m1 m2 =
  H.disjoint_join m0.heap m1.heap m2.heap

let join_associative m0 m1 m2 =
  H.join_associative m0.heap m1.heap m2.heap

let interp p m = H.interp p m.heap

let ref = H.ref

let emp : slprop u#a = H.emp
let pts_to = H.pts_to
let h_and = H.h_and
let h_or = H.h_or
let star = H.star
let wand = H.wand
let h_exists = H.h_exists
let h_forall = H.h_forall

////////////////////////////////////////////////////////////////////////////////
//properties of equiv
////////////////////////////////////////////////////////////////////////////////

let equiv_symmetric (p1 p2:slprop u#a) = H.equiv_symmetric p1 p2

#push-options "--warn_error -271"
let equiv_heap_iff_equiv (p1 p2:slprop u#a)
  : Lemma (ensures (H.equiv p1 p2 <==> equiv p1 p2))
          [SMTPat (equiv p1 p2)]
  = let aux_lr ()
      : Lemma
        (requires H.equiv p1 p2)
        (ensures equiv p1 p2)
        [SMTPat ()]
      = ()
    in
    let aux_rl_helper1 (h:H.heap)
      : Lemma
        (requires equiv p1 p2 /\ H.interp p1 h)
        (ensures H.interp p2 h)
        [SMTPat ()]
      = assert (interp p2 (mem_of_heap h))
    in
    let aux_rl_helper2 (h:H.heap)
      : Lemma
        (requires equiv p1 p2 /\ H.interp p2 h)
        (ensures H.interp p1 h)
        [SMTPat ()]
      = assert (interp p2 (mem_of_heap h))
    in
    let aux_rl ()
      : Lemma
        (requires equiv p1 p2)
        (ensures H.equiv p1 p2)
        [SMTPat ()]
      = () in
    ()

let equiv_heap_iff_equiv_forall ()
  : Lemma (ensures (forall p1 p2. H.equiv p1 p2 <==> equiv p1 p2))
  = let aux p1 p2
      : Lemma (ensures (H.equiv p1 p2 <==> equiv p1 p2))
              [SMTPat ()]
      = equiv_heap_iff_equiv p1 p2
    in
    ()
#pop-options

let equiv_extensional_on_star (p1 p2 p3:slprop u#a) =
  equiv_heap_iff_equiv_forall ();
  H.equiv_extensional_on_star p1 p2 p3

////////////////////////////////////////////////////////////////////////////////
//pts_to
////////////////////////////////////////////////////////////////////////////////

let pts_to_compatible (#a:Type u#a)
                      (#pcm:_)
                      (x:ref a pcm)
                      (v0 v1:a)
                      (m:mem u#a)
  = H.pts_to_compatible x v0 v1 (heap_of_mem m)

////////////////////////////////////////////////////////////////////////////////
// star
////////////////////////////////////////////////////////////////////////////////

let intro_star p q mp mq =
  H.intro_star p q (heap_of_mem mp) (heap_of_mem mq)

let star_commutative (p1 p2:slprop) =
  H.star_commutative p1 p2

let star_associative (p1 p2 p3:slprop) =
  H.star_associative p1 p2 p3

let star_congruence (p1 p2 p3 p4:slprop) =
  equiv_heap_iff_equiv_forall ();
  H.star_congruence p1 p2 p3 p4

let affine_star (p q:slprop) (m:mem) =
  H.affine_star p q (heap_of_mem m)

////////////////////////////////////////////////////////////////////////////////
// Invariants on the lock store
////////////////////////////////////////////////////////////////////////////////

let iname = nat
module S = FStar.Set
module L = FStar.List.Tot
let rec lock_store_invariant (e:inames) (l:lock_store u#a) : slprop u#a =
  let current_addr = L.length l - 1 in
  match l with
  | [] -> emp
  | Invariant p :: tl ->
    if current_addr `S.mem` e then
      lock_store_invariant e tl
    else
      p `star` lock_store_invariant e tl

let heap_ctr_valid (ctr:nat) (h:H.heap u#a) : H.a_heap_prop u#a =
  fun _ -> h `H.free_above_addr` ctr

let locks_invariant (e:inames) (m:mem u#a) : slprop u#a =
  H.h_refine (lock_store_invariant e m.locks)
             (heap_ctr_valid m.ctr (heap_of_mem m))

(***** Following lemmas are needed in Steel.Effect *****)

let core_mem_interp (hp:slprop u#a) (m:mem u#a) = ()

let interp_depends_only_on (hp:slprop u#a) = H.interp_depends_only_on hp

let h_exists_cong (#a:Type) (p q : a -> slprop)
    : Lemma
      (requires (forall x. p x `equiv` q x))
      (ensures (h_exists p `equiv` h_exists q))
    = equiv_heap_iff_equiv_forall ();
      H.h_exists_cong p q

////////////////////////////////////////////////////////////////////////////////
// Preorders and effects
////////////////////////////////////////////////////////////////////////////////
module PP = Steel.PCM.Preorder


////////////////////////////////////////////////////////////////////////////////
// Lifting heap actions
////////////////////////////////////////////////////////////////////////////////

let tot_pre_action_except (e:inames) (fp:slprop u#a) (a:Type u#b) (fp':a -> slprop u#a) =
  hmem_with_inv_except e fp -> (x:a & hmem_with_inv_except e (fp' x))

let tot_pre_action = tot_pre_action_except S.empty

let ac_reasoning_for_m_frame_preserving
    (p q r:slprop u#a) (m:mem u#a)
  : Lemma
    (requires interp ((p `star` q) `star` r) m)
    (ensures interp (p `star` r) m)
  = calc (equiv) {
    (p `star` q) `star` r;
       (equiv) { star_commutative p q;
                 equiv_extensional_on_star (p `star` q) (q `star` p) r }
    (q `star` p) `star` r;
       (equiv) { star_associative q p r }
    q `star` (p `star` r);
    };
    assert (interp (q `star` (p `star` r)) m);
    affine_star q (p `star` r) m

let is_frame_preserving
  (#e:inames)
  (#a:Type u#b)
  (#fp:slprop u#a)
  (#fp':a -> slprop u#a)
  (f:tot_pre_action_except e fp a fp') =
  forall (frame:slprop u#a) (m0:hmem_with_inv_except e (fp `star` frame)).
    (ac_reasoning_for_m_frame_preserving fp frame (locks_invariant e m0) m0;
     let (| x, m1 |) = f m0 in
     interp ((fp' x `star` frame) `star` locks_invariant e m1) m1 /\
     (forall (mp:mprop frame). mp (core_mem m0) == mp (core_mem m1)))

let tot_action_except (e:inames) (fp:slprop u#a) (a:Type u#b) (fp':a -> slprop u#a) =
  f:tot_pre_action_except e fp a fp'{ is_frame_preserving f }

let tot_action = tot_action_except S.empty

let linv e (m:mem) = locks_invariant e m

let hheap_of_hmem #fp #e (m:hmem_with_inv_except e fp)
  : h:H.hheap (fp `star` linv e m) { h `H.free_above_addr` m.ctr}
  = let h = heap_of_mem m in
    H.refine_interp (lock_store_invariant e m.locks)
                    (heap_ctr_valid m.ctr (heap_of_mem m)) h;
    h

let hmem_of_hheap #e (#fp0 #fp1:slprop) (m:hmem_with_inv_except e fp0)
                  (h:H.hheap (fp1 `star` linv e m) {
                       h `Heap.free_above_addr` m.ctr
                  })
    : m1:hmem_with_inv_except e fp1{linv e m `equiv` linv e m1}
    = let m1 : mem = { m with heap = h } in
      assert (interp (fp1 `star` linv e m) m1);
      star_commutative fp1 (linv e m);
      assert (interp (linv e m `star` fp1) m1);
      assert (linv e m1 ==  H.h_refine (lock_store_invariant e m1.locks)
                                       (heap_ctr_valid m1.ctr (heap_of_mem m1)));
      assert (linv e m ==  H.h_refine (lock_store_invariant e m1.locks)
                                      (heap_ctr_valid m1.ctr (heap_of_mem m)));
      H.refine_interp (lock_store_invariant e m1.locks)
                      (heap_ctr_valid m1.ctr (heap_of_mem m))
                      (heap_of_mem m);
      assert (forall h. (heap_ctr_valid m1.ctr (heap_of_mem m)) h <==>
                   (heap_ctr_valid m1.ctr (heap_of_mem m1)) h);
      H.refine_equiv (lock_store_invariant e m1.locks)
                     (lock_store_invariant e m1.locks)
                     (heap_ctr_valid m1.ctr (heap_of_mem m))
                     (heap_ctr_valid m1.ctr (heap_of_mem m1));
      assert (linv e m `equiv` linv e m1);
      let _ = equiv_extensional_on_star (linv e m) (linv e m1) fp1 in
      assert ((linv e m `star` fp1) `equiv` (linv e m1 `star` fp1));
      assert (interp (linv e m1 `star` fp1) m1);
      star_commutative (linv e m1) fp1;
      assert (interp (fp1 `star` linv e m1) m1);
      m1

let with_inv_except (m:mem) e (fp:slprop) = interp (fp `star` locks_invariant e m) m

#push-options "--warn_error -271"
let as_hprop (frame:slprop) (mp:mprop frame)
    : hp:H.hprop frame{forall m. mp (core_mem m) == hp (heap_of_mem m)}
    = let f = fun h -> mp (mem_of_heap h) in
      assert (forall m. mp (core_mem m) == f (heap_of_mem m));
      let aux (m0:H.hheap frame) (m1:H.heap{H.disjoint m0 m1})
        : Lemma
          (ensures (mem_of_heap (H.join m0 m1) == join (mem_of_heap m0) (mem_of_heap m1)))
          [SMTPat ()]
        = ()
      in
      f


let mprop_preservation_of_hprop_preservation
       (p:slprop) (m0 m1:mem)
    : Lemma
      (requires (forall (hp:H.hprop p). hp (heap_of_mem m0) == hp (heap_of_mem m1)))
      (ensures (forall (mp:mprop p). mp (core_mem m0) == mp (core_mem m1)))
    = let aux (mp:mprop p)
        : Lemma (mp (core_mem m0) == mp (core_mem m1))
          [SMTPat()]
        = assert (as_hprop p mp (heap_of_mem m0) == as_hprop p mp (heap_of_mem m1))
      in
      ()

let lift_heap_action (#fp:slprop) (#a:Type) (#fp':a -> slprop)
                     (e:inames)
                     ($f:H.action fp a fp')
  : tot_action_except e fp a fp'
  = let g : tot_pre_action_except e fp a fp' = fun m ->
        let h0 = hheap_of_hmem m in
        let (| x, h' |) = f h0 in
        (| x, hmem_of_hheap m h' |)
    in
    let aux (frame:slprop) (m0:hmem_with_inv_except e (fp `star` frame))
      : Lemma
        (ensures
          (ac_reasoning_for_m_frame_preserving fp frame (locks_invariant e m0) m0;
           let (| x, m1 |) = g m0 in
           interp ((fp' x `star` frame) `star` locks_invariant e m1) m1 /\
           (forall (mp:mprop frame). mp (core_mem m0) == mp (core_mem m1))))
        [SMTPat ()]
      = ac_reasoning_for_m_frame_preserving fp frame (locks_invariant e m0) m0;
        let (| x, m1 |) = g m0 in
        let h0 = hheap_of_hmem m0 in
        let (| x', h1 |) = f h0 in
        H.action_framing f (linv e m0) h0;
        assert (x == x');
        star_associative fp frame (linv e m0);
        H.action_framing f (frame `star` linv e m0) h0;
        assert (H.interp ((fp' x) `star` (frame `star` linv e m0)) h1);
        star_associative (fp' x) frame (linv e m0);
        assert (H.interp ((fp' x `star` frame) `star` linv e m0) h1);
        let h1' : H.hheap ((fp' x `star` frame) `star` linv e m0) = h1 in
        assert (m1 == hmem_of_hheap m0 h1');
        assert (with_inv_except m1 e (fp' x `star` frame));
        assert (forall (hp:H.hprop frame). hp h0 == hp h1);
        mprop_preservation_of_hprop_preservation frame m0 m1;
        ()
    in
    assert (is_frame_preserving g);
    g

let mem_evolves = admit()

let lift_tot_action #a #e #fp #fp' ($f:tot_action_except e fp a fp')
  : action_except a e fp fp'
  = admit()

let sel_action e r v0
  = lift_tot_action (lift_heap_action e (H.sel_action r v0))

let upd_action e r v0 v1
  = lift_tot_action (lift_heap_action e (H.upd_action r v0 v1))

let free_action e r v0
  = lift_tot_action (lift_heap_action e (H.free_action r v0))

let weaken (p q r:slprop) (h:H.hheap (p `star` q) { H.stronger q r })
  : H.hheap (p `star` r)
  = H.weaken p q r h; h

let weaken_refine (p:slprop) (q r:H.a_heap_prop)
  : Lemma
    (requires (forall h. q h ==> r h))
    (ensures H.stronger (H.h_refine p q) (H.h_refine p r))
  = let aux (h:H.heap)
        : Lemma (ensures (H.interp (H.h_refine p q) h ==> H.interp (H.h_refine p r) h))
                [SMTPat ()]
        = H.refine_interp p q h;
          H.refine_interp p r h
    in
    ()

let inc_ctr (#p:slprop) #e (m:hmem_with_inv_except e p)
  : m':hmem_with_inv_except e p{m'.ctr = m.ctr + 1 /\ H.stronger (linv e m) (linv e m')}
  = let m' : mem = { m with ctr = m.ctr + 1} in
    assert (interp (p `star` linv e m) m');
    assert (linv e m == H.h_refine (lock_store_invariant e m.locks)
                                   (heap_ctr_valid m.ctr (heap_of_mem m)));
    assert (linv e m' == H.h_refine (lock_store_invariant e m.locks)
                                    (heap_ctr_valid (m.ctr + 1) (heap_of_mem m)));
    H.weaken_free_above (heap_of_mem m) m.ctr (m.ctr + 1);
    weaken_refine (lock_store_invariant e m.locks)
                  (heap_ctr_valid m.ctr (heap_of_mem m))
                  (heap_ctr_valid (m.ctr + 1) (heap_of_mem m));
    assert (H.stronger (linv e m) (linv e m'));
    let _ = weaken p (linv e m) (linv e m') (heap_of_mem m) in
    m'

let frame_related_mems (fp0 fp1:slprop u#a) e (m0:hmem_with_inv_except e fp0) (m1:hmem_with_inv_except e fp1) =
    forall (frame:slprop u#a).
      interp ((fp0 `star` frame) `star` linv e m0) m0 ==>
      interp ((fp1 `star` frame) `star` linv e m1) m1 /\
      (forall (mp:mprop frame). mp (core_mem m0) == mp (core_mem m1))

let refined_pre_action e (fp0:slprop) (a:Type) (fp1:a -> slprop) =
  m0:hmem_with_inv_except e fp0 ->
  Pure (x:a &
        hmem_with_inv_except e (fp1 x))
       (requires True)
       (ensures fun  (| x, m1 |) ->
         frame_related_mems fp0 (fp1 x) e m0 m1)

let refined_pre_action_as_action (#fp0:slprop) (#a:Type) (#fp1:a -> slprop)
                                 #e ($f:refined_pre_action e fp0 a fp1)
  : tot_action_except e fp0 a fp1
  = let g : tot_pre_action_except e fp0 a fp1 = fun m -> f m in
    let aux (frame:slprop)
            (m0:hmem_with_inv_except e (fp0 `star` frame))
      : Lemma
        (ensures
          (ac_reasoning_for_m_frame_preserving fp0 frame (locks_invariant e m0) m0;
           let (| x, m1 |) = g m0 in
           interp ((fp1 x `star` frame) `star` locks_invariant e m1) m1 /\
          (forall (mp:mprop frame). mp (core_mem m0) == mp (core_mem m1))))
        [SMTPat ()]
      = ac_reasoning_for_m_frame_preserving fp0 frame (locks_invariant e m0) m0;
        let (| x', m1' |) = g m0 in
        let (| x, m1 |) = f m0 in
        assert (x == x' /\ m1 == m1')
    in
    g

let alloc_action #a #pcm e x
  = let f : refined_pre_action e emp (ref a pcm) (fun r -> pts_to r x)
      = fun m0 ->
        let h = hheap_of_hmem m0 in
        let (|r, h'|) = H.extend x m0.ctr h in
        let m' : hmem_with_inv_except e emp = inc_ctr m0 in
        let h' : H.hheap (pts_to #a r x `star` linv e m') = weaken _ (linv e m0) (linv e m') h' in
        let m1 : hmem_with_inv_except e (pts_to #a r x) = hmem_of_hheap m' h' in
        assert (forall frame. H.frame_related_heaps h h' emp (pts_to r x) frame true);
        let aux (frame:slprop)
          : Lemma
            (requires
               interp ((emp `star` frame) `star` linv e m0) m0)
            (ensures
               interp ((pts_to #a r x `star` frame) `star` linv e m1) m1 /\
               (forall (mp:mprop frame). mp (core_mem m0) == mp (core_mem m1)))
            [SMTPat (emp `star` frame)]
          = star_associative emp frame (linv e m0);
            assert (H.interp (emp `star` (frame `star` linv e m0)) h);
            assert (H.interp (pts_to #a r x `star` (frame `star` linv e m0)) h');
            star_associative (pts_to #a r x) frame (linv e m0);
            assert (H.interp ((pts_to #a r x `star` frame) `star` linv e m0) h');
            assert (H.stronger (linv e m0) (linv e m'));
            assert (H.equiv (linv e m') (linv e m1));
            assert (H.stronger (linv e m0) (linv e m1));
            let h' : H.hheap ((pts_to #a r x `star` frame) `star` linv e m1) = weaken _ (linv e m0) (linv e m1) h' in
            assert (H.interp ((pts_to #a r x `star` frame) `star` linv e m1) h');
            assert (forall (mp:H.hprop frame). mp h == mp h');
            mprop_preservation_of_hprop_preservation frame m0 m1;
            assert (forall (mp:mprop frame). mp (core_mem m0) == mp (core_mem m1))
        in
        assert (frame_related_mems emp (pts_to r x) e m0 m1);
        (| r, m1 |)
    in
    lift_tot_action (refined_pre_action_as_action f)


let ( >--> ) (i:iname) (p:slprop) : prop = admit()
let new_invariant (e:inames) (p:slprop) = admit()
