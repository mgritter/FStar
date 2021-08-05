module PointStruct

open Steel.C.PCM
open Steel.C.Opt
open Steel.C.Connection
open Steel.C.Struct
open Steel.C.StructLiteral
open Steel.C.Typedef
open FStar.FunctionalExtensionality
open Steel.Effect
module A = Steel.Effect.Atomic

irreducible let c_typedef = 0

[@@c_typedef]
let c_int: typedef = {
  carrier = option int;
  pcm = opt_pcm #int;
  view_type = int;
  view = opt_view int;
}

let mk_struct_typedef a b = b

[@@c_typedef]
let point_fields: struct_fields = 
  mk_struct_typedef "point" (
  fields_cons "x" c_int (
  fields_cons "y" c_int (
  fields_nil)))

let point_view_t = struct "point" point_fields

let point_view = struct_view "point" point_fields

let point = struct_pcm_carrier "point" point_fields

let point_pcm = struct_pcm "point" point_fields

#push-options "--fuel 0"

let x_conn
: connection point_pcm (opt_pcm #int)
= struct_field "point" point_fields "x"

#push-options "--print_universes --print_implicits"
// --z3rlimit 30"

unfold let norm_list =
  [delta_attr [`%c_typedef];
   delta_only
    [`%mk_struct_typedef;
     `%fields_cons;
     `%fields_nil;
     `%Mkstruct_fields?.get_field;
     `%Mktypedef?.carrier;
     `%Mktypedef?.pcm;
     `%Mktypedef?.view_type;
     `%Mktypedef?.view];
   iota; zeta; primops]

assume val addr_of_struct_field'
  (#tag: string) (#fields: struct_fields) (#excluded: set string)
  (field: field_of fields)
  (p: ref 'a (struct_pcm tag fields))
: Steel (ref 'a (fields.get_field field).pcm)
    (p `pts_to_view` struct_view tag fields excluded)
    (fun q ->
      (p `pts_to_view` struct_view tag fields (insert field excluded)) `star`
      (pts_to_view u#0
                  #'a
                  #(norm norm_list (Mktypedef?.carrier (Mkstruct_fields?.get_field fields field)))
                  #(norm norm_list (Mktypedef?.pcm (Mkstruct_fields?.get_field fields field)))
                  q
                  #(norm norm_list (Mktypedef?.view_type (Mkstruct_fields?.get_field fields field)))
                  #false
                  (norm norm_list (Mktypedef?.view (Mkstruct_fields?.get_field fields field)))))
    (requires fun _ -> not (excluded field))
    (ensures fun h q h' -> 
      not (excluded field) /\
      q == ref_focus p (struct_field tag fields field) /\
      extract_field tag fields excluded field
        (h (p `pts_to_view` struct_view tag fields excluded))
       ==
        (h' (p `pts_to_view` struct_view tag fields (insert field excluded)),
         h' (q `pts_to_view` (fields.get_field field).view)))

assume val unaddr_of_struct_field'
  (#tag: string) (#fields: struct_fields) (#excluded: set string)
  (field: field_of fields)
  (p: ref 'a (struct_pcm tag fields))
  (q: ref 'a (fields.get_field field).pcm)
: Steel unit
    ((p `pts_to_view` struct_view tag fields excluded) `star`
     (pts_to_view u#0
                  #'a
                  #(norm norm_list (Mktypedef?.carrier (Mkstruct_fields?.get_field fields field)))
                  #(norm norm_list (Mktypedef?.pcm (Mkstruct_fields?.get_field fields field)))
                  q
                  #(norm norm_list (Mktypedef?.view_type (Mkstruct_fields?.get_field fields field)))
                  #false
                  (norm norm_list (Mktypedef?.view (Mkstruct_fields?.get_field fields field)))))
    (fun _ -> p `pts_to_view` struct_view tag fields (remove field excluded))
    (requires fun _ ->
      excluded field == true /\
      q == ref_focus p (struct_field tag fields field))
    (ensures fun h _ h' -> 
      excluded field == true /\
      extract_field tag fields (remove field excluded) field
        (h' (p `pts_to_view` struct_view tag fields (remove field excluded)))
       ==
        (h (p `pts_to_view` struct_view tag fields excluded),
         h (q `pts_to_view` (fields.get_field field).view)))

val swap (p: ref 'a point_pcm)
: Steel unit
    (p `pts_to_view` point_view emptyset)
    (fun _ -> (p `pts_to_view` point_view emptyset))
    (requires fun _ -> True)
    (ensures fun h q h' -> True)
      // h' (p `pts_to_view` point_view emptyset) `struct_get` "x"
      // == h (p `pts_to_view` point_view emptyset) `struct_get` "y" /\
      // h' (p `pts_to_view` point_view emptyset) `struct_get` "y"
      // == h (p `pts_to_view` point_view emptyset) `struct_get` "x")
      
let swap #a p =
  let q = addr_of_struct_field' "x" p in
  //A.slassert(q `pts_to_view` opt_view int);
  //A.change_equal_slprop (q `pts_to_view` _) (q `pts_to_view` opt_view int);
  let r = addr_of_struct_field' "y" p in
  let x = opt_read_sel q in
  let y = opt_read_sel r in
  q `opt_write_sel` y;
  r `opt_write_sel` x;
  unaddr_of_struct_field' "y" p r;
  unaddr_of_struct_field' "x" p q;
  A.sladmit();
  A.return ()

(*
TO PROVE:
extract_field v field = (w, x) 
get v field = x
get v field' = get w field' for all field' =!= field
*)

(* struct tag { point_fields ... } *)

(*

struct tag *p ;

int *q = &p->x;

q: ref (struct tag) #int (int_pcm)

EAddrOf (
  EField (
    TQualified "Example.t",
    (EBufRead (<<p>>, 0)),
    "x"))


Read:
    EBufRead (<<p>>, 0)

Write:
    EBufWrite (<<e>>, 0, <<e'>>)
or
    EAssign (EBufRead (<<e>>, 0), <<e'>>)

addr_of_struct_field "x" (p: ref 'a #(struct_pcm_carrier tag point_fields) (struct_pcm tag point_fields))
(* &(((struct tag)(*p)).x)

*)




*)

/// make pts_to_view stuff smt_fallback?
let addr_of_x' #a p excluded =
  let q = addr_of_struct_field #_ #"point" #point_fields #excluded "x" p in
  //A.change_equal_slprop (q `pts_to_view` _) (q `pts_to_view` opt_view int);
  //A.change_equal_slprop (p `pts_to_view` _) (p `pts_to_view` point_view (insert "x" excluded));
  //A.slassert ((p `pts_to_view` point_view (insert "x" excluded)) `star`
  //     (q `pts_to_view` opt_view int));
  A.change_equal_slprop (q `pts_to_view` _)
    (pts_to_view #a #(option int) #(opt_pcm #int) q #int #false (opt_view int));
  A.change_equal_slprop (p `pts_to_view` _)
    (pts_to_view #a #point #point_pcm p
          #(struct' "point" point_fields (insert #string "x" excluded)) #false 
         (point_view (insert "x" excluded)));
  //A.slassert ((pts_to_view #a #point #point_pcm p
  //        #(struct' "point" point_fields (insert #string "x" excluded)) #false 
  //       (point_view (insert "x" excluded))) `star`
  //     (pts_to_view #a #(option int) #(opt_pcm #int) q #int #false (opt_view int)));
  //A.sladmit();
  A.return q

let point_fields k = match k with
  | X -> option int
  | Y -> option int
let point = restricted_t point_field point_fields

let point_fields_pcm k : pcm (point_fields k) = match k with
  | X -> opt_pcm #int
  | Y -> opt_pcm #int
let point_pcm = prod_pcm point_fields_pcm

let mk_point_f (x y: option int) (k: point_field): point_fields k = match k with
  | X -> x
  | Y -> y
  
let mk_point (x y: option int): point =
  on_domain point_field (mk_point_f x y)

let _x = struct_field point_fields_pcm X
let _y = struct_field point_fields_pcm Y

/// Taking pointers to the x and y fields of a point

let point_without_x x y
: Lemma (struct_without_field point_fields_pcm X (mk_point x y) `feq` Ghost.reveal (mk_point none y))
  [SMTPat (mk_point x y)]
= ()

let point_with_x x y
: Lemma (struct_with_field point_fields_pcm X x (mk_point None y) `feq`
         mk_point x y)
  [SMTPat (mk_point x y)]
= ()

let point_without_y x y
: Lemma (struct_without_field point_fields_pcm Y (mk_point x y) `feq` mk_point x None)
  [SMTPat (mk_point x y)]
= ()

let point_with_y x y
: Lemma (struct_with_field point_fields_pcm Y y (mk_point x None) `feq`
         mk_point x y)
  [SMTPat (mk_point x y)]
= ()

let addr_of_x #a #x #y p =
  let q = addr_of_struct_field p X (mk_point x y) in
  A.change_equal_slprop (p `pts_to` _) (p `pts_to` mk_point None y);
  A.change_equal_slprop (q `pts_to` _) (q `pts_to` x);
  A.return q
  
let unaddr_of_x #a #x #y p q =
  unaddr_of_struct_field #_ #_ #_ #point_fields_pcm X q p (mk_point None y) x; // FIXME: WHY WHY WHY does F* infer the constant function (due to the type of q) instead?
  A.change_equal_slprop (p `pts_to` _) (p `pts_to` _)

let addr_of_y #a #x #y p =
  let q = addr_of_struct_field p Y (mk_point x y) in
  A.change_equal_slprop (p `pts_to` _) (p `pts_to` mk_point x None);
  A.change_equal_slprop (q `pts_to` _) (q `pts_to` y);
  A.return q

let unaddr_of_y #a #x #y p q =
  unaddr_of_struct_field #_ #_ #_ #point_fields_pcm Y q p (mk_point x None) y; // same here
  A.change_equal_slprop (p `pts_to` _) (p `pts_to` _)
