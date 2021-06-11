module Steel.Pointer

(* An interface for C pointers and pointer arithmetic for C arrays. *)

open Steel.Memory
open Steel.FractionalPermission
open Steel.Effect
open Steel.Effect.Atomic

include Steel.CStdInt

[@@erasable]
val base_array (a: Type0) : Tot Type0

val base_array_len
  (#a: Type0)
  (b: base_array a)
: Ghost size_t
  (requires True)
  (ensures (fun res -> size_v res > 0))

val base_array_freeable
  (#a: Type0)
  (b: base_array a)
: Tot prop

val t (a: Type0) : Tot Type0

val null (a: Type0) : Tot (t a)

val g_is_null (#a: Type0) (p: t a) : Ghost bool
  (requires True)
  (ensures (fun res -> res == true <==> p == null a))

val base
  (#a: Type0)
  (p: t a)
: Pure (base_array a)
  (requires (g_is_null p == false))
  (ensures (fun _ -> True))

val offset
  (#a: Type0)
  (p: t a)
: Ghost size_t
  (requires (g_is_null p == false))
  (ensures (fun res ->
    size_v res <= size_v (base_array_len (base p))
  ))

val base_offset_inj
  (#a: Type0)
  (p1 p2: t a)
: Lemma
  (requires (g_is_null p1 == false /\ g_is_null p2 == false /\ base p1 == base p2 /\ offset p1 == offset p2))
  (ensures (p1 == p2))

val g_add
  (#a: Type0)
  (p: t a)
  (off: size_t)
: Ghost (t a)
  (requires (g_is_null p == false /\ size_v (offset p) + size_v off <= size_v (base_array_len (base p))))
  (ensures (fun res ->
    g_is_null res == false /\
    base res == base p /\
    size_v (offset res) == size_v (offset p) + size_v off
  ))

val g_sub
  (#a: Type0)
  (p: t a)
  (off: size_t)
: Ghost (t a)
  (requires (g_is_null p == false /\ size_v (offset p) >= size_v off))
  (ensures (fun res ->
    g_is_null res == false /\
    base res == base p /\
    size_v (offset res) == size_v (offset p) - size_v off
  ))

let g_le
  (#a: Type0)
  (p1 p2: t a)
: Tot prop
= g_is_null p1 == false /\
  g_is_null p2 == false /\
  base p1 == base p2 /\
  size_v (offset p1) <= size_v (offset p2)

(*
val g_diff
  (#a: Type0)
  (p1 p2: t a)
: Ghost ptrdiff_t
  (requires (g_is_null p1 == false /\ g_is_null p2 == false /\ base p1 == base p2 /\ ptrdiff_precond (size_v (offset p2) - size_v (offset p1))))
  (ensures (fun y -> ptrdiff_v y == size_v (offset p2) - size_v (offset p1)))
*)

[@@erasable]
noeq
type range = {
  range_from: int;
  range_to: int;
  range_write_perm: perm;
  range_free_perm: perm;
  range_prf: squash (range_from <= 0 /\ 0 <= range_to);
}

let ptr_range = (x: range { x.range_from == 0 /\ x.range_to == 1 })

val slptr_range
  (#a: Type)
  (x: t a)
  (r: range)
: Tot (slprop u#1)

val ptr_select
  (#a: Type)
  (x: t a)
  (r: range)
: Tot (selector (Seq.lseq a (r.range_to - r.range_from)) (slptr_range x r))

[@@ __steel_reduce__ ]
let vptr_range'
  (#a: Type)
  (x: t a)
  (r: range)
: Tot vprop'
= {
  hp = slptr_range x r;
  t = Seq.lseq a (r.range_to - r.range_from);
  sel = ptr_select x r;
}

[@@ __steel_reduce__ ]
let vptr_range
  (#a: Type)
  (x: t a)
  (r: range)
: Tot vprop
= VUnit (vptr_range' x r)

val vptr_range_not_null
  (#opened: _)
  (#a: Type)
  (x: t a)
  (r: range)
: SteelGhost unit opened
    (vptr_range x r)
    (fun _ -> vptr_range x r)
    (fun _ -> True)
    (fun h _ h' ->
      h' (vptr_range x r) == h (vptr_range x r) /\
      g_is_null x == false
    )

let mk_range
  (from: int)
  (to: int)
  (write_perm free_perm: perm)
: Pure range
  (requires (from <= 0 /\ 0 <= to))
  (ensures (fun _ -> True))
= {
  range_from = from;
  range_to = to;
  range_write_perm = write_perm;
  range_free_perm = free_perm;
  range_prf = ();
}

[@@ __steel_reduce__]
unfold
let ptr_sel (#a:Type) (#p:vprop) (r: ptr_range) (x: t a)
  (h:rmem p{FStar.Tactics.with_tactic selector_tactic (can_be_split p (vptr_range x r))})
: GTot a 
= Seq.index (h (vptr_range x r)) 0

[@@ __steel_reduce__]
unfold
let ptr_sel0 (#a:Type) (#p:vprop) (r: ptr_range) (x: t a)
  (h:rmem p{ (can_be_split p (vptr_range x r))})
: GTot a 
= Seq.index (h (vptr_range x r)) 0

let vptr_range_or_null
  (#a: Type)
  (x: t a)
  (r: range)
: Tot vprop
= if g_is_null x then emp else vptr_range x r

val is_null
  (#opened: _)
  (#a: Type)
  (x: t a)
  (r: range)
: SteelAtomic bool opened
    (vptr_range_or_null x r)
    (fun _ -> vptr_range_or_null x r)
    (fun _ -> True)
    (fun h res h' ->
      h' (vptr_range_or_null x r) == h (vptr_range_or_null x r) /\
      res == g_is_null x
    )

let assert_null
  (#opened: _)
  (#a: Type)
  (x: t a)
  (r: range)
: SteelGhost unit opened
    (vptr_range_or_null x r)
    (fun _ -> emp)
    (fun _ -> g_is_null x == true)
    (fun _ _ _ -> True)
=
  change_equal_slprop
    (vptr_range_or_null x r)
    emp

let assert_not_null
  (#opened: _)
  (#a: Type)
  (x: t a)
  (r: range)
: SteelGhost unit opened
    (vptr_range_or_null x r)
    (fun _ -> vptr_range x r)
    (fun _ -> g_is_null x == false)
    (fun h _ h' ->
      g_is_null x == false /\
      h' (vptr_range x r) == h (vptr_range_or_null x r)
    )
=
  assert (g_is_null x == false);
  change_equal_slprop
    (vptr_range_or_null x r)
    (vptr_range x r)

let calloc_range
  (len: size_t)
: Tot range
= mk_range 0 (size_v len) full_perm full_perm

val calloc
  (#a: Type)
  (x: a)
  (len: size_t)
: Steel (t a)
    emp
    (fun res -> vptr_range_or_null res (calloc_range len))
    (fun _ -> size_v len > 0)
    (fun _ res h' ->
      if g_is_null res
      then True
      else begin
        base_array_freeable (base res) /\
        base_array_len (base res) == len /\
        size_v (offset res) == 0 /\
        h' (vptr_range res (calloc_range len)) == Seq.create (size_v len) x
      end
    )

let malloc_range
: ptr_range
= calloc_range one_size

let malloc
  (#a: Type)
  (x: a)
: Steel (t a)
    emp
    (fun res -> vptr_range_or_null res malloc_range)
    (fun _ -> True)
    (fun _ res h' ->
      if g_is_null res
      then True
      else begin
        base_array_freeable (base res) /\
        size_v (base_array_len (base res)) == 1 /\
        size_v (offset res) == 0 /\
        ptr_sel0 malloc_range res h' == x
      end
    )
 = calloc x one_size

val free
  (#a: Type)
  (x: t a)
  (r: range)
: Steel unit
    (vptr_range x r)
    (fun _ -> emp)
    (fun _ ->
      g_is_null x == false ==> (
      let b : base_array a = base x in
      base_array_freeable b /\
      size_v (offset x) == 0 /\
      r.range_write_perm == full_perm /\
      r.range_free_perm == full_perm /\
      r.range_from == 0 /\
      r.range_to == size_v (base_array_len b)
    ))
    (fun _ _ _ -> True)

(* pointer arithmetic *)

val add
  (#opened: _)
  (#a: Type)
  (x: t a)
  (r: range)
  (i: size_t)
: SteelAtomic (t a) opened
    (vptr_range x r)
    (fun _ -> vptr_range x r)
    (fun _ ->
      size_v i <= r.range_to
    )
    (fun h res h' ->
      h' (vptr_range x r) == h (vptr_range x r) /\
      g_is_null x == false /\
      size_v (offset x) + size_v i <= size_v (base_array_len (base x)) /\
      res == g_add x i
    )

val sub
  (#opened: _)
  (#a: Type)
  (x: t a)
  (r: range)
  (i: size_t)
: SteelAtomic (t a) opened
    (vptr_range x r)
    (fun _ -> vptr_range x r)
    (fun _ ->
      r.range_from <= 0 - size_v i
    )
    (fun h res h' ->
      h' (vptr_range x r) == h (vptr_range x r) /\
      g_is_null x == false /\
      size_v (offset x) >= size_v i /\
      res == g_sub x i
    )

val index
  (#a: Type)
  (x: t a)
  (r: range)
  (i: ptrdiff_t)
: Steel a
    (vptr_range x r)
    (fun _ -> vptr_range x r)
    (fun _ ->
      r.range_from <= ptrdiff_v i /\
      ptrdiff_v i < r.range_to
    )
    (fun h res h' ->
      let s = h (vptr_range x r) in
      h' (vptr_range x r) == s /\
      r.range_from <= ptrdiff_v i /\
      ptrdiff_v i < r.range_to /\
      res == Seq.index s (ptrdiff_v i - r.range_from)
    )

let deref
  (#a: Type)
  (x: t a)
  (r: ptr_range)
: Steel a
    (vptr_range x r)
    (fun _ -> vptr_range x r)
    (fun _ -> True)
    (fun h res h' ->
      h' (vptr_range x r) == h (vptr_range x r) /\
      res == ptr_sel0 r x h
    )
= index x _ zero_ptrdiff 

val iupd
  (#a: Type)
  (x: t a)
  (r: range)
  (i: ptrdiff_t)
  (v: a)
: Steel unit
    (vptr_range x r)
    (fun _ -> vptr_range x r)
    (fun _ ->
      r.range_from <= ptrdiff_v i /\
      ptrdiff_v i < r.range_to
    )
    (fun h _ h' ->
      r.range_from <= ptrdiff_v i /\
      ptrdiff_v i < r.range_to /\
      h' (vptr_range x r) == Seq.upd (h (vptr_range x r)) (ptrdiff_v i - r.range_from) v
    )

let upd
  (#a: Type)
  (x: t a)
  (r: ptr_range)
  (v: a)
: Steel unit
    (vptr_range x r)
    (fun _ -> vptr_range x r)
    (fun _ -> True)
    (fun _ _ h' ->
      ptr_sel0 r x h' == v
    )
= iupd x r zero_ptrdiff v

[@@erasable]
noeq
type gpair (a1 a2: Type) : Type = | GPair: (fst: a1) -> (snd: a2) -> gpair a1 a2

let g_merge
  (#a: Type)
  (p1 p2: t a)
  (r: gpair range range)
: Pure range
  (requires (
    let GPair r1 r2 = r in
    g_is_null p1 == false /\
    g_is_null p2 == false /\
    base p1 == base p2 /\
    (size_v (offset p1) + r1.range_to == size_v (offset p2) + r2.range_from \/
      size_v (offset p2) + r2.range_to == size_v (offset p1) + r1.range_from) /\
    r1.range_write_perm == r2.range_write_perm
  ))
  (ensures (fun _ -> True))
= 
  let GPair r1 r2 = r in
  if size_v (offset p1) + r1.range_to = size_v (offset p2) + r2.range_from
  then {
    range_from = r1.range_from;
    range_to = r2.range_to - size_v (offset p1) + size_v (offset p2);
    range_write_perm = r1.range_write_perm;
    range_free_perm = r1.range_free_perm `sum_perm` r2.range_free_perm;
    range_prf = ();
  } else {
    range_from = r2.range_from - size_v (offset p1) + size_v (offset p2);
    range_to = r1.range_to;
    range_write_perm = r1.range_write_perm;
    range_free_perm = r1.range_free_perm `sum_perm` r2.range_free_perm;
    range_prf = ();
  }

val merge
  (#opened: _)
  (#a: Type)
  (p1 p2: t a)
  (r1 r2: range)
: SteelGhost range opened
    (vptr_range p1 r1 `star` vptr_range p2 r2)
    (fun res -> vptr_range p1 res)
    (fun _ ->
      (g_is_null p1 == false /\ g_is_null p2 == false) ==> (
      base p1 == base p2 /\
      (size_v (offset p1) + r1.range_to == size_v (offset p2) + r2.range_from \/
        size_v (offset p2) + r2.range_to == size_v (offset p1) + r1.range_from) /\
      r1.range_write_perm == r2.range_write_perm
    ))
    (fun h res h' ->
      g_is_null p1 == false /\ g_is_null p2 == false /\
      base p1 == base p2 /\
      (size_v (offset p1) + r1.range_to == size_v (offset p2) + r2.range_from \/
        size_v (offset p2) + r2.range_to == size_v (offset p1) + r1.range_from) /\
      r1.range_write_perm == r2.range_write_perm /\
      res == g_merge p1 p2 (GPair r1 r2) /\
      h' (vptr_range p1 res) == h (vptr_range p1 r1) `Seq.append` h (vptr_range p2 r2)
    )

let g_split
  (#a: Type)
  (p: t a)
  (r: range)
: Pure (range `gpair` range)
  (requires (
    g_is_null p == false
  ))
  (ensures (fun _ -> True))
= ({
    range_from = r.range_from;
    range_to = 0;
    range_write_perm = r.range_write_perm;
    range_free_perm = half_perm r.range_free_perm;
    range_prf = ();
  }) `GPair` ({
    range_from = 0;
    range_to = r.range_to;
    range_write_perm = r.range_write_perm;
    range_free_perm = half_perm r.range_free_perm;
    range_prf = ();
  })

#restart-solver

let g_split_correct
  (#a: Type)
  (p: t a)
  (r: range)
: Lemma
  (requires (
    g_is_null p == false
  ))
  (ensures (
    let GPair r1 r2 = g_split p r in
    g_merge p p (g_split p r) == r
  ))
  [SMTPat (g_merge p p (g_split p r))]
 = ()

val split
  (#opened: _)
  (#a: Type)
  (p: t a)
  (r: range)
: SteelGhost (range `gpair` range) opened
    (vptr_range p r)
    (fun res -> vptr_range p (GPair?.fst res) `star` vptr_range p (GPair?.snd res))
    (fun _ -> True)
    (fun h res h' ->
      let GPair r1 r2 = res in
      let s = h (vptr_range p r) in
      let s1 = h' (vptr_range p (GPair?.fst res)) in
      let s2 = h' (vptr_range p (GPair?.snd res)) in
      g_is_null p == false /\
      res == g_split p r /\
      s1 == Seq.slice s 0 (r1.range_to - r1.range_from) /\
      s2 == Seq.slice s (r1.range_to - r1.range_from) (Seq.length s) /\
      s == s1 `Seq.append` s2
    )

let g_move
  (#a: Type)
  (p1 p2: t a)
  (r: range)
: Pure range
  (requires (
    g_is_null p1 == false /\
    g_is_null p2 == false /\
    base p1 == base p2 /\
    size_v (offset p1) + r.range_from <= size_v (offset p2) /\
    size_v (offset p2) <= size_v (offset p1) + r.range_to
  ))
  (ensures (fun _ -> True))
= {
  range_from = r.range_from + size_v (offset p1) - size_v (offset p2);
  range_to = r.range_to + size_v (offset p1) - size_v (offset p2);
  range_write_perm = r.range_write_perm;
  range_free_perm = r.range_free_perm;
  range_prf = ();
}

let g_move_correct
  (#a: Type)
  (p1 p2: t a)
  (r: range)
: Lemma
  (requires (
    g_is_null p1 == false /\
    g_is_null p2 == false /\
    base p1 == base p2 /\
    size_v (offset p1) + r.range_from <= size_v (offset p2) /\
    size_v (offset p2) <= size_v (offset p1) + r.range_to
  ))
  (ensures (
    g_move p2 p1 (g_move p1 p2 r) == r
  ))
= ()

val move
  (#opened: _)
  (#a: Type)
  (p1 p2: t a)
  (r: range)
: SteelGhost range opened
    (vptr_range p1 r)
    (fun res -> vptr_range p2 res)
    (fun _ ->
      (g_is_null p1 == false /\ g_is_null p2 == false) ==> (
      base p1 == base p2 /\
      size_v (offset p1) + r.range_from <= size_v (offset p2) /\
      size_v (offset p2) <= size_v (offset p1) + r.range_to
    ))
    (fun h res h' ->
      (g_is_null p1 == false /\ g_is_null p2 == false) /\
      base p1 == base p2 /\
      size_v (offset p1) + r.range_from <= size_v (offset p2) /\
      size_v (offset p2) <= size_v (offset p1) + r.range_to /\
      res == g_move p1 p2 r /\
      h' (vptr_range p2 res) == h (vptr_range p1 r)
    )
