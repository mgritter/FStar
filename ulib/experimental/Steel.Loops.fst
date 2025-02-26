(*
   Copyright 2021 Microsoft Research

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
module Steel.Loops
open Steel.Memory
open Steel.Effect.Common
open Steel.Effect
open Steel.Reference
module AT = Steel.Effect.Atomic
module U32 = FStar.UInt32

val for_loop' (start:U32.t)
              (finish:U32.t { U32.v start <= U32.v finish })
              (current:U32.t { U32.v start <= U32.v current /\
                               U32.v current <= U32.v finish })
              (inv: nat_at_most finish -> vprop)
              (body:
                    (i:u32_between start finish ->
                          SteelT unit
                          (inv (U32.v i))
                          (fun _ -> inv (U32.v i + 1))))
  : SteelT unit
      (inv (U32.v current))
      (fun _ -> inv (U32.v finish))

#push-options "--fuel 0 --ifuel 0"
let rec for_loop' start finish current inv body
  = if current = finish then (
       AT.change_equal_slprop (inv _) (inv _);
       AT.return ()
    )
    else (
      let _: squash (U32.v current < U32.v finish) = () in //fails without this
      body current;
      let current' = U32.(current +^ 1ul) in
      AT.change_equal_slprop (inv (U32.v current + 1))
                             (inv (U32.v current'));
      for_loop' start finish current' inv body
    )


(* produces 11 queries *)
let for_loop start finish inv body = for_loop' start finish start inv body


let rec while_loop inv cond body =
  let b = cond () in
  if b
  then (
     AT.change_equal_slprop (inv b) (inv true);
     body();
     while_loop inv cond body
  )
  else (
     AT.change_equal_slprop (inv b) (inv false);
     AT.return ()
  )
