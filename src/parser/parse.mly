%{
(*
 We are expected to have only 6 shift-reduce conflicts in ML and 8 in F#.
 A lot (176) of end-of-stream conflicts are also reported and
 should be investigated...
*)
(* (c) Microsoft Corporation. All rights reserved *)
open Prims
open FStar_Pervasives
open FStar_Errors
open FStar_Compiler_List
open FStar_Compiler_Util
open FStar_Compiler_Range
open FStar_Options
(* TODO : these files should be deprecated and removed *)
open FStar_Syntax_Syntax
open FStar_Parser_Const
open FStar_Syntax_Util
open FStar_Parser_AST
open FStar_Parser_Util
open FStar_Const
open FStar_Ident
open FStar_String

let logic_qualifier_deprecation_warning =
  "logic qualifier is deprecated, please remove it from the source program. In case your program verifies with the qualifier annotated but not without it, please try to minimize the example and file a github issue"

let mk_meta_tac m = Meta m

let old_attribute_syntax_warning =
  "The `[@ ...]` syntax of attributes is deprecated. \
   Use `[@@ a1; a2; ...; an]`, a semi-colon separated list of attributes, instead"

let none_to_empty_list x = 
  match x with
  | None -> []
  | Some l -> l

%}

%token <bytes> BYTEARRAY
%token <string> STRING
%token <string> IDENT
%token <string> NAME
%token <string> TVAR
%token <string> TILDE

/* bool indicates if INT8 was 'bad' max_int+1, e.g. '128'  */
%token <string * bool> INT8
%token <string * bool> INT16
%token <string * bool> INT32
%token <string * bool> INT64
%token <string * bool> INT
%token <string> RANGE

%token <string> UINT8
%token <string> UINT16
%token <string> UINT32
%token <string> UINT64
%token <float> IEEE64
%token <string> REAL
%token <char> CHAR
%token <bool> LET

%token FORALL EXISTS ASSUME NEW LOGIC ATTRIBUTES
%token IRREDUCIBLE UNFOLDABLE INLINE OPAQUE UNFOLD INLINE_FOR_EXTRACTION
%token NOEXTRACT
%token NOEQUALITY UNOPTEQUALITY PRAGMALIGHT PRAGMA_SET_OPTIONS PRAGMA_RESET_OPTIONS PRAGMA_PUSH_OPTIONS PRAGMA_POP_OPTIONS PRAGMA_RESTART_SOLVER PRAGMA_PRINT_EFFECTS_GRAPH
%token TYP_APP_LESS TYP_APP_GREATER SUBTYPE SUBKIND BY
%token AND ASSERT SYNTH BEGIN ELSE END
%token EXCEPTION FALSE FUN FUNCTION IF IN MODULE DEFAULT
%token MATCH OF
%token FRIEND OPEN REC THEN TRUE TRY TYPE CALC CLASS INSTANCE EFFECT VAL
%token INTRO ELIM
%token INCLUDE
%token WHEN RETURNS WITH HASH AMP LPAREN RPAREN LPAREN_RPAREN COMMA LONG_LEFT_ARROW LARROW RARROW
%token IFF IMPLIES CONJUNCTION DISJUNCTION
%token DOT COLON COLON_COLON SEMICOLON
%token QMARK_DOT
%token QMARK
%token SEMICOLON_SEMICOLON EQUALS PERCENT_LBRACK LBRACK_AT LBRACK_AT_AT LBRACK_AT_AT_AT DOT_LBRACK
%token DOT_LENS_PAREN_LEFT DOT_LPAREN DOT_LBRACK_BAR LBRACK LBRACK_BAR LBRACE_BAR LBRACE BANG_LBRACE
%token BAR_RBRACK BAR_RBRACE UNDERSCORE LENS_PAREN_LEFT LENS_PAREN_RIGHT
%token BAR RBRACK RBRACE DOLLAR
%token PRIVATE REIFIABLE REFLECTABLE REIFY RANGE_OF SET_RANGE_OF LBRACE_COLON_PATTERN PIPE_RIGHT
%token NEW_EFFECT SUB_EFFECT LAYERED_EFFECT POLYMONADIC_BIND POLYMONADIC_SUBCOMP SPLICE SQUIGGLY_RARROW TOTAL
%token REQUIRES ENSURES DECREASES LBRACE_COLON_WELL_FOUNDED
%token MINUS COLON_EQUALS QUOTE BACKTICK_AT BACKTICK_HASH
%token BACKTICK UNIV_HASH
%token BACKTICK_PERC

%token<string>  OPPREFIX OPINFIX0a OPINFIX0b OPINFIX0c OPINFIX0d OPINFIX1 OPINFIX2 OPINFIX3 OPINFIX4
%token<string>  OP_MIXFIX_ASSIGNMENT OP_MIXFIX_ACCESS

/* These are artificial */
%token EOF

%nonassoc THEN
%nonassoc ELSE


%right COLON_COLON
%right AMP

%nonassoc COLON_EQUALS
%left     OPINFIX0a
%left     OPINFIX0b
%left     OPINFIX0c EQUALS
%left     OPINFIX0d
%left     PIPE_RIGHT
%right    OPINFIX1
%left     OPINFIX2 MINUS QUOTE
%left     OPINFIX3
%left     BACKTICK
%right    OPINFIX4

%start inputFragment
%start term
%start warn_error_list
%type <FStar_Parser_AST.inputFragment> inputFragment
%type <FStar_Parser_AST.term> term
%type <FStar_Ident.ident> lident
%type <(FStar_Errors.flag * string) list> warn_error_list
%%

(* inputFragment is used at the same time for whole files and fragment of codes (for interactive mode) *)
inputFragment:
  | is_light=boption(PRAGMALIGHT STRING { }) decls=list(decl) EOF
      {
        as_frag is_light (rhs parseState 1) decls
      }


/******************************************************************************/
/*                      Top level declarations                                */
/******************************************************************************/

pragma:
  | PRAGMA_SET_OPTIONS s=string
      { SetOptions s }
  | PRAGMA_RESET_OPTIONS s_opt=string?
      { ResetOptions s_opt }
  | PRAGMA_PUSH_OPTIONS s_opt=string?
      { PushOptions s_opt }
  | PRAGMA_POP_OPTIONS
      { PopOptions }
  | PRAGMA_RESTART_SOLVER
      { RestartSolver }
  | PRAGMA_PRINT_EFFECTS_GRAPH
      { PrintEffectsGraph }

attribute:
  | LBRACK_AT x = list(atomicTerm) RBRACK
      {
        let _ =
            match x with
            | _::_::_ ->
                  log_issue (lhs parseState) (Warning_DeprecatedAttributeSyntax,
                                              old_attribute_syntax_warning)
            | _ -> () in
         x
      }
  | LBRACK_AT_AT x = semiColonTermList RBRACK
      { x }


decoration:
  | x=attribute
      { DeclAttributes x }
  | x=qualifier
      { Qualifier x }

decl:
  | ASSUME lid=uident COLON phi=formula
      { mk_decl (Assume(lid, phi)) (rhs2 parseState 1 4) [ Qualifier Assumption ] }

  | ds=list(decoration) decl=rawDecl
      { mk_decl decl (rhs parseState 2) ds }

  | ds=list(decoration) decl=typeclassDecl
      { let (decl, extra_attrs) = decl in
        let d = mk_decl decl (rhs parseState 2) ds in
        { d with attrs = extra_attrs @ d.attrs }
      }

typeclassDecl:
  | CLASS tcdef=typeDecl
      {
        (* Only a single type decl allowed, but construct it the same as for multiple ones.
         * Only difference is the `true` below marking that this a class so desugaring
         * adds the needed %splice. *)
        let d = Tycon (false, true, [tcdef]) in

        (* No attrs yet, but perhaps we want a `class` attribute *)
        (d, [])
      }

  | INSTANCE q=letqualifier lb=letbinding
      {
        (* Making a single letbinding *)
        let r = rhs2 parseState 1 3 in
        let lbs = focusLetBindings [lb] r in (* lbs is a singleton really *)
        let d = TopLevelLet(q, lbs) in

        (* Slapping a `tcinstance` attribute to it *)
        let at = mk_term (Var tcinstance_lid) r Type_level in

        (d, [at])
      }

