﻿(*
   Copyright 2008-2014 Nikhil Swamy and Microsoft Research

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
#light "off"

module FStar.SMTEncoding.Solver
open FStar.Pervasives
open FStar.Compiler.Effect
open FStar.Compiler.List
open FStar
open FStar.Compiler
open FStar.SMTEncoding.Z3
open FStar.SMTEncoding.Term
open FStar.Compiler.Util
open FStar.TypeChecker
open FStar.TypeChecker.Env
open FStar.SMTEncoding
open FStar.SMTEncoding.ErrorReporting
open FStar.SMTEncoding.Util

module BU = FStar.Compiler.Util
module U = FStar.Syntax.Util
module TcUtil = FStar.TypeChecker.Util
module Print = FStar.Syntax.Print
module Env = FStar.TypeChecker.Env
module Err = FStar.Errors

(****************************************************************************)
(* Hint databases for record and replay (private)                           *)
(****************************************************************************)

// The type definition is now in [FStar.Compiler.Util], since it needs to be visible to
// both the F# and OCaml implementations.

type z3_replay_result = either<Z3.unsat_core, error_labels>
let z3_result_as_replay_result = function
    | Inl l -> Inl l
    | Inr (r, _) -> Inr r
let recorded_hints : ref<(option<hints>)> = BU.mk_ref None
let replaying_hints: ref<(option<hints>)> = BU.mk_ref None

(****************************************************************************)
(* Hint databases (public)                                                  *)
(****************************************************************************)
let initialize_hints_db src_filename format_filename : unit =
    if Options.record_hints() then recorded_hints := Some [];
    let norm_src_filename = BU.normalize_file_path src_filename in
    (*
     * Read the hints file into replaying_hints
     * But it will only be used when use_hints is on
     *)
    let val_filename = Options.hint_file_for_src norm_src_filename in
    begin match BU.read_hints val_filename with
          | HintsOK hints ->
            let expected_digest = BU.digest_of_file norm_src_filename in
            if Options.hint_info()
            then begin
                    BU.print3 "(%s) digest is %s from %s.\n" norm_src_filename
                        (if hints.module_digest = expected_digest
                         then "valid; using hints"
                         else "invalid; using potentially stale hints")
                         val_filename
                 end;
                 replaying_hints := Some hints.hints

          | MalformedJson ->
            if Options.use_hints () then
              Err.log_issue Range.dummyRange
                            (Err.Warning_CouldNotReadHints,
                             BU.format1 "Malformed JSON hints file: %s; ran without hints\n"
                                       val_filename);
            ()

          | UnableToOpen ->
            if Options.use_hints () then
              Err.log_issue Range.dummyRange
                            (Err.Warning_CouldNotReadHints,
                             BU.format1 "Unable to open hints file: %s; ran without hints\n"
                                       val_filename);
            ()
    end

let finalize_hints_db src_filename :unit =
    begin if Options.record_hints () then
          let hints = Option.get !recorded_hints in
          let hints_db = {
                module_digest = BU.digest_of_file src_filename;
                hints = hints
              }  in
          let norm_src_filename = BU.normalize_file_path src_filename in
          let val_filename = Options.hint_file_for_src norm_src_filename in
          BU.write_hints val_filename hints_db
    end;
    recorded_hints := None;
    replaying_hints := None

let with_hints_db fname f =
    initialize_hints_db fname false;
    let result = f () in
    // for the moment, there should be no need to trap exceptions to finalize the hints db
    // no cleanup needs to occur if an error occurs.
    finalize_hints_db fname;
    result

let filter_using_facts_from (e:env) (theory:list<decl>) =
    let matches_fact_ids (include_assumption_names:BU.smap<bool>) (a:Term.assumption) =
      match a.assumption_fact_ids with
      | [] -> true //retaining `a` because it is not tagged with a fact id
      | _ ->
        a.assumption_fact_ids |> BU.for_some (function | Name lid -> Env.should_enc_lid e lid | _ -> false)
        || Option.isSome (BU.smap_try_find include_assumption_names a.assumption_name)
    in
    //theory can have ~10k elements; fold_right on it is dangerous, since it's not tail recursive
    //AR: reversing the list is also crucial for correctness because of RetainAssumption
    //    specifically (RetainAssumption a) comes after (a) in the theory list
    //    as a result, it is crucial that we consider the (RetainAssumption a) before we encounter (a)
    let theory_rev = List.rev theory in  //List.rev is already the tail recursive version of rev
    let pruned_theory =
        let include_assumption_names =
            //this map typically grows to 10k+ elements
            //using a map for it is important, otherwise the list scanning
            //becomes near quadratic in the # of facts
            BU.smap_create 10000
        in
        let keep_decl :decl -> bool = function  //effectful function, adds decls to the include_assumption_names map
          | Assume a -> matches_fact_ids include_assumption_names a
          | RetainAssumptions names ->
            List.iter (fun x -> BU.smap_add include_assumption_names x true) names;
            true
          | Module _ -> failwith "Solver.fs::keep_decl should never have been called with a Module decl"
          | _ -> true
        in
        List.fold_left (fun out d ->
          match d with
          | Module (name, decls) -> decls |> List.filter keep_decl |> (fun decls -> Module (name, decls)::out)
          | _ -> if keep_decl d then d::out else out) [] theory_rev
    in
    pruned_theory

let rec filter_assertions_with_stats (e:env) (core:Z3.unsat_core) (theory:list<decl>)
  :(list<decl> * bool * int * int) =  //(filtered theory, if core used, retained, pruned)
    match core with
    | None ->
      filter_using_facts_from e theory, false, 0, 0  //no stats if no core
    | Some core ->
        //so that we can use the tail-recursive fold_left
        let theory_rev = List.rev theory in
        let theory', n_retained, n_pruned =
            List.fold_left (fun (theory, n_retained, n_pruned) d -> match d with
            | Assume a ->
                if List.contains a.assumption_name core
                then d::theory, n_retained+1, n_pruned
                else if BU.starts_with a.assumption_name "@"
                then d::theory, n_retained, n_pruned
                else theory, n_retained, n_pruned+1
            | Module (name, decls) ->
              decls |> filter_assertions_with_stats e (Some core)
                    |> (fun (decls, _, r, p) -> Module (name, decls)::theory, n_retained + r, n_pruned + p)
            | _ -> d::theory, n_retained, n_pruned)
            ([Caption ("UNSAT CORE: " ^ (core |> String.concat ", "))], 0, 0) theory_rev in  //start with the unsat core caption at the end
        theory', true, n_retained, n_pruned

let filter_assertions (e:env) (core:Z3.unsat_core) (theory:list<decl>) =
  let (theory, b, _, _) = filter_assertions_with_stats e core theory in theory, b

let filter_facts_without_core (e:env) x = filter_using_facts_from e x, false

(***********************************************************************************)
(* Invoking the SMT solver and extracting an error report from the model, if any   *)
(***********************************************************************************)
type errors = {
    error_reason:string;
    error_fuel: int;
    error_ifuel: int;
    error_hint: option<(list<string>)>;
    error_messages: list<Errors.error>;
}

let error_to_short_string err =
    BU.format4 "%s (fuel=%s; ifuel=%s%s)"
            err.error_reason
            (string_of_int err.error_fuel)
            (string_of_int err.error_ifuel)
            (if Option.isSome err.error_hint then "; with hint" else "")

let error_to_is_timeout err =
    if BU.ends_with err.error_reason "canceled"
    then [BU.format4 "timeout (fuel=%s; ifuel=%s; %s)"
            err.error_reason
            (string_of_int err.error_fuel)
            (string_of_int err.error_ifuel)
            (if Option.isSome err.error_hint then "with hint" else "")]
    else []

type query_settings = {
    query_env:env;
    query_decl:decl;
    query_name:string;
    query_index:int;
    query_range:Range.range;
    query_fuel:int;
    query_ifuel:int;
    query_rlimit:int;
    query_hint:Z3.unsat_core;
    query_errors:list<errors>;
    query_all_labels:error_labels;
    query_suffix:list<decl>;
    query_hash:option<string>
}


//surround the query with fuel options and various diagnostics
let with_fuel_and_diagnostics settings label_assumptions =
    let n = settings.query_fuel in
    let i = settings.query_ifuel in
    let rlimit = settings.query_rlimit in
    [  //fuel and ifuel settings
        Term.Caption (BU.format2 "<fuel='%s' ifuel='%s'>"
                        (string_of_int n)
                        (string_of_int i));
        Util.mkAssume(mkEq(mkApp("MaxFuel", []), n_fuel n), None, "@MaxFuel_assumption");
        Util.mkAssume(mkEq(mkApp("MaxIFuel", []), n_fuel i), None, "@MaxIFuel_assumption");
        settings.query_decl        //the query itself
    ]
    @label_assumptions         //the sub-goals that are currently disabled
    @[  Term.SetOption ("rlimit", string_of_int rlimit); //the rlimit setting for the check-sat
        Term.CheckSat; //go Z3!
        Term.SetOption ("rlimit", "0"); //back to using infinite rlimit
        Term.GetReasonUnknown; //explain why it failed
        Term.GetUnsatCore; //for proof profiling, recording hints etc
    ]
    @(if (Options.print_z3_statistics() ||
          Options.query_stats ()) then [Term.GetStatistics] else []) //stats
    @settings.query_suffix //recover error labels and a final "Done!" message


let used_hint s = Option.isSome s.query_hint

let get_hint_for qname qindex =
    match !replaying_hints with
    | Some hints ->
      BU.find_map hints (function
        | Some hint when hint.hint_name=qname && hint.hint_index=qindex -> Some hint
        | _ -> None)
    | _ -> None

let query_errors settings z3result =
    match z3result.z3result_status with
    | UNSAT _ -> None
    | _ ->
     let msg, error_labels = Z3.status_string_and_errors z3result.z3result_status in
     let err =  {
            error_reason = msg;
            error_fuel = settings.query_fuel;
            error_ifuel = settings.query_ifuel;
            error_hint = settings.query_hint;
            error_messages = List.map (fun (_, x, y) -> Errors.Error_Z3SolverError,
                                                        x,
                                                        y,
                                                        Errors.get_ctx ()) // FIXME: leaking abstraction
                                      error_labels
        }
     in
     Some err

let detail_hint_replay settings z3result =
    if used_hint settings
    && Options.detail_hint_replay ()
    then match z3result.z3result_status with
         | UNSAT _ -> ()
         | _failed ->
           let ask_z3 label_assumptions =
               Z3.ask settings.query_range
                      (filter_assertions settings.query_env settings.query_hint)
                      settings.query_hash
                      settings.query_all_labels
                      (with_fuel_and_diagnostics settings label_assumptions)
                      None
                      false
           in
           detail_errors true settings.query_env settings.query_all_labels ask_z3

let find_localized_errors (errs : list<errors>) : option<errors> =
    errs |> List.tryFind (fun err -> match err.error_messages with [] -> false | _ -> true)

let errors_to_report (settings : query_settings) : list<Errors.error> =
    let format_smt_error msg =
      BU.format1 "SMT solver says:\n\t%s;\n\t\
                  Note: 'canceled' or 'resource limits reached' means the SMT query timed out, so you might want to increase the rlimit;\n\t\
                  'incomplete quantifiers' means Z3 could not prove the query, so try to spell your proof out in greater detail, increase fuel or ifuel\n\t\
                  'unknown' means Z3 provided no further reason for the proof failing"
        msg
    in
    let basic_errors =
        (*
         * AR: smt_error is either an Inr of a multi-line detailed message OR an Inl of a single line short message
         *     depending on whether Options.query_stats is on or off
         *)
        let smt_error =
          if Options.query_stats () then
            settings.query_errors
            |> List.map error_to_short_string
            |> String.concat ";\n\t"
            |> format_smt_error |> Inr
          else
            (*
             * AR: --query_stats is not set, we want to give a succint but helpful diagnosis
             *
             *     settings.query_errors is a list of errors, whose field error_reason contains the strings:
             *       unknown because (incomplete ...) or unknown because (resource ...) or unknown because canceled etc.
             *     it's a list as it contains one element per config (e.g. fuel options)
             *
             *     in the following code we go through the error reasons in all the configs,
             *       and if all the error reasons are the same, we provide a hint for that reason
             *     otherwise we just ask the user to run with --query_stats
             *
             *     as per the smt-lib standard, the possible values of reason-unknown are s-expressions,
             *       that are either non-space strings, or strings with spaces enclosed in parenthesis
             *       (I think), so incomplete or resource messages are in parenthesis, whereas
             *       canceled, timeout, etc. are without
             *)
            let incomplete_count, canceled_count, unknown_count =
              List.fold_left (fun (ic, cc, uc) err ->
                let err = BU.substring_from err.error_reason (String.length "unknown because ") in
                //err is (incomplete quantifiers), (resource ...), canceled, or unknown etc.
                if BU.starts_with err "canceled"  ||
                   BU.starts_with err "(resource" ||
                   BU.starts_with err "timeout"
                then (ic, cc + 1, uc)
                else if BU.starts_with err "(incomplete" then (ic + 1, cc, uc)
                else (ic, cc, uc + 1)  //note this covers unknowns, overflows, etc.
              ) (0, 0, 0) settings.query_errors
            in
            (match incomplete_count, canceled_count, unknown_count with
             | _, 0, 0 when incomplete_count > 0 -> "The SMT solver could not prove the query, try to spell your proof in more detail or increase fuel/ifuel"
             | 0, _, 0 when canceled_count > 0   -> "The SMT query timed out, you might want to increase the rlimit"
             | _, _, _                           -> "Try with --query_stats to get more details") |> Inl
        in
        match find_localized_errors settings.query_errors with
        | Some err ->
          // FStar.Errors.log_issue settings.query_range (FStar.Errors.Warning_SMTErrorReason, smt_error);
          FStar.TypeChecker.Err.errors_smt_detail settings.query_env err.error_messages smt_error
        | None ->
          FStar.TypeChecker.Err.errors_smt_detail
                   settings.query_env
                   [(Errors.Error_UnknownFatal_AssertionFailure,
                     "Unknown assertion failed",
                     settings.query_range,
                     Errors.get_ctx ())]
                   smt_error
    in
    let detailed_errors : unit =
      if Options.detail_errors()
      then let initial_fuel = {
                  settings with query_fuel=Options.initial_fuel();
                                query_ifuel=Options.initial_ifuel();
                                query_hint=None
              }
           in
           let ask_z3 label_assumptions =
              Z3.ask  settings.query_range
                      (filter_facts_without_core settings.query_env)
                      settings.query_hash
                      settings.query_all_labels
                      (with_fuel_and_diagnostics initial_fuel label_assumptions)
                      None
                      false
              in
           (* GM: This is a bit of hack, we don't return these detailed errors
            * (it implies rewriting detail_errors heavily). Returning them
            * is only relevant for summarizing errors on --quake, where I don't
            * think we care about these. *)
           detail_errors false settings.query_env settings.query_all_labels ask_z3
    in
    basic_errors

let report_errors qry_settings =
    FStar.Errors.add_errors (errors_to_report qry_settings)

let query_info settings z3result =
    let process_unsat_core (core:unsat_core) =
        (* A generic accumulator of unique strings,
           extracted in sorted order *)
        let accumulator () =
            let r : ref<list<string>> = BU.mk_ref [] in
            let add, get =
                let module_names = BU.mk_ref [] in
                (fun m ->
                    let ms = !module_names in
                    if List.contains m ms then ()
                    else module_names := m :: ms),
                (fun () ->
                    !module_names |> BU.sort_with String.compare)
            in
            add, get
       in
       (* Accumulator for module names *)
       let add_module_name, get_module_names =
           accumulator()
       in
       (* Accumulator for discarded names *)
       let add_discarded_name, get_discarded_names =
           accumulator()
       in
       (* SMT Axioms are named using an ad hoc naming convention
          that includes the F* source name within it.

          This function reversed the naming convention to extract
          the source name of the F* entity from `s`, an axiom name
          mentioned in an unsat core (but also in smt.qi.profile, etc.)

          The basic structure of the name is

            <lowercase_prefix><An F* lid, i.e., a dot-separated name beginning with upper case letter><some reserved suffix>

          So, the code below strips off the <lowercase_prefix>
          and any of the reserved suffixes.

          What's left is an F* name, which can be decomposed as usual
          into a module name + a top-level identifier
       *)
       let parse_axiom_name (s:string) =
            let chars = String.list_of_string s in
            let first_upper_index =
                BU.try_find_index BU.is_upper chars
            in
            match first_upper_index with
            | None ->
              //Has no embedded F* name (discard it, and record it in the discarded set)
              add_discarded_name s;
              []
            | Some first_upper_index ->
                let name_and_suffix = BU.substring_from s first_upper_index in
                let components = String.split ['.'] name_and_suffix in
                let excluded_suffixes =
                    [ "fuel_instrumented";
                      "_pretyping";
                      "_Tm_refine";
                      "_Tm_abs";
                      "@";
                      "_interpretation_Tm_arrow";
                      "MaxFuel_assumption";
                      "MaxIFuel_assumption";
                    ]
                in
                let exclude_suffix s =
                    let s = BU.trim_string s in
                    let sopt =
                        BU.find_map
                            excluded_suffixes
                            (fun sfx ->
                                if BU.contains s sfx
                                then Some (List.hd (BU.split s sfx))
                                else None)
                    in
                    match sopt with
                    | None -> if s = "" then [] else [s]
                    | Some s -> if s = "" then [] else [s]
                in
                let components =
                    match components with
                    | [] -> []
                    | _ ->
                      let module_name, last = BU.prefix components in
                      let components = module_name @ exclude_suffix last in
                      let _ =
                          match components with
                          | []
                          | [_] -> () //no module name
                          | _ ->
                            add_module_name (String.concat "." module_name)
                      in
                      components
                in
                if components = []
                then (add_discarded_name s; [])
                else [ components |> String.concat "."]
        in
        match core with
        | None ->
           BU.print_string "no unsat core\n"
        | Some core ->
           let core = List.collect parse_axiom_name core in
           BU.print1 "Z3 Proof Stats: Modules relevant to this proof:\nZ3 Proof Stats:\t%s\n"
                     (get_module_names() |> String.concat "\nZ3 Proof Stats:\t");
           BU.print1 "Z3 Proof Stats (Detail 1): Specifically:\nZ3 Proof Stats (Detail 1):\t%s\n"
                     (String.concat "\nZ3 Proof Stats (Detail 1):\t" core);
           BU.print1 "Z3 Proof Stats (Detail 2): Note, this report ignored the following names in the context: %s\n"
                     (get_discarded_names() |> String.concat ", ")
    in
    if Options.hint_info()
    || Options.query_stats()
    then begin
        let status_string, errs = Z3.status_string_and_errors z3result.z3result_status in
        let at_log_file =
            match z3result.z3result_log_file with
            | None -> ""
            | Some s -> "@"^s
        in
        let tag, core = match z3result.z3result_status with
         | UNSAT core -> "succeeded", core
         | _ -> "failed {reason-unknown=" ^ status_string ^ "}", None
        in
        let range = "(" ^ (Range.string_of_range settings.query_range) ^ at_log_file ^ ")" in
        let used_hint_tag = if used_hint settings then " (with hint)" else "" in
        let stats =
            if Options.query_stats() then
                let f k v a = a ^ k ^ "=" ^ v ^ " " in
                let str = smap_fold z3result.z3result_statistics f "statistics={" in
                    (substring str 0 ((String.length str) - 1)) ^ "}"
            else "" in
        BU.print "%s\tQuery-stats (%s, %s)\t%s%s in %s milliseconds with fuel %s and ifuel %s and rlimit %s %s\n"
             [  range;
                settings.query_name;
                BU.string_of_int settings.query_index;
                tag;
                used_hint_tag;
                BU.string_of_int z3result.z3result_time;
                BU.string_of_int settings.query_fuel;
                BU.string_of_int settings.query_ifuel;
                BU.string_of_int settings.query_rlimit;
                stats
             ];
        if Options.print_z3_statistics () then process_unsat_core core;
        errs |> List.iter (fun (_, msg, range) ->
            let tag = if used_hint settings then "(Hint-replay failed): " else "" in
            FStar.Errors.log_issue range (FStar.Errors.Warning_HitReplayFailed, (tag ^ msg)))
    end

//caller must ensure that the recorded_hints is already initiailized
let store_hint hint =
  match !recorded_hints with
  | Some l -> recorded_hints := Some (l@[Some hint])
  | _ -> assert false; ()

let record_hint settings z3result =
    if not (Options.record_hints()) then () else
    begin
      let mk_hint core = {
                  hint_name=settings.query_name;
                  hint_index=settings.query_index;
                  fuel=settings.query_fuel;
                  ifuel=settings.query_ifuel;
                  unsat_core=core;
                  query_elapsed_time=0; //recording the elapsed_time prevents us from reaching a fixed point
                  hash=(match z3result.z3result_status with
                        | UNSAT core -> z3result.z3result_query_hash
                        | _ -> None)
          }
      in
      match z3result.z3result_status with
      | UNSAT None ->
        // we succeeded by just matching a query hash
        store_hint (Option.get (get_hint_for settings.query_name settings.query_index))
      | UNSAT unsat_core ->
        if used_hint settings //if we already successfully use a hint
        then //just re-use the successful hint, but record the hash of the pruned theory
             store_hint (mk_hint settings.query_hint)
        else store_hint (mk_hint unsat_core)          //else store the new unsat core
      | _ ->  () //the query failed, so nothing to do
    end

let process_result settings result : option<errors> =
    let errs = query_errors settings result in
    query_info settings result;
    record_hint settings result;
    detail_hint_replay settings result;
    errs

// Attempts to solve each query setting (in `qs`) sequentially until
// one succeeds. If one succeeds, we are done and report no errors. If
// all of them fail, we call `report` with a log of the errors so they
// can be displayed to the user.
// Returns Inr cfg if successful, with the succeeding config cfg
// and Inl errs if all options were exhausted
// without a success, where errs is the list of errors each query
// returned.
let fold_queries (qs:list<query_settings>)
                 (ask:query_settings -> z3result)
                 (f:query_settings -> z3result -> option<errors>)
                 : either<list<errors>, query_settings> =
    let rec aux (acc : list<errors>) qs : either<list<errors>, query_settings> =
        match qs with
        | [] -> Inl acc
        | q::qs ->
          let res = ask q in
          begin match f q res with
          | None -> Inr q //done
          | Some errs ->
            aux (errs::acc) qs
          end
    in
    aux [] qs

let full_query_id settings =
    "(" ^ settings.query_name ^ ", " ^ (BU.string_of_int settings.query_index) ^ ")"

let collect (l : list<'a>) : list<('a * int)> =
    let acc : list<('a * int)> = [] in
    let rec add_one acc x =
        match acc with
        | [] -> [(x, 1)]
        | (h, n)::t ->
            if h = x
            then (h, n+1)::t
            else (h, n) :: add_one t x
    in
    List.fold_left add_one acc l

let ask_and_report_errors env all_labels prefix query suffix : unit =
    Z3.giveZ3 prefix; //feed the context of the query to the solver

    let default_settings, next_hint =
        let qname, index =
            match env.qtbl_name_and_index with
            | _, None -> failwith "No query name set!"
            | _, Some (q, n) -> Ident.string_of_lid q, n
        in
        let rlimit =
            Prims.op_Multiply
                (Options.z3_rlimit_factor ())
                (Prims.op_Multiply (Options.z3_rlimit ()) 544656)
        in
        let next_hint = get_hint_for qname index in
        let default_settings = {
            query_env=env;
            query_decl=query;
            query_name=qname;
            query_index=index;
            query_range=Env.get_range env;
            query_fuel=Options.initial_fuel();
            query_ifuel=Options.initial_ifuel();
            query_rlimit=rlimit;
            query_hint=None;
            query_errors=[];
            query_all_labels=all_labels;
            query_suffix=suffix;
            query_hash=(match next_hint with
                        | None -> None
                        | Some {hash=h} -> h)
        } in
        default_settings, next_hint
    in

    let use_hints_setting =
        if Options.use_hints () && next_hint |> is_some
        then
            let ({unsat_core=Some core; fuel=i; ifuel=j; hash=h}) = next_hint |> must in
            [{default_settings with query_hint=Some core;
                                    query_fuel=i;
                                    query_ifuel=j}]
        else []
    in

    let initial_fuel_max_ifuel =
        if Options.max_ifuel() > Options.initial_ifuel()
        then [{default_settings with query_ifuel=Options.max_ifuel()}]
        else []
    in

    let half_max_fuel_max_ifuel =
        if Options.max_fuel() / 2 >  Options.initial_fuel()
        then [{default_settings with query_fuel=Options.max_fuel() / 2;
                                     query_ifuel=Options.max_ifuel()}]
        else []
    in

    let max_fuel_max_ifuel =
      if Options.max_fuel()    >  Options.initial_fuel()
      && Options.max_ifuel()   >=  Options.initial_ifuel()
      then [{default_settings with query_fuel=Options.max_fuel();
                                   query_ifuel=Options.max_ifuel()}]
      else []
    in

    let all_configs =
        use_hints_setting
        @ [default_settings]
        @ initial_fuel_max_ifuel
        @ half_max_fuel_max_ifuel
        @ max_fuel_max_ifuel
    in

    let check_one_config config : z3result =
          if Options.z3_refresh() then Z3.refresh();
          Z3.ask config.query_range
                  (filter_assertions config.query_env config.query_hint)
                  config.query_hash
                  config.query_all_labels
                  (with_fuel_and_diagnostics config [])
                  (Some (Z3.mk_fresh_scope()))
                  (used_hint config)
    in

    let check_all_configs configs : either<list<errors>, query_settings> =
        fold_queries configs check_one_config process_result
    in

    let quake_and_check_all_configs configs =
        let lo   = Options.quake_lo () in
        let hi   = Options.quake_hi () in
        let seed = Options.z3_seed () in
        let name = full_query_id default_settings in
        let quaking = hi > 1 && not (Options.retry ()) in
        let quaking_or_retrying = hi > 1 in
        let hi = if hi < 1 then 1 else hi in
        let lo =
            if lo < 1 then 1
            else if lo > hi then hi
            else lo
        in
        let run_one (seed:int) =
            (* Here's something annoying regarding --quake:
             *
             * In normal circumstances, we can just run the query again and get
             * a slightly different behaviour because of Z3 accumulating some
             * internal state that doesn't get erased on a (pop). So we simply repeat
             * the query then.
             *
             * But, if we're doing --z3refresh, we will always get the exact
             * same behaviour by doing that, so we do want to set the seed in this case.
             *
             * Why not always set it? Because it requires restarting the solver, which
             * takes a long time.
             *
             * Why not use the (set-option smt.random_seed ..) command? Because
             * it seems to have no effect just before a (check-sat), so it needs to be
             * set early, which basically implies restarting.
             *
             * So we do this horrendous thing.
             *)
            if Options.z3_refresh ()
            then Options.with_saved_options (fun () ->
                   Options.set_option "z3seed" (Options.Int seed);
                   check_all_configs configs)
            else check_all_configs configs
        in
        let rec fold_nat' (f : 'a -> int -> 'a) (acc : 'a) (lo : int) (hi : int) : 'a =
            if lo > hi
            then acc
            else fold_nat' f (f acc lo) (lo + 1) hi
        in
        let best_fuel = BU.mk_ref None in
        let best_ifuel = BU.mk_ref None in
        let maybe_improve r n =
            match !r with
            | None -> r := Some n
            | Some m -> if n < m then r := Some n
        in
        let nsuccess, nfailures, rs =
            fold_nat'
                (fun (nsucc, nfail, rs) n ->
                     if not (Options.quake_keep ())
                        && (nsucc >= lo (* already have enough successes *)
                            || nfail > hi-lo) (* already have too many failures *)
                     then (nsucc, nfail, rs)
                     else begin
                     if quaking_or_retrying
                        && (Options.interactive () || Options.debug_any ()) (* only on emacs or when debugging *)
                        && n>0 then (* no need to print last *)
                       BU.print5 "%s: so far query %s %sfailed %s (%s runs remain)\n"
                           (if quaking then "Quake" else "Retry")
                           name
                           (if quaking then BU.format1 "succeeded %s times and " (string_of_int nsucc) else "")
                           (* ^ if --retrying, it does not make sense to print successes since
                            * they must be exactly 0 *)
                           (if quaking then string_of_int nfail else string_of_int nfail ^ " times")
                           (* ^ proper grammar :-) *)
                           (string_of_int (hi-n));
                     let r = run_one (seed+n) in
                     let nsucc, nfail =
                        match r with
                        | Inr cfg ->
                            (* maybe update best fuels *)
                            maybe_improve best_fuel cfg.query_fuel;
                            maybe_improve best_ifuel cfg.query_ifuel;
                            nsucc + 1, nfail
                        | _ -> nsucc, nfail+1
                     in
                     (nsucc, nfail, r::rs)
                     end)
                (0, 0, []) 0 (hi-1)
        in
        let total_ran = nsuccess + nfailures in
        if quaking then begin
            let fuel_msg =
              match !best_fuel, !best_ifuel with
              | Some f, Some i ->
                BU.format2 " (best fuel=%s, best ifuel=%s)" (string_of_int f) (string_of_int i)
              | _, _ -> ""
            in
            BU.print5 "Quake: query %s succeeded %s/%s times%s%s\n"
                      name
                      (string_of_int nsuccess)
                      (string_of_int total_ran)
                      (if total_ran < hi then " (early finish)" else "")
                      fuel_msg
        end;
        (* If nsuccess < lo, we have a failure. We report summarized
         * information if doing --quake (and not --query_stats) *)
        if nsuccess < lo then begin
          let all_errs = List.concatMap (function | Inr _ -> []
                                                  | Inl es -> [es]) rs in
          if quaking_or_retrying && not (Options.query_stats ()) then begin
            let errors_to_report errs =
                errors_to_report ({default_settings with query_errors=errs})
            in

            (* Obtain all errors that would have been reported *)
            let errs = List.map errors_to_report all_errs in
            (* Summarize them *)
            let errs = errs |> List.flatten |> collect in
            (* Show the amount on each error *)
            let errs = errs |> List.map (fun ((e, m, r, ctx), n) ->
                if n > 1
                then (e, m ^ BU.format1 " (%s times)" (string_of_int n), r, ctx)
                else (e, m, r, ctx))
            in
            (* Now report them *)
            FStar.Errors.add_errors errs;

            (* Get the range of lid we're checking for the quake error *)
            let rng = match snd (env.qtbl_name_and_index) with
                      | Some (l, _) -> Ident.range_of_lid l
                      | _ -> Range.dummyRange
            in
            (* Adding another error for the threshold (but not for --retry) *)
            if quaking then
              FStar.TypeChecker.Err.log_issue
                env rng
                (Errors.Error_QuakeFailed,
                  BU.format6
                    "Query %s failed the quake test, %s out of %s attempts succeded, \
                     but the threshold was %s out of %s%s"
                     name
                    (string_of_int nsuccess)
                    (string_of_int total_ran)
                    (string_of_int lo)
                    (string_of_int hi)
                    (if total_ran < hi then " (early abort)" else ""))

          end
          else begin
            (* Just report them as usual *)
            let report errs = report_errors ({default_settings with query_errors=errs}) in
            List.iter report all_errs
          end
        end
    in

    let skip =
        Options.admit_smt_queries () ||
        Env.too_early_in_prims env   ||
        (match Options.admit_except () with
         | Some id ->
           if BU.starts_with id "("
           then full_query_id default_settings <> id
           else default_settings.query_name <> id
         | None -> false) in

    if skip
    then if Options.record_hints () && next_hint |> is_some
         //restore the hint as is, cf. #1651
         then next_hint |> must |> store_hint
         else ()
    else quake_and_check_all_configs all_configs

type solver_cfg = {
  seed             : int;
  cliopt           : list<string>;
  facts            : list<(list<string> * bool)>;
  valid_intro      : bool;
  valid_elim       : bool;
}

let _last_cfg : ref<option<solver_cfg>> = BU.mk_ref None

let get_cfg env : solver_cfg =
    { seed             = Options.z3_seed ()
    ; cliopt           = Options.z3_cliopt ()
    ; facts            = env.proof_ns
    ; valid_intro      = Options.smtencoding_valid_intro ()
    ; valid_elim       = Options.smtencoding_valid_elim ()
    }

let save_cfg env =
    _last_cfg := Some (get_cfg env)

let should_refresh env =
    match !_last_cfg with
    | None -> (save_cfg env; false)
    | Some cfg ->
        not (cfg = get_cfg env)

let do_solve use_env_msg tcenv q : unit =
    if should_refresh tcenv then begin
      save_cfg tcenv;
      Z3.refresh ()
    end;
    Encode.push (BU.format1 "Starting query at %s" (Range.string_of_range <| Env.get_range tcenv));
    let pop () = Encode.pop (BU.format1 "Ending query at %s" (Range.string_of_range <| Env.get_range tcenv)) in
    try
      let prefix, labels, qry, suffix = Encode.encode_query use_env_msg tcenv q in
      let tcenv = incr_query_index tcenv in
      match qry with
      | Assume({assumption_term={tm=App(FalseOp, _)}}) -> pop()
      | _ when tcenv.admit -> pop()
      | Assume _ ->
        ask_and_report_errors tcenv labels prefix qry suffix;
        pop ()

      | _ -> failwith "Impossible"
    with
      | FStar.SMTEncoding.Env.Inner_let_rec names ->  //can be raised by encode_query
        pop ();  //AR: Important, we push-ed before encode_query was called
        FStar.TypeChecker.Err.log_issue
          tcenv tcenv.range
          (Errors.Error_NonTopRecFunctionNotFullyEncoded,
           BU.format1
             "Could not encode the query since F* does not support precise smtencoding of inner let-recs yet (in this case %s)"
             (String.concat "," (List.map fst names)))

let solve use_env_msg tcenv q : unit =
    if Options.no_smt () then
        FStar.TypeChecker.Err.log_issue
          tcenv tcenv.range
            (Errors.Error_NoSMTButNeeded,
             BU.format1 "Q = %s\nA query could not be solved internally, and --no_smt was given" (Print.term_to_string q))
    else
    Profiling.profile
      (fun () -> do_solve use_env_msg tcenv q)
      (Some (Ident.string_of_lid (Env.current_module tcenv)))
      "FStar.SMTEncoding.solve_top_level"


(**********************************************************************************************)
(* Top-level interface *)
(**********************************************************************************************)
open FStar.TypeChecker.Env
let solver = {
    init=(fun e -> save_cfg e; Encode.init e);
    push=Encode.push;
    pop=Encode.pop;
    snapshot=Encode.snapshot;
    rollback=Encode.rollback;
    encode_sig=Encode.encode_sig;
    preprocess=(fun e g -> [e,g, FStar.Options.peek ()]);
    solve=solve;
    finish=Z3.finish;
    refresh=Z3.refresh;
}
let dummy = {
    init=(fun _ -> ());
    push=(fun _ -> ());
    pop=(fun _ -> ());
    snapshot=(fun _ -> (0, 0, 0), ());
    rollback=(fun _ _ -> ());
    encode_sig=(fun _ _ -> ());
    preprocess=(fun e g -> [e,g, FStar.Options.peek ()]);
    solve=(fun _ _ _ -> ());
    finish=(fun () -> ());
    refresh=(fun () -> ());
}