rawDecl:
  | p=pragma
      { Pragma p }
  | OPEN uid=quident
      { Open uid }
  | FRIEND uid=quident
      { Friend uid }
  | INCLUDE uid=quident
      { Include uid }
  | MODULE uid1=uident EQUALS uid2=quident
      { ModuleAbbrev(uid1, uid2) }
  | MODULE qlident
      { raise_error (Fatal_SyntaxError, "Syntax error: expected a module name") (rhs parseState 2) }
  | MODULE uid=quident
      {  TopLevelModule uid }
  | TYPE tcdefs=separated_nonempty_list(AND,typeDecl)
      { Tycon (false, false, tcdefs) }
  | EFFECT uid=uident tparams=typars EQUALS t=typ
      { Tycon(true, false, [(TyconAbbrev(uid, tparams, None, t))]) }
  | LET q=letqualifier lbs=separated_nonempty_list(AND, letbinding)
      {
        let r = rhs2 parseState 1 3 in
        let lbs = focusLetBindings lbs r in
        if q <> Rec && List.length lbs <> 1
        then raise_error (Fatal_MultipleLetBinding, "Unexpected multiple let-binding (Did you forget some rec qualifier ?)") r;
        TopLevelLet(q, lbs)
      }
  | VAL c=constant
      {
        (* This is just to provide a better error than "syntax error" *)
        raise_error (Fatal_SyntaxError, "Syntax error: constants are not allowed in val declarations") (rhs2 parseState 1 2)
      }
  | VAL lid=lidentOrOperator bss=list(multiBinder) COLON t=typ
      {
        let t = match flatten bss with
          | [] -> t
          | bs -> mk_term (Product(bs, t)) (rhs2 parseState 3 5) Type_level
        in Val(lid, t)
      }
  | SPLICE LBRACK ids=separated_list(SEMICOLON, ident) RBRACK t=thunk(atomicTerm)
      { Splice (ids, t) }
  | EXCEPTION lid=uident t_opt=option(OF t=typ {t})
      { Exception(lid, t_opt) }
  | NEW_EFFECT ne=newEffect
      { NewEffect ne }
  | LAYERED_EFFECT ne=effectDefinition
      { LayeredEffect ne }
  | EFFECT ne=layeredEffectDefinition
      { LayeredEffect ne }
  | SUB_EFFECT se=subEffect
      { SubEffect se }
  | POLYMONADIC_BIND b=polymonadic_bind
      { Polymonadic_bind b }
  | POLYMONADIC_SUBCOMP c=polymonadic_subcomp
      { Polymonadic_subcomp c }

typeDecl:
  (* TODO : change to lident with stratify *)
  | lid=ident tparams=typars ascr_opt=ascribeKind? tcdef=typeDefinition
      { tcdef lid tparams ascr_opt }

typars:
  | x=tvarinsts              { x }
  | x=binders                { x }

tvarinsts:
  | TYP_APP_LESS tvs=separated_nonempty_list(COMMA, tvar) TYP_APP_GREATER
      { map (fun tv -> mk_binder (TVariable(tv)) (range_of_id tv) Kind None) tvs }

typeDefinition:
  |   { (fun id binders kopt -> check_id id; TyconAbstract(id, binders, kopt)) }
  | EQUALS t=typ
      { (fun id binders kopt ->  check_id id; TyconAbbrev(id, binders, kopt, t)) }
  /* A documentation on the first branch creates a conflict with { x with a = ... }/{ a = ... } */
  | EQUALS LBRACE
      record_field_decls=right_flexible_nonempty_list(SEMICOLON, recordFieldDecl)
   RBRACE
      { (fun id binders kopt -> check_id id; TyconRecord(id, binders, kopt, record_field_decls)) }
  (* having the first BAR optional using left-flexible list creates a s/r on FSDOC since any decl can be preceded by a FSDOC *)
  | EQUALS ct_decls=list(constructorDecl)
      { (fun id binders kopt -> check_id id; TyconVariant(id, binders, kopt, ct_decls)) }

recordFieldDecl:
  | qualified_lid=aqualifiedWithAttrs(lident) COLON t=typ 
      { 
        let (qual, attrs), lid = qualified_lid in
        (lid, qual, attrs, t) 
      }

constructorDecl:
  | BAR uid=uident COLON t=typ                { (uid, Some t, false) }
  | BAR uid=uident t_opt=option(OF t=typ {t}) { (uid, t_opt, true) }

attr_letbinding:
  | attr=ioption(attribute) AND lb=letbinding
    { attr, lb }

letbinding:
  | focus_opt=maybeFocus lid=lidentOrOperator lbp=nonempty_list(patternOrMultibinder) ascr_opt=ascribeTyp? EQUALS tm=term
      {
        let pat = mk_pattern (PatVar(lid, None, [])) (rhs parseState 2) in
        let pat = mk_pattern (PatApp (pat, flatten lbp)) (rhs2 parseState 1 3) in
        let pos = rhs2 parseState 1 6 in
        match ascr_opt with
        | None -> (focus_opt, (pat, tm))
        | Some t -> (focus_opt, (mk_pattern (PatAscribed(pat, t)) pos, tm))
      }
  | focus_opt=maybeFocus pat=tuplePattern ascr=ascribeTyp EQUALS tm=term
      { focus_opt, (mk_pattern (PatAscribed(pat, ascr)) (rhs2 parseState 1 4), tm) }
  | focus_opt=maybeFocus pat=tuplePattern EQUALS tm=term
      { focus_opt, (pat, tm) }

/******************************************************************************/
/*                                Effects                                     */
/******************************************************************************/

newEffect:
  | ed=effectRedefinition
  | ed=effectDefinition
    { ed }

effectRedefinition:
  | lid=uident EQUALS t=simpleTerm
    { RedefineEffect(lid, [], t) }

effectDefinition:
  | LBRACE lid=uident bs=binders COLON typ=tmArrow(tmNoEq)
           WITH eds=separated_nonempty_list(SEMICOLON, effectDecl)
    RBRACE
    { DefineEffect(lid, bs, typ, eds) }

layeredEffectDefinition:
  | LBRACE lid=uident bs=binders WITH r=tmNoEq RBRACE
    {
      let typ =  (* bs -> Effect *)
        let first_b, last_b =
          match bs with
          | [] ->
             raise_error (Fatal_SyntaxError,
                          "Syntax error: unexpected empty binders list in the layered effect definition")
                         (range_of_id lid)
          | _ -> hd bs, last bs |> must in
        let r = union_ranges first_b.brange last_b.brange in
        mk_term (Product (bs, mk_term (Name (lid_of_str "Effect")) r Type_level)) r Type_level in
      let rec decls (r:term) =
        match r.tm with
        | Paren r -> decls r
        | Record (None, flds) ->
           flds |> List.map (fun (lid, t) ->
                              mk_decl (Tycon (false,
                                              false,
                                              [TyconAbbrev (ident_of_lid lid, [], None, t)]))
                                      t.range [])
        | _ ->
           raise_error (Fatal_SyntaxError,
                        "Syntax error: layered effect combinators should be declared as a record")
                       r.range in
      DefineEffect (lid, [], typ, decls r) }

effectDecl:
  | lid=lident action_params=binders EQUALS t=simpleTerm
    { mk_decl (Tycon (false, false, [TyconAbbrev(lid, action_params, None, t)])) (rhs2 parseState 1 3) [] }

subEffect:
  | src_eff=quident SQUIGGLY_RARROW tgt_eff=quident EQUALS lift=simpleTerm
      { { msource = src_eff; mdest = tgt_eff; lift_op = NonReifiableLift lift } }
  | src_eff=quident SQUIGGLY_RARROW tgt_eff=quident
    LBRACE
      lift1=separated_pair(IDENT, EQUALS, simpleTerm)
      lift2_opt=ioption(separated_pair(SEMICOLON id=IDENT {id}, EQUALS, simpleTerm))
      /* might be nice for homogeneity if possible : ioption(SEMICOLON) */
    RBRACE
     {
       match lift2_opt with
       | None ->
          begin match lift1 with
          | ("lift", lift) ->
             { msource = src_eff; mdest = tgt_eff; lift_op = LiftForFree lift }
          | ("lift_wp", lift_wp) ->
             { msource = src_eff; mdest = tgt_eff; lift_op = NonReifiableLift lift_wp }
          | _ ->
             raise_error (Fatal_UnexpectedIdentifier, "Unexpected identifier; expected {'lift', and possibly 'lift_wp'}") (lhs parseState)
          end
       | Some (id2, tm2) ->
          let (id1, tm1) = lift1 in
          let lift, lift_wp = match (id1, id2) with
                  | "lift_wp", "lift" -> tm1, tm2
                  | "lift", "lift_wp" -> tm2, tm1
                  | _ -> raise_error (Fatal_UnexpectedIdentifier, "Unexpected identifier; expected {'lift', 'lift_wp'}") (lhs parseState)
          in
          { msource = src_eff; mdest = tgt_eff; lift_op = ReifiableLift (lift, lift_wp) }
     }

polymonadic_bind:
  | LPAREN m_eff=quident COMMA n_eff=quident RPAREN PIPE_RIGHT p_eff=quident EQUALS bind=simpleTerm
      { (m_eff, n_eff, p_eff, bind) }

polymonadic_subcomp:
  | m_eff=quident SUBTYPE n_eff=quident EQUALS subcomp=simpleTerm
    { (m_eff, n_eff, subcomp) }


/******************************************************************************/
/*                        Qualifiers, tags, ...                               */
/******************************************************************************/

qualifier:
  | ASSUME        { Assumption }
  | INLINE        {
    raise_error (Fatal_InlineRenamedAsUnfold, "The 'inline' qualifier has been renamed to 'unfold'") (lhs parseState)
   }
  | UNFOLDABLE    {
              raise_error (Fatal_UnfoldableDeprecated, "The 'unfoldable' qualifier is no longer denotable; it is the default qualifier so just omit it") (lhs parseState)
   }
  | INLINE_FOR_EXTRACTION {
     Inline_for_extraction
  }
  | UNFOLD {
     Unfold_for_unification_and_vcgen
  }
  | IRREDUCIBLE   { Irreducible }
  | NOEXTRACT     { NoExtract }
  | DEFAULT       { DefaultEffect }
  | TOTAL         { TotalEffect }
  | PRIVATE       { Private }
  
  | NOEQUALITY    { Noeq }
  | UNOPTEQUALITY { Unopteq }
  | NEW           { New }
  | LOGIC         { log_issue (lhs parseState) (Warning_logicqualifier,
                                                logic_qualifier_deprecation_warning);
                    Logic }
  | OPAQUE        { Opaque }
  | REIFIABLE     { Reifiable }
  | REFLECTABLE   { Reflectable }

maybeFocus:
  | b=boption(SQUIGGLY_RARROW) { b }

letqualifier:
  | REC         { Rec }
  |             { NoLetQualifier }

(*
 * AR: this should be generalized to:
 *     (a) allow attributes on non-implicit binders
 *     note that in the [@@ case, we choose the Implicit aqual
 *)
aqual: 
  | HASH LBRACK t=thunk(tmNoEq) RBRACK { mk_meta_tac t }
  | HASH      { Implicit }
  | DOLLAR    { Equality }

binderAttributes:
  | LBRACK_AT_AT_AT t=semiColonTermList RBRACK { t }

/******************************************************************************/
/*                         Patterns, binders                                  */
/******************************************************************************/

(* disjunction should be allowed in nested patterns *)
disjunctivePattern:
  | pats=separated_nonempty_list(BAR, tuplePattern) { pats }

tuplePattern:
  | pats=separated_nonempty_list(COMMA, constructorPattern)
      { match pats with | [x] -> x | l -> mk_pattern (PatTuple (l, false)) (rhs parseState 1) }

constructorPattern:
  | pat=constructorPattern COLON_COLON pats=constructorPattern
      { mk_pattern (consPat (rhs parseState 3) pat pats) (rhs2 parseState 1 3) }
  | uid=quident args=nonempty_list(atomicPattern)
      {
        let head_pat = mk_pattern (PatName uid) (rhs parseState 1) in
        mk_pattern (PatApp (head_pat, args)) (rhs2 parseState 1 2)
      }
  | pat=atomicPattern
      { pat }

atomicPattern:
  | LPAREN pat=tuplePattern COLON t=simpleArrow phi_opt=refineOpt RPAREN
      {
        let pos_t = rhs2 parseState 2 4 in
        let pos = rhs2 parseState 1 6 in
        mkRefinedPattern pat t true phi_opt pos_t pos
      }
  | LBRACK pats=separated_list(SEMICOLON, tuplePattern) RBRACK
      { mk_pattern (PatList pats) (rhs2 parseState 1 3) }
  | LBRACE record_pat=right_flexible_nonempty_list(SEMICOLON, fieldPattern) RBRACE
      { mk_pattern (PatRecord record_pat) (rhs2 parseState 1 3) }
  | LENS_PAREN_LEFT pat0=constructorPattern COMMA pats=separated_nonempty_list(COMMA, constructorPattern) LENS_PAREN_RIGHT
      { mk_pattern (PatTuple(pat0::pats, true)) (rhs2 parseState 1 5) }
  | LPAREN pat=tuplePattern RPAREN   { pat }
  | tv=tvar                   { mk_pattern (PatTvar (tv, None, [])) (rhs parseState 1) }
  | LPAREN op=operator RPAREN
      { mk_pattern (PatOp op) (rhs2 parseState 1 3) }
  | UNDERSCORE
      { mk_pattern (PatWild (None, [])) (rhs parseState 1) }
  | HASH UNDERSCORE
      { mk_pattern (PatWild (Some Implicit, [])) (rhs parseState 1) }
  | c=constant
      { mk_pattern (PatConst c) (rhs parseState 1) }
  | qual_id=aqualifiedWithAttrs(lident)
    {
      let (aqual, attrs), lid = qual_id in
      mk_pattern (PatVar (lid, aqual, attrs)) (rhs parseState 1) }
  | uid=quident
      { mk_pattern (PatName uid) (rhs parseState 1) }

fieldPattern:
  | p = separated_pair(qlident, EQUALS, tuplePattern)
      { p }
  | lid=qlident
      { lid, mk_pattern (PatVar (ident_of_lid lid, None, [])) (rhs parseState 1) }

  (* (x : t) is already covered by atomicPattern *)
  (* we do *NOT* allow _ in multibinder () since it creates reduce/reduce conflicts when*)
  (* preprocessing to ocamlyacc/fsyacc (which is expected since the macro are expanded) *)
patternOrMultibinder:
  | LBRACE_BAR UNDERSCORE COLON t=simpleArrow BAR_RBRACE
      { let mt = mk_term (Var tcresolve_lid) (rhs parseState 4) Type_level in
        let w = mk_pattern (PatWild (Some (mk_meta_tac mt), []))
                                 (rhs2 parseState 1 5) in
        let asc = (t, None) in
        [mk_pattern (PatAscribed(w, asc)) (rhs2 parseState 1 5)]
      }

  (* GM: I would rather use lidentOrUnderscore and delete the rule above,
   * but I need to produce a PatWild above, and a PatVar here. However
   * why does PatWild even exist..? *)
  | LBRACE_BAR i=lident COLON t=simpleArrow BAR_RBRACE
      { let mt = mk_term (Var tcresolve_lid) (rhs parseState 4) Type_level in
        let w = mk_pattern (PatVar (i, Some (mk_meta_tac mt), []))
                                 (rhs2 parseState 1 5) in
        let asc = (t, None) in
        [mk_pattern (PatAscribed(w, asc)) (rhs2 parseState 1 5)]
      }

  | LBRACE_BAR t=simpleArrow BAR_RBRACE
      { let mt = mk_term (Var tcresolve_lid) (rhs parseState 2) Type_level in
        let w = mk_pattern (PatVar (gen (rhs2 parseState 1 3), Some (mk_meta_tac mt), []))
                                 (rhs2 parseState 1 3) in
        let asc = (t, None) in
        [mk_pattern (PatAscribed(w, asc)) (rhs2 parseState 1 3)]
      }
  | pat=atomicPattern { [pat] }
  | LPAREN qual_id0=aqualifiedWithAttrs(lident) qual_ids=nonempty_list(aqualifiedWithAttrs(lident)) COLON t=simpleArrow r=refineOpt RPAREN
      {
        let pos = rhs2 parseState 1 7 in
        let t_pos = rhs parseState 5 in
        let qual_ids = qual_id0 :: qual_ids in
        List.map (fun ((aq, attrs), x) -> mkRefinedPattern (mk_pattern (PatVar (x, aq, attrs)) pos) t false r t_pos pos) qual_ids
      }

binder:
  | aqualifiedWithAttrs_lid=aqualifiedWithAttrs(lidentOrUnderscore)
     {
       let (q, attrs), lid = aqualifiedWithAttrs_lid in
       mk_binder_with_attrs (Variable lid) (rhs parseState 1) Type_level q attrs
     }

  | tv=tvar  { mk_binder (TVariable tv) (rhs parseState 1) Kind None  }
       (* small regression here : fun (=x : t) ... is not accepted anymore *)

multiBinder:
  | LBRACE_BAR id=lidentOrUnderscore COLON t=simpleArrow BAR_RBRACE
      { let mt = mk_term (Var tcresolve_lid) (rhs parseState 4) Type_level in
        let r = rhs2 parseState 1 5 in
        [mk_binder (Annotated (id, t)) r Type_level (Some (mk_meta_tac mt))]
      }

  | LBRACE_BAR t=simpleArrow BAR_RBRACE
      { let mt = mk_term (Var tcresolve_lid) (rhs parseState 2) Type_level in
        let r = rhs2 parseState 1 3 in
        let id = gen r in
        [mk_binder (Annotated (id, t)) r Type_level (Some (mk_meta_tac mt))]
      }

  | LPAREN qual_ids=nonempty_list(aqualifiedWithAttrs(lidentOrUnderscore)) COLON t=simpleArrow r=refineOpt RPAREN
     {
       let should_bind_var = match qual_ids with | [ _ ] -> true | _ -> false in
       List.map (fun ((q, attrs), x) ->
         mkRefinedBinder x t should_bind_var r (rhs2 parseState 1 6) q attrs) qual_ids
     }

binders: bss=list(b=binder {[b]} | bs=multiBinder {bs}) { flatten bss }

aqualifiedWithAttrs(X):
  | aq=aqual attrs=binderAttributes x=X { (Some aq, attrs), x }
  | aq=aqual x=X { (Some aq, []), x }
  | attrs=binderAttributes x=X { (None, attrs), x }
  | x=X { (None, []), x }

/******************************************************************************/
/*                      Identifiers, module paths                             */
/******************************************************************************/

qlident:
  | ids=path(lident) { lid_of_ids ids }

quident:
  | ids=path(uident) { lid_of_ids ids }

path(Id):
  | id=Id { [id] }
  | uid=uident DOT p=path(Id) { uid::p }

ident:
  | x=lident { x }
  | x=uident  { x }

lidentOrOperator:
  | id=IDENT
    { mk_ident(id, rhs parseState 1) }
  | LPAREN id=operator RPAREN
    { mk_ident (compile_op' (string_of_id id) (range_of_id id), range_of_id id) }

lidentOrUnderscore:
  | id=IDENT { mk_ident(id, rhs parseState 1)}
  | UNDERSCORE { gen (rhs parseState 1) }

lident:
  | id=IDENT { mk_ident(id, rhs parseState 1)}

uident:
  | id=NAME { mk_ident(id, rhs parseState 1) }

tvar:
  | tv=TVAR { mk_ident(tv, rhs parseState 1) }


/******************************************************************************/
/*                            Types and terms                                 */
/******************************************************************************/

thunk(X): | t=X { mk_term (Abs ([mk_pattern (PatWild (None, [])) (rhs parseState 3)], t)) (rhs parseState 3) Expr }

thunk2(X):
  | t=X
     { let u = mk_term (Const Const_unit) (rhs parseState 3) Expr in
       let t = mk_term (Seq (u, t)) (rhs parseState 3) Expr in
       mk_term (Abs ([mk_pattern (PatWild (None, [])) (rhs parseState 3)], t)) (rhs parseState 3) Expr }

ascribeTyp:
  | COLON t=tmArrow(tmNoEq) tacopt=option(BY tactic=thunk(atomicTerm) {tactic}) { t, tacopt }

(* Remove for stratify *)
ascribeKind:
  | COLON  k=kind { k }

(* Remove for stratify *)
kind:
  | t=tmArrow(tmNoEq) { {t with level=Kind} }


term:
  | e=noSeqTerm
      { e }
  | e1=noSeqTerm SEMICOLON e2=term
      { mk_term (Seq(e1, e2)) (rhs2 parseState 1 3) Expr }
(* Added this form for sequencing; *)
(* but it results in an additional shift/reduce conflict *)
(* ... which is actually be benign, since the same conflict already *)
(*     exists for the previous production *)
  | e1=noSeqTerm SEMICOLON_SEMICOLON e2=term
      { mk_term (Bind(gen (rhs parseState 2), e1, e2)) (rhs2 parseState 1 3) Expr }
  | x=lidentOrUnderscore LONG_LEFT_ARROW e1=noSeqTerm SEMICOLON e2=term
      { mk_term (Bind(x, e1, e2)) (rhs2 parseState 1 5) Expr }

match_returning:
  | RETURNS t=tmIff {t}

noSeqTerm:
  | t=typ  { t }
  | e=tmIff SUBTYPE t=tmIff tactic_opt=option(BY tactic=thunk(typ) {tactic})
      { mk_term (Ascribed(e,{t with level=Expr},tactic_opt)) (rhs2 parseState 1 4) Expr }
  | e1=atomicTermNotQUident op_expr=dotOperator LARROW e3=noSeqTerm
      {
        let (op, e2, _) = op_expr in
        let opid = mk_ident (string_of_id op ^ "<-", range_of_id op) in
        mk_term (Op(opid, [ e1; e2; e3 ])) (rhs2 parseState 1 4) Expr
      }
  | REQUIRES t=typ
      { mk_term (Requires(t, None)) (rhs2 parseState 1 2) Type_level }
  | ENSURES t=typ
      { mk_term (Ensures(t, None)) (rhs2 parseState 1 2) Type_level }
  | DECREASES t=typ
      { mk_term (Decreases (t, None)) (rhs2 parseState 1 2) Type_level }
  | DECREASES LBRACE_COLON_WELL_FOUNDED t=noSeqTerm RBRACE
      (*
       * decreases clause with relation is written as e1 e2,
       *   where e1 is a relation and e2 is a term
       *
       * this is parsed as an app node, so we destruct the app node
       *)
      { match t.tm with
        | App (t1, t2, _) ->
	  let ot = mk_term (WFOrder (t1, t2)) (rhs2 parseState 3 3) Type_level in
	  mk_term (Decreases (ot, None)) (rhs2 parseState 1 4) Type_level
	| _ ->
	  raise_error (Fatal_SyntaxError,
	    "Syntax error: To use well-founded relations, write e1 e2") (rhs parseState 3) }
	  
  | ATTRIBUTES es=nonempty_list(atomicTerm)
      { mk_term (Attributes es) (rhs2 parseState 1 2) Type_level }
  | IF e1=noSeqTerm ret_opt=option(match_returning) THEN e2=noSeqTerm ELSE e3=noSeqTerm
      { mk_term (If(e1, ret_opt, e2, e3)) (rhs2 parseState 1 7) Expr }
  | IF e1=noSeqTerm ret_opt=option(match_returning) THEN e2=noSeqTerm
      {
        let e3 = mk_term (Const Const_unit) (rhs2 parseState 1 5) Expr in
        mk_term (If(e1, ret_opt, e2, e3)) (rhs2 parseState 1 5) Expr
      }
  | TRY e1=term WITH pbs=left_flexible_nonempty_list(BAR, patternBranch)
      {
         let branches = focusBranches (pbs) (rhs2 parseState 1 4) in
         mk_term (TryWith(e1, branches)) (rhs2 parseState 1 4) Expr
      }
  | MATCH e=term ret_opt=option(match_returning) WITH pbs=left_flexible_list(BAR, pb=patternBranch {pb})
      {
        let branches = focusBranches pbs (rhs2 parseState 1 5) in
        mk_term (Match(e, ret_opt, branches)) (rhs2 parseState 1 5) Expr
      }

  | LET OPEN t=term IN e=term
      {
            match t.tm with
            | Ascribed(r, rty, None) ->
              mk_term (LetOpenRecord(r, rty, e)) (rhs2 parseState 1 5) Expr

            | Name uid ->
              mk_term (LetOpen(uid, e)) (rhs2 parseState 1 5) Expr

            | _ ->
              raise_error (Fatal_SyntaxError, "Syntax error: local opens expects either opening\n\
                                               a module or namespace using `let open T in e`\n\
                                               or, a record type with `let open e <: t in e'`")
                          (rhs parseState 3)
      }

  | attrs=ioption(attribute)
    LET q=letqualifier lb=letbinding lbs=list(attr_letbinding) IN e=term
      {
        let lbs = (attrs, lb)::lbs in
        let lbs = focusAttrLetBindings lbs (rhs2 parseState 2 3) in
        mk_term (Let(q, lbs, e)) (rhs2 parseState 1 6) Expr
      }
  | FUNCTION pbs=left_flexible_nonempty_list(BAR, patternBranch)
      {
        let branches = focusBranches pbs (rhs2 parseState 1 2) in
        mk_function branches (lhs parseState) (rhs2 parseState 1 2)
      }
  | ASSUME e=atomicTerm
      { let a = set_lid_range assume_lid (rhs parseState 1) in
        mkExplicitApp (mk_term (Var a) (rhs parseState 1) Expr) [e] (rhs2 parseState 1 2)
      }

  | ASSERT e=atomicTerm tactic_opt=option(BY tactic=thunk2(typ) {tactic})
      {
        match tactic_opt with
        | None ->
          let a = set_lid_range assert_lid (rhs parseState 1) in
          mkExplicitApp (mk_term (Var a) (rhs parseState 1) Expr) [e] (rhs2 parseState 1 2)
        | Some tac ->
          let a = set_lid_range assert_by_tactic_lid (rhs parseState 1) in
          mkExplicitApp (mk_term (Var a) (rhs parseState 1) Expr) [e; tac] (rhs2 parseState 1 4)
      }

   | UNDERSCORE BY tactic=thunk(atomicTerm)
     {
         let a = set_lid_range synth_lid (rhs parseState 1) in
         mkExplicitApp (mk_term (Var a) (rhs parseState 1) Expr) [tactic] (rhs2 parseState 1 2)
     }

   | SYNTH tactic=atomicTerm
     {
         let a = set_lid_range synth_lid (rhs parseState 1) in
         mkExplicitApp (mk_term (Var a) (rhs parseState 1) Expr) [tactic] (rhs2 parseState 1 2)
     }

   | CALC rel=atomicTerm LBRACE init=noSeqTerm SEMICOLON steps=list(calcStep) RBRACE
     {
         mk_term (CalcProof (rel, init, steps)) (rhs2 parseState 1 7) Expr
     }

   | INTRO FORALL bs=binders DOT p=noSeqTerm WITH e=noSeqTerm
     {
        mk_term (IntroForall(bs, p, e)) (rhs2 parseState 1 7) Expr
     }

   | INTRO EXISTS bs=binders DOT p=noSeqTerm WITH vs=list(atomicTerm) AND e=noSeqTerm
     {
        if List.length bs <> List.length vs
        then raise_error (Fatal_SyntaxError, "Syntax error: expected instantiations for all binders") (rhs parseState 7)
        else mk_term (IntroExists(bs, p, vs, e)) (rhs2 parseState 1 9) Expr
     }    

   | INTRO p=tmFormula IMPLIES q=tmFormula WITH y=singleBinder DOT e=noSeqTerm
     {
        mk_term (IntroImplies(p, q, y, e)) (rhs2 parseState 1 8) Expr
     }

   | INTRO p=tmFormula DISJUNCTION q=tmConjunction WITH lr=NAME e=noSeqTerm
     {
        let b =
            if lr = "Left" then true
            else if lr = "Right" then false
            else raise_error (Fatal_SyntaxError, "Syntax error: _intro_ \/ expects either 'Left' or 'Right'") (rhs parseState 6)
        in
        mk_term (IntroOr(b, p, q, e))  (rhs2 parseState 1 7) Expr
     }

   | INTRO p=tmConjunction CONJUNCTION q=tmTuple WITH e1=noSeqTerm AND e2=noSeqTerm
     {
        mk_term (IntroAnd(p, q, e1, e2))  (rhs2 parseState 1 8) Expr
     }

   | ELIM FORALL xs=binders DOT p=noSeqTerm WITH vs=list(atomicTerm)
     {
        mk_term (ElimForall(xs, p, vs)) (rhs2 parseState 1 7) Expr
     }
     
   | ELIM EXISTS bs=binders DOT p=noSeqTerm RETURNS q=noSeqTerm WITH y=singleBinder DOT e=noSeqTerm
     {
        mk_term (ElimExists(bs, p, q, y, e)) (rhs2 parseState 1 11) Expr
     }

   | ELIM p=tmFormula IMPLIES q=tmFormula WITH e=noSeqTerm
     {
        mk_term (ElimImplies(p, q, e)) (rhs2 parseState 1 6) Expr
     }

   | ELIM p=tmFormula DISJUNCTION q=tmConjunction RETURNS r=noSeqTerm WITH x=singleBinder DOT e1=noSeqTerm AND y=singleBinder DOT e2=noSeqTerm
     {
        mk_term (ElimOr(p, q, r, x, e1, y, e2)) (rhs2 parseState 1 14) Expr
     }    

   | ELIM p=tmConjunction CONJUNCTION q=tmTuple RETURNS r=noSeqTerm WITH xs=binders DOT e=noSeqTerm
     {
        match xs with
        | [x;y] -> mk_term (ElimAnd(p, q, r, x, y, e)) (rhs2 parseState 1 10) Expr
     }

singleBinder:
  | bs=binders
    {
       match bs with
       | [b] -> b
       | _ -> raise_error (Fatal_SyntaxError, "Syntax error: expected a single binder") (rhs parseState 1)
    }
    
calcRel:
  | i=binop_name { mk_term (Op (i, [])) (rhs parseState 1) Expr }
  | BACKTICK id=qlident BACKTICK { mk_term (Var id) (rhs2 parseState 2 4) Un }
  | t=atomicTerm { t }

calcStep:
   | rel=calcRel LBRACE justif=option(term) RBRACE next=noSeqTerm SEMICOLON
     {
         let justif =
             match justif with
             | Some t -> t
             | None -> mk_term (Const Const_unit) (rhs2 parseState 2 4) Expr
         in
         CalcStep (rel, justif, next)
     }

typ:
  | t=simpleTerm { t }

  | q=quantifier bs=binders DOT trigger=trigger e=noSeqTerm
      {
        match bs with
        | [] ->
          raise_error (Fatal_MissingQuantifierBinder, "Missing binders for a quantifier") (rhs2 parseState 1 3)
        | _ ->
          let idents = idents_of_binders bs (rhs2 parseState 1 3) in
          mk_term (q (bs, (idents, trigger), e)) (rhs2 parseState 1 5) Formula
      }

%inline quantifier:
  | FORALL { fun x -> QForall x }
  | EXISTS { fun x -> QExists x}

trigger:
  |   { [] }
  | LBRACE_COLON_PATTERN pats=disjunctivePats RBRACE { pats }

disjunctivePats:
  | pats=separated_nonempty_list(DISJUNCTION, conjunctivePat) { pats }

conjunctivePat:
  | pats=separated_nonempty_list(SEMICOLON, appTerm)          { pats }

simpleTerm:
  | e=tmIff { e }
  | FUN pats=nonempty_list(patternOrMultibinder) RARROW e=term
      { mk_term (Abs(flatten pats, e)) (rhs2 parseState 1 4) Un }

maybeFocusArrow:
  | RARROW          { false }
  | SQUIGGLY_RARROW { true }

patternBranch:
  | pat=disjunctivePattern when_opt=maybeWhen focus=maybeFocusArrow e=term
      {
        let pat = match pat with
          | [p] -> p
          | ps -> mk_pattern (PatOr ps) (rhs2 parseState 1 1)
        in
        (focus, (pat, when_opt, e))
      }

%inline maybeWhen:
  |                      { None }
  | WHEN e=tmFormula     { Some e }



tmIff:
  | e1=tmImplies IFF e2=tmIff
      { mk_term (Op(mk_ident("<==>", rhs parseState 2), [e1; e2])) (rhs2 parseState 1 3) Formula }
  | e=tmImplies { e }

tmImplies:
  | e1=tmArrow(tmFormula) IMPLIES e2=tmImplies
      { mk_term (Op(mk_ident("==>", rhs parseState 2), [e1; e2])) (rhs2 parseState 1 3) Formula }
  | e=tmArrow(tmFormula)
      { e }


(* Tm : either tmFormula, containing EQUALS or tmNoEq, without EQUALS *)
tmArrow(Tm):
  | dom=tmArrowDomain(Tm) RARROW tgt=tmArrow(Tm)
     {
       let ((aq_opt, attrs), dom_tm) = dom in
       let b = match extract_named_refinement dom_tm with
         | None -> mk_binder_with_attrs (NoName dom_tm) (rhs parseState 1) Un aq_opt attrs
         | Some (x, t, f) -> mkRefinedBinder x t true f (rhs2 parseState 1 1) aq_opt attrs
       in
       mk_term (Product([b], tgt)) (rhs2 parseState 1 3)  Un
     }
  | e=Tm { e }

simpleArrow:
  | dom=simpleArrowDomain RARROW tgt=simpleArrow
     {
       let ((aq_opt, attrs), dom_tm) = dom in
       let b = match extract_named_refinement dom_tm with
         | None -> mk_binder_with_attrs (NoName dom_tm) (rhs parseState 1) Un aq_opt attrs
         | Some (x, t, f) -> mkRefinedBinder x t true f (rhs2 parseState 1 1) aq_opt attrs
       in
       mk_term (Product([b], tgt)) (rhs2 parseState 1 3)  Un
     }
  | e=tmEqNoRefinement { e }

simpleArrowDomain:
  | LBRACE_BAR t=tmEqNoRefinement BAR_RBRACE
      { let mt = mk_term (Var tcresolve_lid) (rhs parseState 4) Type_level in
        ((Some (mk_meta_tac mt), []), t)
      }
  | aq_opt=ioption(aqual) attrs_opt=ioption(binderAttributes) dom_tm=tmEqNoRefinement { (aq_opt, none_to_empty_list attrs_opt), dom_tm }

(* Tm already account for ( term ), we need to add an explicit case for (#Tm) *)
%inline tmArrowDomain(Tm):
  | LBRACE_BAR t=Tm BAR_RBRACE
      { let mt = mk_term (Var tcresolve_lid) (rhs parseState 4) Type_level in
        ((Some (mk_meta_tac mt), []), t)
      }
  | LPAREN q=aqual attrs_opt=ioption(binderAttributes) dom_tm=Tm RPAREN { (Some q, none_to_empty_list attrs_opt), dom_tm }
  | aq_opt=ioption(aqual) attrs_opt=ioption(binderAttributes) dom_tm=Tm { (aq_opt, none_to_empty_list attrs_opt), dom_tm }

tmFormula:
  | e1=tmFormula DISJUNCTION e2=tmConjunction
      { mk_term (Op(mk_ident("\\/", rhs parseState 2), [e1;e2])) (rhs2 parseState 1 3) Formula }
  | e=tmConjunction { e }

tmConjunction:
  | e1=tmConjunction CONJUNCTION e2=tmTuple
      { mk_term (Op(mk_ident("/\\", rhs parseState 2), [e1;e2])) (rhs2 parseState 1 3) Formula }
  | e=tmTuple { e }

tmTuple:
  | el=separated_nonempty_list(COMMA, tmEq)
      {
        match el with
          | [x] -> x
          | components -> mkTuple components (rhs2 parseState 1 1)
      }


tmEqWith(X):
  | e1=tmEqWith(X) EQUALS e2=tmEqWith(X)
      { mk_term (Op(mk_ident("=", rhs parseState 2), [e1; e2])) (rhs2 parseState 1 3) Un}
  (* non-associativity of COLON_EQUALS is currently not well handled by fsyacc which reports a s/r conflict *)
  (* see https:/ /github.com/fsprojects/FsLexYacc/issues/39 *)
  | e1=tmEqWith(X) COLON_EQUALS e2=tmEqWith(X)
      { mk_term (Op(mk_ident(":=", rhs parseState 2), [e1; e2])) (rhs2 parseState 1 3) Un}
  | e1=tmEqWith(X) PIPE_RIGHT e2=tmEqWith(X)
      { mk_term (Op(mk_ident("|>", rhs parseState 2), [e1; e2])) (rhs2 parseState 1 3) Un}
  | e1=tmEqWith(X) op=operatorInfix0ad12 e2=tmEqWith(X)
      { mk_term (Op(op, [e1; e2])) (rhs2 parseState 1 3) Un}
  | e1=tmEqWith(X) MINUS e2=tmEqWith(X)
      { mk_term (Op(mk_ident("-", rhs parseState 2), [e1; e2])) (rhs2 parseState 1 3) Un}
  | MINUS e=tmEqWith(X)
      { mk_uminus e (rhs parseState 1) (rhs2 parseState 1 2) Expr }
  | QUOTE e=tmEqWith(X)
      { mk_term (Quote (e, Dynamic)) (rhs2 parseState 1 3) Un }
  | BACKTICK e=tmEqWith(X)
      { mk_term (Quote (e, Static)) (rhs2 parseState 1 3) Un }
  | BACKTICK_AT e=atomicTerm
      { let q = mk_term (Quote (e, Dynamic)) (rhs2 parseState 1 3) Un in
        mk_term (Antiquote q) (rhs2 parseState 1 3) Un }
  | BACKTICK_HASH e=atomicTerm
      { mk_term (Antiquote e) (rhs2 parseState 1 3) Un }
  | e=tmNoEqWith(X)
      { e }

tmNoEqWith(X):
  | e1=tmNoEqWith(X) COLON_COLON e2=tmNoEqWith(X)
      { consTerm (rhs parseState 2) e1 e2 }
  | e1=tmNoEqWith(X) AMP e2=tmNoEqWith(X)
      {
            let dom =
               match extract_named_refinement e1 with
               | Some (x, t, f) ->
                 let dom = mkRefinedBinder x t true f (rhs parseState 1) None [] in
                 Inl dom
               | _ ->
                 Inr e1
            in
            let tail = e2 in
            let dom, res =
                match tail.tm with
                | Sum(dom', res) -> dom::dom', res
                | _ -> [dom], tail
            in
            mk_term (Sum(dom, res)) (rhs2 parseState 1 3) Type_level
      }
  | e1=tmNoEqWith(X) op=OPINFIX3 e2=tmNoEqWith(X)
      { mk_term (Op(mk_ident(op, rhs parseState 2), [e1; e2])) (rhs2 parseState 1 3) Un}
  | e1=tmNoEqWith(X) BACKTICK op=tmNoEqWith(X) BACKTICK e2=tmNoEqWith(X)
      { mkApp op [ e1, Infix; e2, Nothing ] (rhs2 parseState 1 5) }
 | e1=tmNoEqWith(X) op=OPINFIX4 e2=tmNoEqWith(X)
      { mk_term (Op(mk_ident(op, rhs parseState 2), [e1; e2])) (rhs2 parseState 1 3) Un}
  | LBRACE e=recordExp RBRACE { e }
  | BACKTICK_PERC e=atomicTerm
      { mk_term (VQuote e) (rhs2 parseState 1 3) Un }
  | op=TILDE e=atomicTerm
      { mk_term (Op(mk_ident (op, rhs parseState 1), [e])) (rhs2 parseState 1 2) Formula }
  | e=X { e }

binop_name:
  | o=OPINFIX0a              { mk_ident (o, rhs parseState 1) }
  | o=OPINFIX0b              { mk_ident (o, rhs parseState 1) }
  | o=OPINFIX0c              { mk_ident (o, rhs parseState 1) }
  | o=EQUALS                 { mk_ident ("=", rhs parseState 1) }
  | o=OPINFIX0d              { mk_ident (o, rhs parseState 1) }
  | o=OPINFIX1               { mk_ident (o, rhs parseState 1) }
  | o=OPINFIX2               { mk_ident (o, rhs parseState 1) }
  | o=OPINFIX3               { mk_ident (o, rhs parseState 1) }
  | o=OPINFIX4               { mk_ident (o, rhs parseState 1) }
  | o=IMPLIES                { mk_ident ("==>", rhs parseState 1) }
  | o=CONJUNCTION            { mk_ident ("/\\", rhs parseState 1) }
  | o=DISJUNCTION            { mk_ident ("\\/", rhs parseState 1) }
  | o=IFF                    { mk_ident ("<==>", rhs parseState 1) }
  | o=PIPE_RIGHT             { mk_ident ("|>", rhs parseState 1) }
  | o=COLON_EQUALS           { mk_ident (":=", rhs parseState 1) }
  | o=COLON_COLON            { mk_ident ("::", rhs parseState 1) }
  | o=OP_MIXFIX_ASSIGNMENT   { mk_ident (o, rhs parseState 1) }
  | o=OP_MIXFIX_ACCESS       { mk_ident (o, rhs parseState 1) }

tmEqNoRefinement:
  | e=tmEqWith(appTerm) { e }

tmEq:
  | e=tmEqWith(tmRefinement)  { e }

tmNoEq:
  | e=tmNoEqWith(tmRefinement) { e }

tmRefinement:
  | id=lidentOrUnderscore COLON e=appTerm phi_opt=refineOpt
      {
        let t = match phi_opt with
          | None -> NamedTyp(id, e)
          | Some phi -> Refine(mk_binder (Annotated(id, e)) (rhs2 parseState 1 3) Type_level None, phi)
        in mk_term t (rhs2 parseState 1 4) Type_level
      }
  | e=appTerm  { e }

refineOpt:
  | phi_opt=option(LBRACE phi=formula RBRACE {phi}) {phi_opt}

%inline formula:
  | e=noSeqTerm { {e with level=Formula} }

recordExp:
  | record_fields=right_flexible_nonempty_list(SEMICOLON, simpleDef)
      { mk_term (Record (None, record_fields)) (rhs parseState 1) Expr }
  | e=appTerm WITH  record_fields=right_flexible_nonempty_list(SEMICOLON, simpleDef)
      { mk_term (Record (Some e, record_fields)) (rhs2 parseState 1 3) Expr }

simpleDef:
  | e=separated_pair(qlident, EQUALS, noSeqTerm) { e }
  | lid=qlident { lid, mk_term (Name (lid_of_ids [ ident_of_lid lid ])) (rhs parseState 1) Un }

appTerm:
  | head=indexingTerm args=list(argTerm)
      { mkApp head (map (fun (x,y) -> (y,x)) args) (rhs2 parseState 1 2) }

argTerm:
  | x=pair(maybeHash, indexingTerm) { x }
  | u=universe { u }

%inline maybeHash:
  |      { Nothing }
  | HASH { Hash }

indexingTerm:
  | e1=atomicTermNotQUident op_exprs=nonempty_list(dotOperator)
      {
        List.fold_left (fun e1 (op, e2, r) ->
            mk_term (Op(op, [ e1; e2 ])) (union_ranges e1.range r) Expr)
            e1 op_exprs
      }
  | e=atomicTerm
    { e }

atomicTerm:
  | x=atomicTermNotQUident
    { x }
  | x=atomicTermQUident
    { x }
  | x=opPrefixTerm(atomicTermQUident)
    { x }

atomicTermQUident:
  | id=quident
    {
        let t = Name id in
        let e = mk_term t (rhs parseState 1) Un in
              e
    }
  | id=quident DOT_LPAREN t=term RPAREN
    {
      mk_term (LetOpen (id, t)) (rhs2 parseState 1 4) Expr
    }

atomicTermNotQUident:
  | UNDERSCORE { mk_term Wild (rhs parseState 1) Un }
  | tv=tvar     { mk_term (Tvar tv) (rhs parseState 1) Type_level }
  | c=constant { mk_term (Const c) (rhs parseState 1) Expr }
  | x=opPrefixTerm(atomicTermNotQUident)
    { x }
  | LPAREN op=operator RPAREN
      { mk_term (Op(op, [])) (rhs2 parseState 1 3) Un }
  | LENS_PAREN_LEFT e0=tmEq COMMA el=separated_nonempty_list(COMMA, tmEq) LENS_PAREN_RIGHT
      { mkDTuple (e0::el) (rhs2 parseState 1 5) }
  | e=projectionLHS field_projs=list(DOT id=qlident {id})
      { fold_left (fun e lid -> mk_term (Project(e, lid)) (rhs2 parseState 1 2) Expr ) e field_projs }
  | BEGIN e=term END
      { e }

(* Tm: atomicTermQUident or atomicTermNotQUident *)
opPrefixTerm(Tm):
  | op=OPPREFIX e=Tm
      { mk_term (Op(mk_ident(op, rhs parseState 1), [e])) (rhs2 parseState 1 2) Expr }


projectionLHS:
  | e=qidentWithTypeArgs(qlident, option(fsTypeArgs))
      { e }
  | e=qidentWithTypeArgs(quident, some(fsTypeArgs))
      { e }
  | LPAREN e=term sort_opt=option(pair(hasSort, simpleTerm)) RPAREN
      {
        (* Note: we have to keep the parentheses here. Consider t * u * v. This
         * is parsed as Op2( *, Op2( *, t, u), v). The desugaring phase then looks
         * up * and figures out that it hasn't been overridden, meaning that
         * it's a tuple type, and proceeds to flatten out the whole tuple. Now
         * consider (t * u) * v. We keep the Paren node, which prevents the
         * flattening from happening, hence ensuring the proper type is
         * generated. *)
        let e1 = match sort_opt with
          | None -> e
          | Some (level, t) -> mk_term (Ascribed(e,{t with level=level},None)) (rhs2 parseState 1 4) level
        in mk_term (Paren e1) (rhs2 parseState 1 4) (e.level)
      }
  | LBRACK_BAR es=semiColonTermList BAR_RBRACK
      {
        let l = mkConsList (rhs2 parseState 1 3) es in
        let pos = (rhs2 parseState 1 3) in
        mkExplicitApp (mk_term (Var (array_of_list_lid)) pos Expr) [l] pos
      }
  | LBRACK es=semiColonTermList RBRACK
      { mkConsList (rhs2 parseState 1 3) es }
  | PERCENT_LBRACK es=semiColonTermList RBRACK
      { mk_term (LexList es) (rhs2 parseState 1 3) Type_level }
  | BANG_LBRACE es=separated_list(COMMA, appTerm) RBRACE
      { mkRefSet (rhs2 parseState 1 3) es }
  | ns=quident QMARK_DOT id=lident
      { mk_term (Projector (ns, id)) (rhs2 parseState 1 3) Expr }
  | lid=quident QMARK
      { mk_term (Discrim lid) (rhs2 parseState 1 2) Un }

fsTypeArgs:
  | TYP_APP_LESS targs=separated_nonempty_list(COMMA, atomicTerm) TYP_APP_GREATER
    {targs}

(* Qid : quident or qlident.
   TypeArgs : option(fsTypeArgs) or someFsTypeArgs. *)
qidentWithTypeArgs(Qid,TypeArgs):
  | id=Qid targs_opt=TypeArgs
      {
        let t = if is_name id then Name id else Var id in
        let e = mk_term t (rhs parseState 1) Un in
        match targs_opt with
        | None -> e
        | Some targs -> mkFsTypApp e targs (rhs2 parseState 1 2)
      }

hasSort:
  (* | SUBTYPE { Expr } *)
  | SUBKIND { Type_level } (* Remove with stratify *)

  (* use flexible_list *)
%inline semiColonTermList:
  | l=right_flexible_list(SEMICOLON, noSeqTerm) { l }

constant:
  | LPAREN_RPAREN { Const_unit }
  | n=INT
     {
        if snd n then
          log_issue (lhs parseState) (Error_OutOfRange, "This number is outside the allowable range for representable integer constants");
        Const_int (fst n, None)
     }
  | c=CHAR { Const_char c }
  | s=STRING { Const_string (s,lhs(parseState)) }
  | bs=BYTEARRAY { Const_bytearray (bs,lhs(parseState)) }
  | TRUE { Const_bool true }
  | FALSE { Const_bool false }
  | r=REAL { Const_real r }
  | f=IEEE64 { Const_float f }
  | n=UINT8 { Const_int (n, Some (Unsigned, Int8)) }
  | n=INT8
      {
        if snd n then
          log_issue (lhs(parseState)) (Error_OutOfRange, "This number is outside the allowable range for 8-bit signed integers");
        Const_int (fst n, Some (Signed, Int8))
      }
  | n=UINT16 { Const_int (n, Some (Unsigned, Int16)) }
  | n=INT16
      {
        if snd n then
          log_issue (lhs(parseState)) (Error_OutOfRange, "This number is outside the allowable range for 16-bit signed integers");
        Const_int (fst n, Some (Signed, Int16))
      }
  | n=UINT32 { Const_int (n, Some (Unsigned, Int32)) }
  | n=INT32
      {
        if snd n then
          log_issue (lhs(parseState)) (Error_OutOfRange, "This number is outside the allowable range for 32-bit signed integers");
        Const_int (fst n, Some (Signed, Int32))
      }
  | n=UINT64 { Const_int (n, Some (Unsigned, Int64)) }
  | n=INT64
      {
        if snd n then
          log_issue (lhs(parseState)) (Error_OutOfRange, "This number is outside the allowable range for 64-bit signed integers");
        Const_int (fst n, Some (Signed, Int64))
      }
  (* TODO : What about reflect ? There is also a constant representing it *)
  | REIFY   { Const_reify }
  | RANGE_OF     { Const_range_of }
  | SET_RANGE_OF { Const_set_range_of }


universe:
  | UNIV_HASH ua=atomicUniverse { (UnivApp, ua) }

universeFrom:
  | ua=atomicUniverse { ua }
  | u1=universeFrom op_plus=OPINFIX2 u2=universeFrom
       {
         if op_plus <> "+"
         then log_issue (rhs parseState 2) (Error_OpPlusInUniverse, ("The operator " ^ op_plus ^ " was found in universe context."
                           ^ "The only allowed operator in that context is +."));
         mk_term (Op(mk_ident (op_plus, rhs parseState 2), [u1 ; u2])) (rhs2 parseState 1 3) Expr
       }
  | max=ident us=nonempty_list(atomicUniverse)
      {
        if string_of_id max <> string_of_lid max_lid
        then log_issue (rhs parseState 1) (Error_InvalidUniverseVar, "A lower case ident " ^ string_of_id max ^
                          " was found in a universe context. " ^
                          "It should be either max or a universe variable 'usomething.");
        let max = mk_term (Var (lid_of_ids [max])) (rhs parseState 1) Expr in
        mkApp max (map (fun u -> u, Nothing) us) (rhs2 parseState 1 2)
      }

atomicUniverse:
  | UNDERSCORE
      { mk_term Wild (rhs parseState 1) Expr }
  | n=INT
      {
        if snd n then
          log_issue (lhs(parseState)) (Error_OutOfRange, "This number is outside the allowable range for representable integer constants");
        mk_term (Const (Const_int (fst n, None))) (rhs parseState 1) Expr
      }
  | u=lident { mk_term (Uvar u) (range_of_id u) Expr }
  | LPAREN u=universeFrom RPAREN
    { u (*mk_term (Paren u) (rhs2 parseState 1 3) Expr*) }

warn_error_list:
  | e=warn_error EOF { e }

warn_error:
  | f=flag r=range
    { [(f, r)] }
  | f=flag r=range e=warn_error
    { (f, r) :: e }

flag:
  | op=OPINFIX1
    { if op = "@" then CAlwaysError else failwith (format1 "unexpected token %s in warn-error list" op)}
  | op=OPINFIX2
    { if op = "+" then CWarning else failwith (format1 "unexpected token %s in warn-error list" op)}
  | MINUS
          { CSilent }

range:
  | i=INT
    { format2 "%s..%s" (fst i) (fst i) }
  | r=RANGE
    { r }


/******************************************************************************/
/*                       Miscellanous, tools                                   */
/******************************************************************************/

string:
  | s=STRING { s }

%inline operator:
  | op=OPPREFIX
    { mk_ident (op, rhs parseState 1) }
  | op=binop_name
    { op }
  | op=TILDE
    { mk_ident (op, rhs parseState 1) }

/* These infix operators have a lower precedence than EQUALS */
%inline operatorInfix0ad12:
  | op=OPINFIX0a
  | op=OPINFIX0b
  | op=OPINFIX0c
  | op=OPINFIX0d
  | op=OPINFIX1
  | op=OPINFIX2
     { mk_ident (op, rhs parseState 1) }

%inline dotOperator:
  | DOT_LPAREN e=term RPAREN { mk_ident (".()", rhs parseState 1), e, rhs2 parseState 1 3 }
  | DOT_LBRACK e=term RBRACK { mk_ident (".[]", rhs parseState 1), e, rhs2 parseState 1 3 }
  | DOT_LBRACK_BAR e=term BAR_RBRACK { mk_ident (".[||]", rhs parseState 1), e, rhs2 parseState 1 3 }
  | DOT_LENS_PAREN_LEFT e=term LENS_PAREN_RIGHT { mk_ident (".(||)", rhs parseState 1), e, rhs2 parseState 1 3 }

some(X):
  | x=X { Some x }

right_flexible_list(SEP, X):
  |     { [] }
  | x=X { [x] }
  | x=X SEP xs=right_flexible_list(SEP, X) { x :: xs }

right_flexible_nonempty_list(SEP, X):
  | x=X { [x] }
  | x=X SEP xs=right_flexible_list(SEP, X) { x :: xs }

reverse_left_flexible_list(delim, X):
| (* nothing *)
   { [] }
| x = X
   { [x] }
| xs = reverse_left_flexible_list(delim, X) delim x = X
   { x :: xs }

%inline left_flexible_list(delim, X):
 xs = reverse_left_flexible_list(delim, X)
   { List.rev xs }

reverse_left_flexible_nonempty_list(delim, X):
| ioption(delim) x = X
   { [x] }
| xs = reverse_left_flexible_nonempty_list(delim, X) delim x = X
   { x :: xs }

%inline left_flexible_nonempty_list(delim, X):
 xs = reverse_left_flexible_nonempty_list(delim, X)
   { List.rev xs }
