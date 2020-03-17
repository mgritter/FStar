open Prims
type annotated_pat =
  (FStar_Syntax_Syntax.pat * (FStar_Syntax_Syntax.bv *
    FStar_Syntax_Syntax.typ) Prims.list)
let (desugar_disjunctive_pattern :
  (FStar_Syntax_Syntax.pat' FStar_Syntax_Syntax.withinfo_t *
    (FStar_Syntax_Syntax.bv * FStar_Syntax_Syntax.term'
    FStar_Syntax_Syntax.syntax) Prims.list) Prims.list ->
    FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax
      FStar_Pervasives_Native.option ->
      FStar_Syntax_Syntax.term -> FStar_Syntax_Syntax.branch Prims.list)
  =
  fun annotated_pats  ->
    fun when_opt  ->
      fun branch1  ->
        FStar_All.pipe_right annotated_pats
          (FStar_List.map
             (fun uu____103  ->
                match uu____103 with
                | (pat,annots) ->
                    let branch2 =
                      FStar_List.fold_left
                        (fun br  ->
                           fun uu____158  ->
                             match uu____158 with
                             | (bv,ty) ->
                                 let lb =
                                   let uu____176 =
                                     FStar_Syntax_Syntax.bv_to_name bv  in
                                   FStar_Syntax_Util.mk_letbinding
                                     (FStar_Util.Inl bv) [] ty
                                     FStar_Parser_Const.effect_Tot_lid
                                     uu____176 [] br.FStar_Syntax_Syntax.pos
                                    in
                                 let branch2 =
                                   let uu____182 =
                                     let uu____183 =
                                       FStar_Syntax_Syntax.mk_binder bv  in
                                     [uu____183]  in
                                   FStar_Syntax_Subst.close uu____182 branch1
                                    in
                                 FStar_Syntax_Syntax.mk
                                   (FStar_Syntax_Syntax.Tm_let
                                      ((false, [lb]), branch2))
                                   FStar_Pervasives_Native.None
                                   br.FStar_Syntax_Syntax.pos) branch1 annots
                       in
                    FStar_Syntax_Util.branch (pat, when_opt, branch2)))
  
let (trans_qual :
  FStar_Range.range ->
    FStar_Ident.lident FStar_Pervasives_Native.option ->
      FStar_Parser_AST.qualifier -> FStar_Syntax_Syntax.qualifier)
  =
  fun r  ->
    fun maybe_effect_id  ->
      fun uu___0_240  ->
        match uu___0_240 with
        | FStar_Parser_AST.Private  -> FStar_Syntax_Syntax.Private
        | FStar_Parser_AST.Assumption  -> FStar_Syntax_Syntax.Assumption
        | FStar_Parser_AST.Unfold_for_unification_and_vcgen  ->
            FStar_Syntax_Syntax.Unfold_for_unification_and_vcgen
        | FStar_Parser_AST.Inline_for_extraction  ->
            FStar_Syntax_Syntax.Inline_for_extraction
        | FStar_Parser_AST.NoExtract  -> FStar_Syntax_Syntax.NoExtract
        | FStar_Parser_AST.Irreducible  -> FStar_Syntax_Syntax.Irreducible
        | FStar_Parser_AST.Logic  -> FStar_Syntax_Syntax.Logic
        | FStar_Parser_AST.TotalEffect  -> FStar_Syntax_Syntax.TotalEffect
        | FStar_Parser_AST.Effect_qual  -> FStar_Syntax_Syntax.Effect
        | FStar_Parser_AST.New  -> FStar_Syntax_Syntax.New
        | FStar_Parser_AST.Abstract  -> FStar_Syntax_Syntax.Abstract
        | FStar_Parser_AST.Opaque  ->
            (FStar_Errors.log_issue r
               (FStar_Errors.Warning_DeprecatedOpaqueQualifier,
                 "The 'opaque' qualifier is deprecated since its use was strangely schizophrenic. There were two overloaded uses: (1) Given 'opaque val f : t', the behavior was to exclude the definition of 'f' to the SMT solver. This corresponds roughly to the new 'irreducible' qualifier. (2) Given 'opaque type t = t'', the behavior was to provide the definition of 't' to the SMT solver, but not to inline it, unless absolutely required for unification. This corresponds roughly to the behavior of 'unfoldable' (which is currently the default).");
             FStar_Syntax_Syntax.Visible_default)
        | FStar_Parser_AST.Reflectable  ->
            (match maybe_effect_id with
             | FStar_Pervasives_Native.None  ->
                 FStar_Errors.raise_error
                   (FStar_Errors.Fatal_ReflectOnlySupportedOnEffects,
                     "Qualifier reflect only supported on effects") r
             | FStar_Pervasives_Native.Some effect_id ->
                 FStar_Syntax_Syntax.Reflectable effect_id)
        | FStar_Parser_AST.Reifiable  -> FStar_Syntax_Syntax.Reifiable
        | FStar_Parser_AST.Noeq  -> FStar_Syntax_Syntax.Noeq
        | FStar_Parser_AST.Unopteq  -> FStar_Syntax_Syntax.Unopteq
        | FStar_Parser_AST.DefaultEffect  ->
            FStar_Errors.raise_error
              (FStar_Errors.Fatal_DefaultQualifierNotAllowedOnEffects,
                "The 'default' qualifier on effects is no longer supported")
              r
        | FStar_Parser_AST.Inline  ->
            FStar_Errors.raise_error
              (FStar_Errors.Fatal_UnsupportedQualifier,
                "Unsupported qualifier") r
        | FStar_Parser_AST.Visible  ->
            FStar_Errors.raise_error
              (FStar_Errors.Fatal_UnsupportedQualifier,
                "Unsupported qualifier") r
  
let (trans_pragma : FStar_Parser_AST.pragma -> FStar_Syntax_Syntax.pragma) =
  fun uu___1_260  ->
    match uu___1_260 with
    | FStar_Parser_AST.SetOptions s -> FStar_Syntax_Syntax.SetOptions s
    | FStar_Parser_AST.ResetOptions sopt ->
        FStar_Syntax_Syntax.ResetOptions sopt
    | FStar_Parser_AST.PushOptions sopt ->
        FStar_Syntax_Syntax.PushOptions sopt
    | FStar_Parser_AST.PopOptions  -> FStar_Syntax_Syntax.PopOptions
    | FStar_Parser_AST.RestartSolver  -> FStar_Syntax_Syntax.RestartSolver
    | FStar_Parser_AST.LightOff  -> FStar_Syntax_Syntax.LightOff
  
let (as_imp :
  FStar_Parser_AST.imp ->
    FStar_Syntax_Syntax.arg_qualifier FStar_Pervasives_Native.option)
  =
  fun uu___2_278  ->
    match uu___2_278 with
    | FStar_Parser_AST.Hash  ->
        FStar_Pervasives_Native.Some FStar_Syntax_Syntax.imp_tag
    | uu____281 -> FStar_Pervasives_Native.None
  
let arg_withimp_e :
  'Auu____289 .
    FStar_Parser_AST.imp ->
      'Auu____289 ->
        ('Auu____289 * FStar_Syntax_Syntax.arg_qualifier
          FStar_Pervasives_Native.option)
  = fun imp  -> fun t  -> (t, (as_imp imp)) 
let arg_withimp_t :
  'Auu____315 .
    FStar_Parser_AST.imp ->
      'Auu____315 ->
        ('Auu____315 * FStar_Syntax_Syntax.arg_qualifier
          FStar_Pervasives_Native.option)
  =
  fun imp  ->
    fun t  ->
      match imp with
      | FStar_Parser_AST.Hash  ->
          (t, (FStar_Pervasives_Native.Some FStar_Syntax_Syntax.imp_tag))
      | uu____334 -> (t, FStar_Pervasives_Native.None)
  
let (contains_binder : FStar_Parser_AST.binder Prims.list -> Prims.bool) =
  fun binders  ->
    FStar_All.pipe_right binders
      (FStar_Util.for_some
         (fun b  ->
            match b.FStar_Parser_AST.b with
            | FStar_Parser_AST.Annotated uu____355 -> true
            | uu____361 -> false))
  
let rec (unparen : FStar_Parser_AST.term -> FStar_Parser_AST.term) =
  fun t  ->
    match t.FStar_Parser_AST.tm with
    | FStar_Parser_AST.Paren t1 -> unparen t1
    | uu____370 -> t
  
let (tm_type_z : FStar_Range.range -> FStar_Parser_AST.term) =
  fun r  ->
    let uu____377 =
      let uu____378 = FStar_Ident.lid_of_path ["Type0"] r  in
      FStar_Parser_AST.Name uu____378  in
    FStar_Parser_AST.mk_term uu____377 r FStar_Parser_AST.Kind
  
let (tm_type : FStar_Range.range -> FStar_Parser_AST.term) =
  fun r  ->
    let uu____388 =
      let uu____389 = FStar_Ident.lid_of_path ["Type"] r  in
      FStar_Parser_AST.Name uu____389  in
    FStar_Parser_AST.mk_term uu____388 r FStar_Parser_AST.Kind
  
let rec (is_comp_type :
  FStar_Syntax_DsEnv.env -> FStar_Parser_AST.term -> Prims.bool) =
  fun env  ->
    fun t  ->
      let uu____405 =
        let uu____406 = unparen t  in uu____406.FStar_Parser_AST.tm  in
      match uu____405 with
      | FStar_Parser_AST.Name l ->
          let uu____409 = FStar_Syntax_DsEnv.try_lookup_effect_name env l  in
          FStar_All.pipe_right uu____409 FStar_Option.isSome
      | FStar_Parser_AST.Construct (l,uu____416) ->
          let uu____429 = FStar_Syntax_DsEnv.try_lookup_effect_name env l  in
          FStar_All.pipe_right uu____429 FStar_Option.isSome
      | FStar_Parser_AST.App (head1,uu____436,uu____437) ->
          is_comp_type env head1
      | FStar_Parser_AST.Paren t1 -> failwith "impossible"
      | FStar_Parser_AST.Ascribed (t1,uu____442,uu____443) ->
          is_comp_type env t1
      | FStar_Parser_AST.LetOpen (uu____448,t1) -> is_comp_type env t1
      | uu____450 -> false
  
let (unit_ty : FStar_Parser_AST.term) =
  FStar_Parser_AST.mk_term
    (FStar_Parser_AST.Name FStar_Parser_Const.unit_lid)
    FStar_Range.dummyRange FStar_Parser_AST.Type_level
  
type env_t = FStar_Syntax_DsEnv.env
type lenv_t = FStar_Syntax_Syntax.bv Prims.list
let (desugar_name' :
  (FStar_Syntax_Syntax.term -> FStar_Syntax_Syntax.term) ->
    env_t ->
      Prims.bool ->
        FStar_Ident.lid ->
          FStar_Syntax_Syntax.term FStar_Pervasives_Native.option)
  =
  fun setpos  ->
    fun env  ->
      fun resolve  ->
        fun l  ->
          let tm_attrs_opt =
            if resolve
            then FStar_Syntax_DsEnv.try_lookup_lid_with_attributes env l
            else
              FStar_Syntax_DsEnv.try_lookup_lid_with_attributes_no_resolve
                env l
             in
          match tm_attrs_opt with
          | FStar_Pervasives_Native.None  -> FStar_Pervasives_Native.None
          | FStar_Pervasives_Native.Some (tm,attrs) ->
              let warn_if_deprecated attrs1 =
                FStar_List.iter
                  (fun a  ->
                     match a.FStar_Syntax_Syntax.n with
                     | FStar_Syntax_Syntax.Tm_app
                         ({
                            FStar_Syntax_Syntax.n =
                              FStar_Syntax_Syntax.Tm_fvar fv;
                            FStar_Syntax_Syntax.pos = uu____551;
                            FStar_Syntax_Syntax.vars = uu____552;_},args)
                         when
                         FStar_Ident.lid_equals
                           (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v
                           FStar_Parser_Const.deprecated_attr
                         ->
                         let msg =
                           let uu____580 =
                             FStar_Syntax_Print.term_to_string tm  in
                           Prims.op_Hat uu____580 " is deprecated"  in
                         let msg1 =
                           if (FStar_List.length args) > Prims.int_zero
                           then
                             let uu____596 =
                               let uu____597 =
                                 let uu____600 = FStar_List.hd args  in
                                 FStar_Pervasives_Native.fst uu____600  in
                               uu____597.FStar_Syntax_Syntax.n  in
                             match uu____596 with
                             | FStar_Syntax_Syntax.Tm_constant
                                 (FStar_Const.Const_string (s,uu____623))
                                 when
                                 Prims.op_Negation
                                   ((FStar_Util.trim_string s) = "")
                                 ->
                                 Prims.op_Hat msg
                                   (Prims.op_Hat ", use "
                                      (Prims.op_Hat s " instead"))
                             | uu____630 -> msg
                           else msg  in
                         let uu____633 = FStar_Ident.range_of_lid l  in
                         FStar_Errors.log_issue uu____633
                           (FStar_Errors.Warning_DeprecatedDefinition, msg1)
                     | FStar_Syntax_Syntax.Tm_fvar fv when
                         FStar_Ident.lid_equals
                           (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v
                           FStar_Parser_Const.deprecated_attr
                         ->
                         let msg =
                           let uu____638 =
                             FStar_Syntax_Print.term_to_string tm  in
                           Prims.op_Hat uu____638 " is deprecated"  in
                         let uu____641 = FStar_Ident.range_of_lid l  in
                         FStar_Errors.log_issue uu____641
                           (FStar_Errors.Warning_DeprecatedDefinition, msg)
                     | uu____643 -> ()) attrs1
                 in
              (warn_if_deprecated attrs;
               (let tm1 = setpos tm  in FStar_Pervasives_Native.Some tm1))
  
let desugar_name :
  'Auu____659 .
    'Auu____659 ->
      (FStar_Syntax_Syntax.term -> FStar_Syntax_Syntax.term) ->
        env_t -> Prims.bool -> FStar_Ident.lident -> FStar_Syntax_Syntax.term
  =
  fun mk1  ->
    fun setpos  ->
      fun env  ->
        fun resolve  ->
          fun l  ->
            FStar_Syntax_DsEnv.fail_or env (desugar_name' setpos env resolve)
              l
  
let (compile_op_lid :
  Prims.int -> Prims.string -> FStar_Range.range -> FStar_Ident.lident) =
  fun n1  ->
    fun s  ->
      fun r  ->
        let uu____712 =
          let uu____715 =
            let uu____716 =
              let uu____722 = FStar_Parser_AST.compile_op n1 s r  in
              (uu____722, r)  in
            FStar_Ident.mk_ident uu____716  in
          [uu____715]  in
        FStar_All.pipe_right uu____712 FStar_Ident.lid_of_ids
  
let op_as_term :
  'Auu____738 .
    env_t ->
      Prims.int ->
        'Auu____738 ->
          FStar_Ident.ident ->
            FStar_Syntax_Syntax.term FStar_Pervasives_Native.option
  =
  fun env  ->
    fun arity  ->
      fun rng  ->
        fun op  ->
          let r l dd =
            let uu____776 =
              let uu____777 =
                let uu____778 =
                  FStar_Ident.set_lid_range l op.FStar_Ident.idRange  in
                FStar_Syntax_Syntax.lid_as_fv uu____778 dd
                  FStar_Pervasives_Native.None
                 in
              FStar_All.pipe_right uu____777 FStar_Syntax_Syntax.fv_to_tm  in
            FStar_Pervasives_Native.Some uu____776  in
          let fallback uu____786 =
            let uu____787 = FStar_Ident.text_of_id op  in
            match uu____787 with
            | "=" ->
                r FStar_Parser_Const.op_Eq
                  FStar_Syntax_Syntax.delta_equational
            | ":=" ->
                r FStar_Parser_Const.write_lid
                  FStar_Syntax_Syntax.delta_equational
            | "<" ->
                r FStar_Parser_Const.op_LT
                  FStar_Syntax_Syntax.delta_equational
            | "<=" ->
                r FStar_Parser_Const.op_LTE
                  FStar_Syntax_Syntax.delta_equational
            | ">" ->
                r FStar_Parser_Const.op_GT
                  FStar_Syntax_Syntax.delta_equational
            | ">=" ->
                r FStar_Parser_Const.op_GTE
                  FStar_Syntax_Syntax.delta_equational
            | "&&" ->
                r FStar_Parser_Const.op_And
                  FStar_Syntax_Syntax.delta_equational
            | "||" ->
                r FStar_Parser_Const.op_Or
                  FStar_Syntax_Syntax.delta_equational
            | "+" ->
                r FStar_Parser_Const.op_Addition
                  FStar_Syntax_Syntax.delta_equational
            | "-" when arity = Prims.int_one ->
                r FStar_Parser_Const.op_Minus
                  FStar_Syntax_Syntax.delta_equational
            | "-" ->
                r FStar_Parser_Const.op_Subtraction
                  FStar_Syntax_Syntax.delta_equational
            | "/" ->
                r FStar_Parser_Const.op_Division
                  FStar_Syntax_Syntax.delta_equational
            | "%" ->
                r FStar_Parser_Const.op_Modulus
                  FStar_Syntax_Syntax.delta_equational
            | "!" ->
                r FStar_Parser_Const.read_lid
                  FStar_Syntax_Syntax.delta_equational
            | "@" ->
                let uu____808 = FStar_Options.ml_ish ()  in
                if uu____808
                then
                  r FStar_Parser_Const.list_append_lid
                    (FStar_Syntax_Syntax.Delta_equational_at_level
                       (Prims.of_int (2)))
                else
                  r FStar_Parser_Const.list_tot_append_lid
                    (FStar_Syntax_Syntax.Delta_equational_at_level
                       (Prims.of_int (2)))
            | "|>" ->
                r FStar_Parser_Const.pipe_right_lid
                  FStar_Syntax_Syntax.delta_equational
            | "<|" ->
                r FStar_Parser_Const.pipe_left_lid
                  FStar_Syntax_Syntax.delta_equational
            | "<>" ->
                r FStar_Parser_Const.op_notEq
                  FStar_Syntax_Syntax.delta_equational
            | "~" ->
                r FStar_Parser_Const.not_lid
                  (FStar_Syntax_Syntax.Delta_constant_at_level
                     (Prims.of_int (2)))
            | "==" ->
                r FStar_Parser_Const.eq2_lid
                  (FStar_Syntax_Syntax.Delta_constant_at_level
                     (Prims.of_int (2)))
            | "<<" ->
                r FStar_Parser_Const.precedes_lid
                  FStar_Syntax_Syntax.delta_constant
            | "/\\" ->
                r FStar_Parser_Const.and_lid
                  (FStar_Syntax_Syntax.Delta_constant_at_level Prims.int_one)
            | "\\/" ->
                r FStar_Parser_Const.or_lid
                  (FStar_Syntax_Syntax.Delta_constant_at_level Prims.int_one)
            | "==>" ->
                r FStar_Parser_Const.imp_lid
                  (FStar_Syntax_Syntax.Delta_constant_at_level Prims.int_one)
            | "<==>" ->
                r FStar_Parser_Const.iff_lid
                  (FStar_Syntax_Syntax.Delta_constant_at_level
                     (Prims.of_int (2)))
            | uu____833 -> FStar_Pervasives_Native.None  in
          let uu____835 =
            let uu____838 =
              compile_op_lid arity op.FStar_Ident.idText
                op.FStar_Ident.idRange
               in
            desugar_name'
              (fun t  ->
                 let uu___203_844 = t  in
                 {
                   FStar_Syntax_Syntax.n =
                     (uu___203_844.FStar_Syntax_Syntax.n);
                   FStar_Syntax_Syntax.pos = (op.FStar_Ident.idRange);
                   FStar_Syntax_Syntax.vars =
                     (uu___203_844.FStar_Syntax_Syntax.vars)
                 }) env true uu____838
             in
          match uu____835 with
          | FStar_Pervasives_Native.Some t -> FStar_Pervasives_Native.Some t
          | uu____849 -> fallback ()
  
let (sort_ftv : FStar_Ident.ident Prims.list -> FStar_Ident.ident Prims.list)
  =
  fun ftv  ->
    let uu____864 =
      FStar_Util.remove_dups
        (fun x  -> fun y  -> x.FStar_Ident.idText = y.FStar_Ident.idText) ftv
       in
    FStar_All.pipe_left
      (FStar_Util.sort_with
         (fun x  ->
            fun y  ->
              FStar_String.compare x.FStar_Ident.idText y.FStar_Ident.idText))
      uu____864
  
let rec (free_type_vars_b :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.binder ->
      (FStar_Syntax_DsEnv.env * FStar_Ident.ident Prims.list))
  =
  fun env  ->
    fun binder  ->
      match binder.FStar_Parser_AST.b with
      | FStar_Parser_AST.Variable uu____913 -> (env, [])
      | FStar_Parser_AST.TVariable x ->
          let uu____917 = FStar_Syntax_DsEnv.push_bv env x  in
          (match uu____917 with | (env1,uu____929) -> (env1, [x]))
      | FStar_Parser_AST.Annotated (uu____932,term) ->
          let uu____934 = free_type_vars env term  in (env, uu____934)
      | FStar_Parser_AST.TAnnotated (id1,uu____940) ->
          let uu____941 = FStar_Syntax_DsEnv.push_bv env id1  in
          (match uu____941 with | (env1,uu____953) -> (env1, []))
      | FStar_Parser_AST.NoName t ->
          let uu____957 = free_type_vars env t  in (env, uu____957)

and (free_type_vars :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.term -> FStar_Ident.ident Prims.list)
  =
  fun env  ->
    fun t  ->
      let uu____964 =
        let uu____965 = unparen t  in uu____965.FStar_Parser_AST.tm  in
      match uu____964 with
      | FStar_Parser_AST.Labeled uu____968 ->
          failwith "Impossible --- labeled source term"
      | FStar_Parser_AST.Tvar a ->
          let uu____981 = FStar_Syntax_DsEnv.try_lookup_id env a  in
          (match uu____981 with
           | FStar_Pervasives_Native.None  -> [a]
           | uu____986 -> [])
      | FStar_Parser_AST.Wild  -> []
      | FStar_Parser_AST.Const uu____989 -> []
      | FStar_Parser_AST.Uvar uu____990 -> []
      | FStar_Parser_AST.Var uu____991 -> []
      | FStar_Parser_AST.Projector uu____992 -> []
      | FStar_Parser_AST.Discrim uu____997 -> []
      | FStar_Parser_AST.Name uu____998 -> []
      | FStar_Parser_AST.Requires (t1,uu____1000) -> free_type_vars env t1
      | FStar_Parser_AST.Ensures (t1,uu____1008) -> free_type_vars env t1
      | FStar_Parser_AST.NamedTyp (uu____1015,t1) -> free_type_vars env t1
      | FStar_Parser_AST.Paren t1 -> failwith "impossible"
      | FStar_Parser_AST.Ascribed (t1,t',tacopt) ->
          let ts = t1 :: t' ::
            (match tacopt with
             | FStar_Pervasives_Native.None  -> []
             | FStar_Pervasives_Native.Some t2 -> [t2])
             in
          FStar_List.collect (free_type_vars env) ts
      | FStar_Parser_AST.Construct (uu____1034,ts) ->
          FStar_List.collect
            (fun uu____1055  ->
               match uu____1055 with
               | (t1,uu____1063) -> free_type_vars env t1) ts
      | FStar_Parser_AST.Op (uu____1064,ts) ->
          FStar_List.collect (free_type_vars env) ts
      | FStar_Parser_AST.App (t1,t2,uu____1072) ->
          let uu____1073 = free_type_vars env t1  in
          let uu____1076 = free_type_vars env t2  in
          FStar_List.append uu____1073 uu____1076
      | FStar_Parser_AST.Refine (b,t1) ->
          let uu____1081 = free_type_vars_b env b  in
          (match uu____1081 with
           | (env1,f) ->
               let uu____1096 = free_type_vars env1 t1  in
               FStar_List.append f uu____1096)
      | FStar_Parser_AST.Sum (binders,body) ->
          let uu____1113 =
            FStar_List.fold_left
              (fun uu____1137  ->
                 fun bt  ->
                   match uu____1137 with
                   | (env1,free) ->
                       let uu____1161 =
                         match bt with
                         | FStar_Util.Inl binder ->
                             free_type_vars_b env1 binder
                         | FStar_Util.Inr t1 ->
                             let uu____1176 = free_type_vars env1 body  in
                             (env1, uu____1176)
                          in
                       (match uu____1161 with
                        | (env2,f) -> (env2, (FStar_List.append f free))))
              (env, []) binders
             in
          (match uu____1113 with
           | (env1,free) ->
               let uu____1205 = free_type_vars env1 body  in
               FStar_List.append free uu____1205)
      | FStar_Parser_AST.Product (binders,body) ->
          let uu____1214 =
            FStar_List.fold_left
              (fun uu____1234  ->
                 fun binder  ->
                   match uu____1234 with
                   | (env1,free) ->
                       let uu____1254 = free_type_vars_b env1 binder  in
                       (match uu____1254 with
                        | (env2,f) -> (env2, (FStar_List.append f free))))
              (env, []) binders
             in
          (match uu____1214 with
           | (env1,free) ->
               let uu____1285 = free_type_vars env1 body  in
               FStar_List.append free uu____1285)
      | FStar_Parser_AST.Project (t1,uu____1289) -> free_type_vars env t1
      | FStar_Parser_AST.Attributes cattributes ->
          FStar_List.collect (free_type_vars env) cattributes
      | FStar_Parser_AST.CalcProof (rel,init1,steps) ->
          let uu____1300 = free_type_vars env rel  in
          let uu____1303 =
            let uu____1306 = free_type_vars env init1  in
            let uu____1309 =
              FStar_List.collect
                (fun uu____1318  ->
                   match uu____1318 with
                   | FStar_Parser_AST.CalcStep (rel1,just,next) ->
                       let uu____1324 = free_type_vars env rel1  in
                       let uu____1327 =
                         let uu____1330 = free_type_vars env just  in
                         let uu____1333 = free_type_vars env next  in
                         FStar_List.append uu____1330 uu____1333  in
                       FStar_List.append uu____1324 uu____1327) steps
               in
            FStar_List.append uu____1306 uu____1309  in
          FStar_List.append uu____1300 uu____1303
      | FStar_Parser_AST.Abs uu____1336 -> []
      | FStar_Parser_AST.Let uu____1343 -> []
      | FStar_Parser_AST.LetOpen uu____1364 -> []
      | FStar_Parser_AST.If uu____1369 -> []
      | FStar_Parser_AST.QForall uu____1376 -> []
      | FStar_Parser_AST.QExists uu____1395 -> []
      | FStar_Parser_AST.Record uu____1414 -> []
      | FStar_Parser_AST.Match uu____1427 -> []
      | FStar_Parser_AST.TryWith uu____1442 -> []
      | FStar_Parser_AST.Bind uu____1457 -> []
      | FStar_Parser_AST.Quote uu____1464 -> []
      | FStar_Parser_AST.VQuote uu____1469 -> []
      | FStar_Parser_AST.Antiquote uu____1470 -> []
      | FStar_Parser_AST.Seq uu____1471 -> []

let (head_and_args :
  FStar_Parser_AST.term ->
    (FStar_Parser_AST.term * (FStar_Parser_AST.term * FStar_Parser_AST.imp)
      Prims.list))
  =
  fun t  ->
    let rec aux args t1 =
      let uu____1525 =
        let uu____1526 = unparen t1  in uu____1526.FStar_Parser_AST.tm  in
      match uu____1525 with
      | FStar_Parser_AST.App (t2,arg,imp) -> aux ((arg, imp) :: args) t2
      | FStar_Parser_AST.Construct (l,args') ->
          ({
             FStar_Parser_AST.tm = (FStar_Parser_AST.Name l);
             FStar_Parser_AST.range = (t1.FStar_Parser_AST.range);
             FStar_Parser_AST.level = (t1.FStar_Parser_AST.level)
           }, (FStar_List.append args' args))
      | uu____1568 -> (t1, args)  in
    aux [] t
  
let (close :
  FStar_Syntax_DsEnv.env -> FStar_Parser_AST.term -> FStar_Parser_AST.term) =
  fun env  ->
    fun t  ->
      let ftv =
        let uu____1593 = free_type_vars env t  in
        FStar_All.pipe_left sort_ftv uu____1593  in
      if (FStar_List.length ftv) = Prims.int_zero
      then t
      else
        (let binders =
           FStar_All.pipe_right ftv
             (FStar_List.map
                (fun x  ->
                   let uu____1615 =
                     let uu____1616 =
                       let uu____1621 = tm_type x.FStar_Ident.idRange  in
                       (x, uu____1621)  in
                     FStar_Parser_AST.TAnnotated uu____1616  in
                   FStar_Parser_AST.mk_binder uu____1615
                     x.FStar_Ident.idRange FStar_Parser_AST.Type_level
                     (FStar_Pervasives_Native.Some FStar_Parser_AST.Implicit)))
            in
         let result =
           FStar_Parser_AST.mk_term (FStar_Parser_AST.Product (binders, t))
             t.FStar_Parser_AST.range t.FStar_Parser_AST.level
            in
         result)
  
let (close_fun :
  FStar_Syntax_DsEnv.env -> FStar_Parser_AST.term -> FStar_Parser_AST.term) =
  fun env  ->
    fun t  ->
      let ftv =
        let uu____1639 = free_type_vars env t  in
        FStar_All.pipe_left sort_ftv uu____1639  in
      if (FStar_List.length ftv) = Prims.int_zero
      then t
      else
        (let binders =
           FStar_All.pipe_right ftv
             (FStar_List.map
                (fun x  ->
                   let uu____1661 =
                     let uu____1662 =
                       let uu____1667 = tm_type x.FStar_Ident.idRange  in
                       (x, uu____1667)  in
                     FStar_Parser_AST.TAnnotated uu____1662  in
                   FStar_Parser_AST.mk_binder uu____1661
                     x.FStar_Ident.idRange FStar_Parser_AST.Type_level
                     (FStar_Pervasives_Native.Some FStar_Parser_AST.Implicit)))
            in
         let t1 =
           let uu____1669 =
             let uu____1670 = unparen t  in uu____1670.FStar_Parser_AST.tm
              in
           match uu____1669 with
           | FStar_Parser_AST.Product uu____1671 -> t
           | uu____1678 ->
               FStar_Parser_AST.mk_term
                 (FStar_Parser_AST.App
                    ((FStar_Parser_AST.mk_term
                        (FStar_Parser_AST.Name
                           FStar_Parser_Const.effect_Tot_lid)
                        t.FStar_Parser_AST.range t.FStar_Parser_AST.level),
                      t, FStar_Parser_AST.Nothing)) t.FStar_Parser_AST.range
                 t.FStar_Parser_AST.level
            in
         let result =
           FStar_Parser_AST.mk_term (FStar_Parser_AST.Product (binders, t1))
             t1.FStar_Parser_AST.range t1.FStar_Parser_AST.level
            in
         result)
  
let rec (uncurry :
  FStar_Parser_AST.binder Prims.list ->
    FStar_Parser_AST.term ->
      (FStar_Parser_AST.binder Prims.list * FStar_Parser_AST.term))
  =
  fun bs  ->
    fun t  ->
      match t.FStar_Parser_AST.tm with
      | FStar_Parser_AST.Product (binders,t1) ->
          uncurry (FStar_List.append bs binders) t1
      | uu____1715 -> (bs, t)
  
let rec (is_var_pattern : FStar_Parser_AST.pattern -> Prims.bool) =
  fun p  ->
    match p.FStar_Parser_AST.pat with
    | FStar_Parser_AST.PatWild uu____1726 -> true
    | FStar_Parser_AST.PatTvar (uu____1730,uu____1731) -> true
    | FStar_Parser_AST.PatVar (uu____1737,uu____1738) -> true
    | FStar_Parser_AST.PatAscribed (p1,uu____1745) -> is_var_pattern p1
    | uu____1758 -> false
  
let rec (is_app_pattern : FStar_Parser_AST.pattern -> Prims.bool) =
  fun p  ->
    match p.FStar_Parser_AST.pat with
    | FStar_Parser_AST.PatAscribed (p1,uu____1769) -> is_app_pattern p1
    | FStar_Parser_AST.PatApp
        ({ FStar_Parser_AST.pat = FStar_Parser_AST.PatVar uu____1782;
           FStar_Parser_AST.prange = uu____1783;_},uu____1784)
        -> true
    | uu____1796 -> false
  
let (replace_unit_pattern :
  FStar_Parser_AST.pattern -> FStar_Parser_AST.pattern) =
  fun p  ->
    match p.FStar_Parser_AST.pat with
    | FStar_Parser_AST.PatConst (FStar_Const.Const_unit ) ->
        FStar_Parser_AST.mk_pattern
          (FStar_Parser_AST.PatAscribed
             ((FStar_Parser_AST.mk_pattern
                 (FStar_Parser_AST.PatWild FStar_Pervasives_Native.None)
                 p.FStar_Parser_AST.prange),
               (unit_ty, FStar_Pervasives_Native.None)))
          p.FStar_Parser_AST.prange
    | uu____1812 -> p
  
let rec (destruct_app_pattern :
  FStar_Syntax_DsEnv.env ->
    Prims.bool ->
      FStar_Parser_AST.pattern ->
        ((FStar_Ident.ident,FStar_Ident.lident) FStar_Util.either *
          FStar_Parser_AST.pattern Prims.list * (FStar_Parser_AST.term *
          FStar_Parser_AST.term FStar_Pervasives_Native.option)
          FStar_Pervasives_Native.option))
  =
  fun env  ->
    fun is_top_level1  ->
      fun p  ->
        match p.FStar_Parser_AST.pat with
        | FStar_Parser_AST.PatAscribed (p1,t) ->
            let uu____1885 = destruct_app_pattern env is_top_level1 p1  in
            (match uu____1885 with
             | (name,args,uu____1928) ->
                 (name, args, (FStar_Pervasives_Native.Some t)))
        | FStar_Parser_AST.PatApp
            ({
               FStar_Parser_AST.pat = FStar_Parser_AST.PatVar
                 (id1,uu____1978);
               FStar_Parser_AST.prange = uu____1979;_},args)
            when is_top_level1 ->
            let uu____1989 =
              let uu____1994 = FStar_Syntax_DsEnv.qualify env id1  in
              FStar_Util.Inr uu____1994  in
            (uu____1989, args, FStar_Pervasives_Native.None)
        | FStar_Parser_AST.PatApp
            ({
               FStar_Parser_AST.pat = FStar_Parser_AST.PatVar
                 (id1,uu____2016);
               FStar_Parser_AST.prange = uu____2017;_},args)
            -> ((FStar_Util.Inl id1), args, FStar_Pervasives_Native.None)
        | uu____2047 -> failwith "Not an app pattern"
  
let rec (gather_pattern_bound_vars_maybe_top :
  Prims.bool ->
    FStar_Ident.ident FStar_Util.set ->
      FStar_Parser_AST.pattern -> FStar_Ident.ident FStar_Util.set)
  =
  fun fail_on_patconst  ->
    fun acc  ->
      fun p  ->
        let gather_pattern_bound_vars_from_list =
          FStar_List.fold_left
            (gather_pattern_bound_vars_maybe_top fail_on_patconst) acc
           in
        match p.FStar_Parser_AST.pat with
        | FStar_Parser_AST.PatWild uu____2106 -> acc
        | FStar_Parser_AST.PatName uu____2109 -> acc
        | FStar_Parser_AST.PatOp uu____2110 -> acc
        | FStar_Parser_AST.PatConst uu____2111 ->
            if fail_on_patconst
            then
              FStar_Errors.raise_error
                (FStar_Errors.Error_CannotRedefineConst,
                  "Constants cannot be redefined") p.FStar_Parser_AST.prange
            else acc
        | FStar_Parser_AST.PatApp (phead,pats) ->
            gather_pattern_bound_vars_from_list (phead :: pats)
        | FStar_Parser_AST.PatTvar (x,uu____2128) -> FStar_Util.set_add x acc
        | FStar_Parser_AST.PatVar (x,uu____2134) -> FStar_Util.set_add x acc
        | FStar_Parser_AST.PatList pats ->
            gather_pattern_bound_vars_from_list pats
        | FStar_Parser_AST.PatTuple (pats,uu____2143) ->
            gather_pattern_bound_vars_from_list pats
        | FStar_Parser_AST.PatOr pats ->
            gather_pattern_bound_vars_from_list pats
        | FStar_Parser_AST.PatRecord guarded_pats ->
            let uu____2160 =
              FStar_List.map FStar_Pervasives_Native.snd guarded_pats  in
            gather_pattern_bound_vars_from_list uu____2160
        | FStar_Parser_AST.PatAscribed (pat,uu____2168) ->
            gather_pattern_bound_vars_maybe_top fail_on_patconst acc pat
  
let (gather_pattern_bound_vars :
  Prims.bool -> FStar_Parser_AST.pattern -> FStar_Ident.ident FStar_Util.set)
  =
  fun fail_on_patconst  ->
    fun p  ->
      let acc =
        FStar_Util.new_set
          (fun id1  ->
             fun id2  ->
               if id1.FStar_Ident.idText = id2.FStar_Ident.idText
               then Prims.int_zero
               else Prims.int_one)
         in
      gather_pattern_bound_vars_maybe_top fail_on_patconst acc p
  
type bnd =
  | LocalBinder of (FStar_Syntax_Syntax.bv * FStar_Syntax_Syntax.aqual) 
  | LetBinder of (FStar_Ident.lident * (FStar_Syntax_Syntax.term *
  FStar_Syntax_Syntax.term FStar_Pervasives_Native.option)) 
let (uu___is_LocalBinder : bnd -> Prims.bool) =
  fun projectee  ->
    match projectee with | LocalBinder _0 -> true | uu____2250 -> false
  
let (__proj__LocalBinder__item___0 :
  bnd -> (FStar_Syntax_Syntax.bv * FStar_Syntax_Syntax.aqual)) =
  fun projectee  -> match projectee with | LocalBinder _0 -> _0 
let (uu___is_LetBinder : bnd -> Prims.bool) =
  fun projectee  ->
    match projectee with | LetBinder _0 -> true | uu____2291 -> false
  
let (__proj__LetBinder__item___0 :
  bnd ->
    (FStar_Ident.lident * (FStar_Syntax_Syntax.term *
      FStar_Syntax_Syntax.term FStar_Pervasives_Native.option)))
  = fun projectee  -> match projectee with | LetBinder _0 -> _0 
let (binder_of_bnd :
  bnd -> (FStar_Syntax_Syntax.bv * FStar_Syntax_Syntax.aqual)) =
  fun uu___3_2339  ->
    match uu___3_2339 with
    | LocalBinder (a,aq) -> (a, aq)
    | uu____2346 -> failwith "Impossible"
  
let (mk_lb :
  (FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax Prims.list *
    (FStar_Syntax_Syntax.bv,FStar_Syntax_Syntax.fv) FStar_Util.either *
    FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax *
    FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax * FStar_Range.range)
    -> FStar_Syntax_Syntax.letbinding)
  =
  fun uu____2379  ->
    match uu____2379 with
    | (attrs,n1,t,e,pos) ->
        {
          FStar_Syntax_Syntax.lbname = n1;
          FStar_Syntax_Syntax.lbunivs = [];
          FStar_Syntax_Syntax.lbtyp = t;
          FStar_Syntax_Syntax.lbeff = FStar_Parser_Const.effect_ALL_lid;
          FStar_Syntax_Syntax.lbdef = e;
          FStar_Syntax_Syntax.lbattrs = attrs;
          FStar_Syntax_Syntax.lbpos = pos
        }
  
let (no_annot_abs :
  FStar_Syntax_Syntax.binders ->
    FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax ->
      FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax)
  =
  fun bs  ->
    fun t  -> FStar_Syntax_Util.abs bs t FStar_Pervasives_Native.None
  
let (mk_ref_read :
  FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax ->
    FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax)
  =
  fun tm  ->
    let tm' =
      let uu____2461 =
        let uu____2478 =
          let uu____2481 =
            FStar_Syntax_Syntax.lid_as_fv FStar_Parser_Const.sread_lid
              FStar_Syntax_Syntax.delta_constant FStar_Pervasives_Native.None
             in
          FStar_Syntax_Syntax.fv_to_tm uu____2481  in
        let uu____2482 =
          let uu____2493 =
            let uu____2502 = FStar_Syntax_Syntax.as_implicit false  in
            (tm, uu____2502)  in
          [uu____2493]  in
        (uu____2478, uu____2482)  in
      FStar_Syntax_Syntax.Tm_app uu____2461  in
    FStar_Syntax_Syntax.mk tm' FStar_Pervasives_Native.None
      tm.FStar_Syntax_Syntax.pos
  
let (mk_ref_alloc :
  FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax ->
    FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax)
  =
  fun tm  ->
    let tm' =
      let uu____2551 =
        let uu____2568 =
          let uu____2571 =
            FStar_Syntax_Syntax.lid_as_fv FStar_Parser_Const.salloc_lid
              FStar_Syntax_Syntax.delta_constant FStar_Pervasives_Native.None
             in
          FStar_Syntax_Syntax.fv_to_tm uu____2571  in
        let uu____2572 =
          let uu____2583 =
            let uu____2592 = FStar_Syntax_Syntax.as_implicit false  in
            (tm, uu____2592)  in
          [uu____2583]  in
        (uu____2568, uu____2572)  in
      FStar_Syntax_Syntax.Tm_app uu____2551  in
    FStar_Syntax_Syntax.mk tm' FStar_Pervasives_Native.None
      tm.FStar_Syntax_Syntax.pos
  
let (mk_ref_assign :
  FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax ->
    FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax ->
      FStar_Range.range ->
        FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax)
  =
  fun t1  ->
    fun t2  ->
      fun pos  ->
        let tm =
          let uu____2655 =
            let uu____2672 =
              let uu____2675 =
                FStar_Syntax_Syntax.lid_as_fv FStar_Parser_Const.swrite_lid
                  FStar_Syntax_Syntax.delta_constant
                  FStar_Pervasives_Native.None
                 in
              FStar_Syntax_Syntax.fv_to_tm uu____2675  in
            let uu____2676 =
              let uu____2687 =
                let uu____2696 = FStar_Syntax_Syntax.as_implicit false  in
                (t1, uu____2696)  in
              let uu____2704 =
                let uu____2715 =
                  let uu____2724 = FStar_Syntax_Syntax.as_implicit false  in
                  (t2, uu____2724)  in
                [uu____2715]  in
              uu____2687 :: uu____2704  in
            (uu____2672, uu____2676)  in
          FStar_Syntax_Syntax.Tm_app uu____2655  in
        FStar_Syntax_Syntax.mk tm FStar_Pervasives_Native.None pos
  
let (generalize_annotated_univs :
  FStar_Syntax_Syntax.sigelt -> FStar_Syntax_Syntax.sigelt) =
  fun s  ->
    let bs_univnames bs =
      let uu____2784 =
        let uu____2799 =
          FStar_Util.new_set FStar_Syntax_Syntax.order_univ_name  in
        FStar_List.fold_left
          (fun uvs  ->
             fun uu____2818  ->
               match uu____2818 with
               | ({ FStar_Syntax_Syntax.ppname = uu____2829;
                    FStar_Syntax_Syntax.index = uu____2830;
                    FStar_Syntax_Syntax.sort = t;_},uu____2832)
                   ->
                   let uu____2840 = FStar_Syntax_Free.univnames t  in
                   FStar_Util.set_union uvs uu____2840) uu____2799
         in
      FStar_All.pipe_right bs uu____2784  in
    let empty_set = FStar_Util.new_set FStar_Syntax_Syntax.order_univ_name
       in
    match s.FStar_Syntax_Syntax.sigel with
    | FStar_Syntax_Syntax.Sig_inductive_typ uu____2856 ->
        failwith
          "Impossible: collect_annotated_universes: bare data/type constructor"
    | FStar_Syntax_Syntax.Sig_datacon uu____2874 ->
        failwith
          "Impossible: collect_annotated_universes: bare data/type constructor"
    | FStar_Syntax_Syntax.Sig_bundle (sigs,lids) ->
        let uvs =
          let uu____2902 =
            FStar_All.pipe_right sigs
              (FStar_List.fold_left
                 (fun uvs  ->
                    fun se  ->
                      let se_univs =
                        match se.FStar_Syntax_Syntax.sigel with
                        | FStar_Syntax_Syntax.Sig_inductive_typ
                            (uu____2923,uu____2924,bs,t,uu____2927,uu____2928)
                            ->
                            let uu____2937 = bs_univnames bs  in
                            let uu____2940 = FStar_Syntax_Free.univnames t
                               in
                            FStar_Util.set_union uu____2937 uu____2940
                        | FStar_Syntax_Syntax.Sig_datacon
                            (uu____2943,uu____2944,t,uu____2946,uu____2947,uu____2948)
                            -> FStar_Syntax_Free.univnames t
                        | uu____2955 ->
                            failwith
                              "Impossible: collect_annotated_universes: Sig_bundle should not have a non data/type sigelt"
                         in
                      FStar_Util.set_union uvs se_univs) empty_set)
             in
          FStar_All.pipe_right uu____2902 FStar_Util.set_elements  in
        let usubst = FStar_Syntax_Subst.univ_var_closing uvs  in
        let uu___585_2964 = s  in
        let uu____2965 =
          let uu____2966 =
            let uu____2975 =
              FStar_All.pipe_right sigs
                (FStar_List.map
                   (fun se  ->
                      match se.FStar_Syntax_Syntax.sigel with
                      | FStar_Syntax_Syntax.Sig_inductive_typ
                          (lid,uu____2993,bs,t,lids1,lids2) ->
                          let uu___596_3006 = se  in
                          let uu____3007 =
                            let uu____3008 =
                              let uu____3025 =
                                FStar_Syntax_Subst.subst_binders usubst bs
                                 in
                              let uu____3026 =
                                let uu____3027 =
                                  FStar_Syntax_Subst.shift_subst
                                    (FStar_List.length bs) usubst
                                   in
                                FStar_Syntax_Subst.subst uu____3027 t  in
                              (lid, uvs, uu____3025, uu____3026, lids1,
                                lids2)
                               in
                            FStar_Syntax_Syntax.Sig_inductive_typ uu____3008
                             in
                          {
                            FStar_Syntax_Syntax.sigel = uu____3007;
                            FStar_Syntax_Syntax.sigrng =
                              (uu___596_3006.FStar_Syntax_Syntax.sigrng);
                            FStar_Syntax_Syntax.sigquals =
                              (uu___596_3006.FStar_Syntax_Syntax.sigquals);
                            FStar_Syntax_Syntax.sigmeta =
                              (uu___596_3006.FStar_Syntax_Syntax.sigmeta);
                            FStar_Syntax_Syntax.sigattrs =
                              (uu___596_3006.FStar_Syntax_Syntax.sigattrs);
                            FStar_Syntax_Syntax.sigopts =
                              (uu___596_3006.FStar_Syntax_Syntax.sigopts)
                          }
                      | FStar_Syntax_Syntax.Sig_datacon
                          (lid,uu____3041,t,tlid,n1,lids1) ->
                          let uu___606_3052 = se  in
                          let uu____3053 =
                            let uu____3054 =
                              let uu____3070 =
                                FStar_Syntax_Subst.subst usubst t  in
                              (lid, uvs, uu____3070, tlid, n1, lids1)  in
                            FStar_Syntax_Syntax.Sig_datacon uu____3054  in
                          {
                            FStar_Syntax_Syntax.sigel = uu____3053;
                            FStar_Syntax_Syntax.sigrng =
                              (uu___606_3052.FStar_Syntax_Syntax.sigrng);
                            FStar_Syntax_Syntax.sigquals =
                              (uu___606_3052.FStar_Syntax_Syntax.sigquals);
                            FStar_Syntax_Syntax.sigmeta =
                              (uu___606_3052.FStar_Syntax_Syntax.sigmeta);
                            FStar_Syntax_Syntax.sigattrs =
                              (uu___606_3052.FStar_Syntax_Syntax.sigattrs);
                            FStar_Syntax_Syntax.sigopts =
                              (uu___606_3052.FStar_Syntax_Syntax.sigopts)
                          }
                      | uu____3074 ->
                          failwith
                            "Impossible: collect_annotated_universes: Sig_bundle should not have a non data/type sigelt"))
               in
            (uu____2975, lids)  in
          FStar_Syntax_Syntax.Sig_bundle uu____2966  in
        {
          FStar_Syntax_Syntax.sigel = uu____2965;
          FStar_Syntax_Syntax.sigrng =
            (uu___585_2964.FStar_Syntax_Syntax.sigrng);
          FStar_Syntax_Syntax.sigquals =
            (uu___585_2964.FStar_Syntax_Syntax.sigquals);
          FStar_Syntax_Syntax.sigmeta =
            (uu___585_2964.FStar_Syntax_Syntax.sigmeta);
          FStar_Syntax_Syntax.sigattrs =
            (uu___585_2964.FStar_Syntax_Syntax.sigattrs);
          FStar_Syntax_Syntax.sigopts =
            (uu___585_2964.FStar_Syntax_Syntax.sigopts)
        }
    | FStar_Syntax_Syntax.Sig_declare_typ (lid,uu____3081,t) ->
        let uvs =
          let uu____3084 = FStar_Syntax_Free.univnames t  in
          FStar_All.pipe_right uu____3084 FStar_Util.set_elements  in
        let uu___615_3089 = s  in
        let uu____3090 =
          let uu____3091 =
            let uu____3098 = FStar_Syntax_Subst.close_univ_vars uvs t  in
            (lid, uvs, uu____3098)  in
          FStar_Syntax_Syntax.Sig_declare_typ uu____3091  in
        {
          FStar_Syntax_Syntax.sigel = uu____3090;
          FStar_Syntax_Syntax.sigrng =
            (uu___615_3089.FStar_Syntax_Syntax.sigrng);
          FStar_Syntax_Syntax.sigquals =
            (uu___615_3089.FStar_Syntax_Syntax.sigquals);
          FStar_Syntax_Syntax.sigmeta =
            (uu___615_3089.FStar_Syntax_Syntax.sigmeta);
          FStar_Syntax_Syntax.sigattrs =
            (uu___615_3089.FStar_Syntax_Syntax.sigattrs);
          FStar_Syntax_Syntax.sigopts =
            (uu___615_3089.FStar_Syntax_Syntax.sigopts)
        }
    | FStar_Syntax_Syntax.Sig_let ((b,lbs),lids) ->
        let lb_univnames lb =
          let uu____3122 =
            FStar_Syntax_Free.univnames lb.FStar_Syntax_Syntax.lbtyp  in
          let uu____3125 =
            match (lb.FStar_Syntax_Syntax.lbdef).FStar_Syntax_Syntax.n with
            | FStar_Syntax_Syntax.Tm_abs (bs,e,uu____3132) ->
                let uvs1 = bs_univnames bs  in
                let uvs2 =
                  match e.FStar_Syntax_Syntax.n with
                  | FStar_Syntax_Syntax.Tm_ascribed
                      (uu____3165,(FStar_Util.Inl t,uu____3167),uu____3168)
                      -> FStar_Syntax_Free.univnames t
                  | FStar_Syntax_Syntax.Tm_ascribed
                      (uu____3215,(FStar_Util.Inr c,uu____3217),uu____3218)
                      -> FStar_Syntax_Free.univnames_comp c
                  | uu____3265 -> empty_set  in
                FStar_Util.set_union uvs1 uvs2
            | FStar_Syntax_Syntax.Tm_arrow (bs,uu____3267) -> bs_univnames bs
            | FStar_Syntax_Syntax.Tm_ascribed
                (uu____3288,(FStar_Util.Inl t,uu____3290),uu____3291) ->
                FStar_Syntax_Free.univnames t
            | FStar_Syntax_Syntax.Tm_ascribed
                (uu____3338,(FStar_Util.Inr c,uu____3340),uu____3341) ->
                FStar_Syntax_Free.univnames_comp c
            | uu____3388 -> empty_set  in
          FStar_Util.set_union uu____3122 uu____3125  in
        let all_lb_univs =
          let uu____3392 =
            FStar_All.pipe_right lbs
              (FStar_List.fold_left
                 (fun uvs  ->
                    fun lb  ->
                      let uu____3408 = lb_univnames lb  in
                      FStar_Util.set_union uvs uu____3408) empty_set)
             in
          FStar_All.pipe_right uu____3392 FStar_Util.set_elements  in
        let usubst = FStar_Syntax_Subst.univ_var_closing all_lb_univs  in
        let uu___674_3418 = s  in
        let uu____3419 =
          let uu____3420 =
            let uu____3427 =
              let uu____3428 =
                FStar_All.pipe_right lbs
                  (FStar_List.map
                     (fun lb  ->
                        let uu___677_3440 = lb  in
                        let uu____3441 =
                          FStar_Syntax_Subst.subst usubst
                            lb.FStar_Syntax_Syntax.lbtyp
                           in
                        let uu____3444 =
                          FStar_Syntax_Subst.subst usubst
                            lb.FStar_Syntax_Syntax.lbdef
                           in
                        {
                          FStar_Syntax_Syntax.lbname =
                            (uu___677_3440.FStar_Syntax_Syntax.lbname);
                          FStar_Syntax_Syntax.lbunivs = all_lb_univs;
                          FStar_Syntax_Syntax.lbtyp = uu____3441;
                          FStar_Syntax_Syntax.lbeff =
                            (uu___677_3440.FStar_Syntax_Syntax.lbeff);
                          FStar_Syntax_Syntax.lbdef = uu____3444;
                          FStar_Syntax_Syntax.lbattrs =
                            (uu___677_3440.FStar_Syntax_Syntax.lbattrs);
                          FStar_Syntax_Syntax.lbpos =
                            (uu___677_3440.FStar_Syntax_Syntax.lbpos)
                        }))
                 in
              (b, uu____3428)  in
            (uu____3427, lids)  in
          FStar_Syntax_Syntax.Sig_let uu____3420  in
        {
          FStar_Syntax_Syntax.sigel = uu____3419;
          FStar_Syntax_Syntax.sigrng =
            (uu___674_3418.FStar_Syntax_Syntax.sigrng);
          FStar_Syntax_Syntax.sigquals =
            (uu___674_3418.FStar_Syntax_Syntax.sigquals);
          FStar_Syntax_Syntax.sigmeta =
            (uu___674_3418.FStar_Syntax_Syntax.sigmeta);
          FStar_Syntax_Syntax.sigattrs =
            (uu___674_3418.FStar_Syntax_Syntax.sigattrs);
          FStar_Syntax_Syntax.sigopts =
            (uu___674_3418.FStar_Syntax_Syntax.sigopts)
        }
    | FStar_Syntax_Syntax.Sig_assume (lid,uu____3453,fml) ->
        let uvs =
          let uu____3456 = FStar_Syntax_Free.univnames fml  in
          FStar_All.pipe_right uu____3456 FStar_Util.set_elements  in
        let uu___685_3461 = s  in
        let uu____3462 =
          let uu____3463 =
            let uu____3470 = FStar_Syntax_Subst.close_univ_vars uvs fml  in
            (lid, uvs, uu____3470)  in
          FStar_Syntax_Syntax.Sig_assume uu____3463  in
        {
          FStar_Syntax_Syntax.sigel = uu____3462;
          FStar_Syntax_Syntax.sigrng =
            (uu___685_3461.FStar_Syntax_Syntax.sigrng);
          FStar_Syntax_Syntax.sigquals =
            (uu___685_3461.FStar_Syntax_Syntax.sigquals);
          FStar_Syntax_Syntax.sigmeta =
            (uu___685_3461.FStar_Syntax_Syntax.sigmeta);
          FStar_Syntax_Syntax.sigattrs =
            (uu___685_3461.FStar_Syntax_Syntax.sigattrs);
          FStar_Syntax_Syntax.sigopts =
            (uu___685_3461.FStar_Syntax_Syntax.sigopts)
        }
    | FStar_Syntax_Syntax.Sig_effect_abbrev (lid,uu____3472,bs,c,flags) ->
        let uvs =
          let uu____3481 =
            let uu____3484 = bs_univnames bs  in
            let uu____3487 = FStar_Syntax_Free.univnames_comp c  in
            FStar_Util.set_union uu____3484 uu____3487  in
          FStar_All.pipe_right uu____3481 FStar_Util.set_elements  in
        let usubst = FStar_Syntax_Subst.univ_var_closing uvs  in
        let uu___696_3495 = s  in
        let uu____3496 =
          let uu____3497 =
            let uu____3510 = FStar_Syntax_Subst.subst_binders usubst bs  in
            let uu____3511 = FStar_Syntax_Subst.subst_comp usubst c  in
            (lid, uvs, uu____3510, uu____3511, flags)  in
          FStar_Syntax_Syntax.Sig_effect_abbrev uu____3497  in
        {
          FStar_Syntax_Syntax.sigel = uu____3496;
          FStar_Syntax_Syntax.sigrng =
            (uu___696_3495.FStar_Syntax_Syntax.sigrng);
          FStar_Syntax_Syntax.sigquals =
            (uu___696_3495.FStar_Syntax_Syntax.sigquals);
          FStar_Syntax_Syntax.sigmeta =
            (uu___696_3495.FStar_Syntax_Syntax.sigmeta);
          FStar_Syntax_Syntax.sigattrs =
            (uu___696_3495.FStar_Syntax_Syntax.sigattrs);
          FStar_Syntax_Syntax.sigopts =
            (uu___696_3495.FStar_Syntax_Syntax.sigopts)
        }
    | uu____3514 -> s
  
let (is_special_effect_combinator : Prims.string -> Prims.bool) =
  fun uu___4_3522  ->
    match uu___4_3522 with
    | "lift1" -> true
    | "lift2" -> true
    | "pure" -> true
    | "app" -> true
    | "push" -> true
    | "wp_if_then_else" -> true
    | "wp_assert" -> true
    | "wp_assume" -> true
    | "wp_close" -> true
    | "stronger" -> true
    | "ite_wp" -> true
    | "wp_trivial" -> true
    | "ctx" -> true
    | "gctx" -> true
    | "lift_from_pure" -> true
    | "return_wp" -> true
    | "return_elab" -> true
    | "bind_wp" -> true
    | "bind_elab" -> true
    | "repr" -> true
    | "post" -> true
    | "pre" -> true
    | "wp" -> true
    | uu____3571 -> false
  
let rec (sum_to_universe :
  FStar_Syntax_Syntax.universe -> Prims.int -> FStar_Syntax_Syntax.universe)
  =
  fun u  ->
    fun n1  ->
      if n1 = Prims.int_zero
      then u
      else
        (let uu____3592 = sum_to_universe u (n1 - Prims.int_one)  in
         FStar_Syntax_Syntax.U_succ uu____3592)
  
let (int_to_universe : Prims.int -> FStar_Syntax_Syntax.universe) =
  fun n1  -> sum_to_universe FStar_Syntax_Syntax.U_zero n1 
let rec (desugar_maybe_non_constant_universe :
  FStar_Parser_AST.term ->
    (Prims.int,FStar_Syntax_Syntax.universe) FStar_Util.either)
  =
  fun t  ->
    let uu____3618 =
      let uu____3619 = unparen t  in uu____3619.FStar_Parser_AST.tm  in
    match uu____3618 with
    | FStar_Parser_AST.Wild  ->
        let uu____3625 =
          let uu____3626 = FStar_Syntax_Unionfind.univ_fresh ()  in
          FStar_Syntax_Syntax.U_unif uu____3626  in
        FStar_Util.Inr uu____3625
    | FStar_Parser_AST.Uvar u ->
        FStar_Util.Inr (FStar_Syntax_Syntax.U_name u)
    | FStar_Parser_AST.Const (FStar_Const.Const_int (repr,uu____3639)) ->
        let n1 = FStar_Util.int_of_string repr  in
        (if n1 < Prims.int_zero
         then
           FStar_Errors.raise_error
             (FStar_Errors.Fatal_NegativeUniverseConstFatal_NotSupported,
               (Prims.op_Hat
                  "Negative universe constant  are not supported : " repr))
             t.FStar_Parser_AST.range
         else ();
         FStar_Util.Inl n1)
    | FStar_Parser_AST.Op (op_plus,t1::t2::[]) ->
        let u1 = desugar_maybe_non_constant_universe t1  in
        let u2 = desugar_maybe_non_constant_universe t2  in
        (match (u1, u2) with
         | (FStar_Util.Inl n1,FStar_Util.Inl n2) -> FStar_Util.Inl (n1 + n2)
         | (FStar_Util.Inl n1,FStar_Util.Inr u) ->
             let uu____3730 = sum_to_universe u n1  in
             FStar_Util.Inr uu____3730
         | (FStar_Util.Inr u,FStar_Util.Inl n1) ->
             let uu____3747 = sum_to_universe u n1  in
             FStar_Util.Inr uu____3747
         | (FStar_Util.Inr u11,FStar_Util.Inr u21) ->
             let uu____3763 =
               let uu____3769 =
                 let uu____3771 = FStar_Parser_AST.term_to_string t  in
                 Prims.op_Hat
                   "This universe might contain a sum of two universe variables "
                   uu____3771
                  in
               (FStar_Errors.Fatal_UniverseMightContainSumOfTwoUnivVars,
                 uu____3769)
                in
             FStar_Errors.raise_error uu____3763 t.FStar_Parser_AST.range)
    | FStar_Parser_AST.App uu____3780 ->
        let rec aux t1 univargs =
          let uu____3817 =
            let uu____3818 = unparen t1  in uu____3818.FStar_Parser_AST.tm
             in
          match uu____3817 with
          | FStar_Parser_AST.App (t2,targ,uu____3826) ->
              let uarg = desugar_maybe_non_constant_universe targ  in
              aux t2 (uarg :: univargs)
          | FStar_Parser_AST.Var max_lid1 ->
              if
                FStar_List.existsb
                  (fun uu___5_3853  ->
                     match uu___5_3853 with
                     | FStar_Util.Inr uu____3860 -> true
                     | uu____3863 -> false) univargs
              then
                let uu____3871 =
                  let uu____3872 =
                    FStar_List.map
                      (fun uu___6_3882  ->
                         match uu___6_3882 with
                         | FStar_Util.Inl n1 -> int_to_universe n1
                         | FStar_Util.Inr u -> u) univargs
                     in
                  FStar_Syntax_Syntax.U_max uu____3872  in
                FStar_Util.Inr uu____3871
              else
                (let nargs =
                   FStar_List.map
                     (fun uu___7_3908  ->
                        match uu___7_3908 with
                        | FStar_Util.Inl n1 -> n1
                        | FStar_Util.Inr uu____3918 -> failwith "impossible")
                     univargs
                    in
                 let uu____3922 =
                   FStar_List.fold_left
                     (fun m  -> fun n1  -> if m > n1 then m else n1)
                     Prims.int_zero nargs
                    in
                 FStar_Util.Inl uu____3922)
          | uu____3938 ->
              let uu____3939 =
                let uu____3945 =
                  let uu____3947 =
                    let uu____3949 = FStar_Parser_AST.term_to_string t1  in
                    Prims.op_Hat uu____3949 " in universe context"  in
                  Prims.op_Hat "Unexpected term " uu____3947  in
                (FStar_Errors.Fatal_UnexpectedTermInUniverse, uu____3945)  in
              FStar_Errors.raise_error uu____3939 t1.FStar_Parser_AST.range
           in
        aux t []
    | uu____3964 ->
        let uu____3965 =
          let uu____3971 =
            let uu____3973 =
              let uu____3975 = FStar_Parser_AST.term_to_string t  in
              Prims.op_Hat uu____3975 " in universe context"  in
            Prims.op_Hat "Unexpected term " uu____3973  in
          (FStar_Errors.Fatal_UnexpectedTermInUniverse, uu____3971)  in
        FStar_Errors.raise_error uu____3965 t.FStar_Parser_AST.range
  
let (desugar_universe :
  FStar_Parser_AST.term -> FStar_Syntax_Syntax.universe) =
  fun t  ->
    let u = desugar_maybe_non_constant_universe t  in
    match u with
    | FStar_Util.Inl n1 -> int_to_universe n1
    | FStar_Util.Inr u1 -> u1
  
let (check_no_aq : FStar_Syntax_Syntax.antiquotations -> unit) =
  fun aq  ->
    match aq with
    | [] -> ()
    | (bv,{
            FStar_Syntax_Syntax.n = FStar_Syntax_Syntax.Tm_quoted
              (e,{
                   FStar_Syntax_Syntax.qkind =
                     FStar_Syntax_Syntax.Quote_dynamic ;
                   FStar_Syntax_Syntax.antiquotes = uu____4016;_});
            FStar_Syntax_Syntax.pos = uu____4017;
            FStar_Syntax_Syntax.vars = uu____4018;_})::uu____4019
        ->
        let uu____4050 =
          let uu____4056 =
            let uu____4058 = FStar_Syntax_Print.term_to_string e  in
            FStar_Util.format1 "Unexpected antiquotation: `@(%s)" uu____4058
             in
          (FStar_Errors.Fatal_UnexpectedAntiquotation, uu____4056)  in
        FStar_Errors.raise_error uu____4050 e.FStar_Syntax_Syntax.pos
    | (bv,e)::uu____4064 ->
        let uu____4083 =
          let uu____4089 =
            let uu____4091 = FStar_Syntax_Print.term_to_string e  in
            FStar_Util.format1 "Unexpected antiquotation: `#(%s)" uu____4091
             in
          (FStar_Errors.Fatal_UnexpectedAntiquotation, uu____4089)  in
        FStar_Errors.raise_error uu____4083 e.FStar_Syntax_Syntax.pos
  
let check_fields :
  'Auu____4104 .
    FStar_Syntax_DsEnv.env ->
      (FStar_Ident.lident * 'Auu____4104) Prims.list ->
        FStar_Range.range -> FStar_Syntax_DsEnv.record_or_dc
  =
  fun env  ->
    fun fields  ->
      fun rg  ->
        let uu____4132 = FStar_List.hd fields  in
        match uu____4132 with
        | (f,uu____4142) ->
            (FStar_Syntax_DsEnv.fail_if_qualified_by_curmodule env f;
             (let record =
                FStar_Syntax_DsEnv.fail_or env
                  (FStar_Syntax_DsEnv.try_lookup_record_by_field_name env) f
                 in
              let check_field uu____4154 =
                match uu____4154 with
                | (f',uu____4160) ->
                    (FStar_Syntax_DsEnv.fail_if_qualified_by_curmodule env f';
                     (let uu____4162 =
                        FStar_Syntax_DsEnv.belongs_to_record env f' record
                         in
                      if uu____4162
                      then ()
                      else
                        (let msg =
                           FStar_Util.format3
                             "Field %s belongs to record type %s, whereas field %s does not"
                             f.FStar_Ident.str
                             (record.FStar_Syntax_DsEnv.typename).FStar_Ident.str
                             f'.FStar_Ident.str
                            in
                         FStar_Errors.raise_error
                           (FStar_Errors.Fatal_FieldsNotBelongToSameRecordType,
                             msg) rg)))
                 in
              (let uu____4172 = FStar_List.tl fields  in
               FStar_List.iter check_field uu____4172);
              (match () with | () -> record)))
  
let rec (desugar_data_pat :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.pattern -> (env_t * bnd * annotated_pat Prims.list))
  =
  fun env  ->
    fun p  ->
      let check_linear_pattern_variables pats r =
        let rec pat_vars p1 =
          match p1.FStar_Syntax_Syntax.v with
          | FStar_Syntax_Syntax.Pat_dot_term uu____4498 ->
              FStar_Syntax_Syntax.no_names
          | FStar_Syntax_Syntax.Pat_wild uu____4505 ->
              FStar_Syntax_Syntax.no_names
          | FStar_Syntax_Syntax.Pat_constant uu____4506 ->
              FStar_Syntax_Syntax.no_names
          | FStar_Syntax_Syntax.Pat_var x ->
              FStar_Util.set_add x FStar_Syntax_Syntax.no_names
          | FStar_Syntax_Syntax.Pat_cons (uu____4508,pats1) ->
              let aux out uu____4549 =
                match uu____4549 with
                | (p2,uu____4562) ->
                    let intersection =
                      let uu____4572 = pat_vars p2  in
                      FStar_Util.set_intersect uu____4572 out  in
                    let uu____4575 = FStar_Util.set_is_empty intersection  in
                    if uu____4575
                    then
                      let uu____4580 = pat_vars p2  in
                      FStar_Util.set_union out uu____4580
                    else
                      (let duplicate_bv =
                         let uu____4586 =
                           FStar_Util.set_elements intersection  in
                         FStar_List.hd uu____4586  in
                       let uu____4589 =
                         let uu____4595 =
                           FStar_Util.format1
                             "Non-linear patterns are not permitted: `%s` appears more than once in this pattern."
                             (duplicate_bv.FStar_Syntax_Syntax.ppname).FStar_Ident.idText
                            in
                         (FStar_Errors.Fatal_NonLinearPatternNotPermitted,
                           uu____4595)
                          in
                       FStar_Errors.raise_error uu____4589 r)
                 in
              FStar_List.fold_left aux FStar_Syntax_Syntax.no_names pats1
           in
        match pats with
        | [] -> ()
        | p1::[] ->
            let uu____4619 = pat_vars p1  in
            FStar_All.pipe_right uu____4619 (fun a1  -> ())
        | p1::ps ->
            let pvars = pat_vars p1  in
            let aux p2 =
              let uu____4647 =
                let uu____4649 = pat_vars p2  in
                FStar_Util.set_eq pvars uu____4649  in
              if uu____4647
              then ()
              else
                (let nonlinear_vars =
                   let uu____4658 = pat_vars p2  in
                   FStar_Util.set_symmetric_difference pvars uu____4658  in
                 let first_nonlinear_var =
                   let uu____4662 = FStar_Util.set_elements nonlinear_vars
                      in
                   FStar_List.hd uu____4662  in
                 let uu____4665 =
                   let uu____4671 =
                     FStar_Util.format1
                       "Patterns in this match are incoherent, variable %s is bound in some but not all patterns."
                       (first_nonlinear_var.FStar_Syntax_Syntax.ppname).FStar_Ident.idText
                      in
                   (FStar_Errors.Fatal_IncoherentPatterns, uu____4671)  in
                 FStar_Errors.raise_error uu____4665 r)
               in
            FStar_List.iter aux ps
         in
      let resolvex l e x =
        let uu____4699 =
          FStar_All.pipe_right l
            (FStar_Util.find_opt
               (fun y  ->
                  (y.FStar_Syntax_Syntax.ppname).FStar_Ident.idText =
                    x.FStar_Ident.idText))
           in
        match uu____4699 with
        | FStar_Pervasives_Native.Some y -> (l, e, y)
        | uu____4716 ->
            let uu____4719 = FStar_Syntax_DsEnv.push_bv e x  in
            (match uu____4719 with | (e1,x1) -> ((x1 :: l), e1, x1))
         in
      let rec aux' top loc env1 p1 =
        let pos q = FStar_Syntax_Syntax.withinfo q p1.FStar_Parser_AST.prange
           in
        let pos_r r q = FStar_Syntax_Syntax.withinfo q r  in
        let orig = p1  in
        match p1.FStar_Parser_AST.pat with
        | FStar_Parser_AST.PatOr uu____4870 -> failwith "impossible"
        | FStar_Parser_AST.PatOp op ->
            let uu____4894 =
              let uu____4895 =
                let uu____4896 =
                  let uu____4903 =
                    let uu____4904 =
                      let uu____4910 =
                        FStar_Parser_AST.compile_op Prims.int_zero
                          op.FStar_Ident.idText op.FStar_Ident.idRange
                         in
                      (uu____4910, (op.FStar_Ident.idRange))  in
                    FStar_Ident.mk_ident uu____4904  in
                  (uu____4903, FStar_Pervasives_Native.None)  in
                FStar_Parser_AST.PatVar uu____4896  in
              {
                FStar_Parser_AST.pat = uu____4895;
                FStar_Parser_AST.prange = (p1.FStar_Parser_AST.prange)
              }  in
            aux loc env1 uu____4894
        | FStar_Parser_AST.PatAscribed (p2,(t,tacopt)) ->
            ((match tacopt with
              | FStar_Pervasives_Native.None  -> ()
              | FStar_Pervasives_Native.Some uu____4930 ->
                  FStar_Errors.raise_error
                    (FStar_Errors.Fatal_TypeWithinPatternsAllowedOnVariablesOnly,
                      "Type ascriptions within patterns cannot be associated with a tactic")
                    orig.FStar_Parser_AST.prange);
             (let uu____4933 = aux loc env1 p2  in
              match uu____4933 with
              | (loc1,env',binder,p3,annots,imp) ->
                  let annot_pat_var p4 t1 =
                    match p4.FStar_Syntax_Syntax.v with
                    | FStar_Syntax_Syntax.Pat_var x ->
                        let uu___933_5022 = p4  in
                        {
                          FStar_Syntax_Syntax.v =
                            (FStar_Syntax_Syntax.Pat_var
                               (let uu___935_5027 = x  in
                                {
                                  FStar_Syntax_Syntax.ppname =
                                    (uu___935_5027.FStar_Syntax_Syntax.ppname);
                                  FStar_Syntax_Syntax.index =
                                    (uu___935_5027.FStar_Syntax_Syntax.index);
                                  FStar_Syntax_Syntax.sort = t1
                                }));
                          FStar_Syntax_Syntax.p =
                            (uu___933_5022.FStar_Syntax_Syntax.p)
                        }
                    | FStar_Syntax_Syntax.Pat_wild x ->
                        let uu___939_5029 = p4  in
                        {
                          FStar_Syntax_Syntax.v =
                            (FStar_Syntax_Syntax.Pat_wild
                               (let uu___941_5034 = x  in
                                {
                                  FStar_Syntax_Syntax.ppname =
                                    (uu___941_5034.FStar_Syntax_Syntax.ppname);
                                  FStar_Syntax_Syntax.index =
                                    (uu___941_5034.FStar_Syntax_Syntax.index);
                                  FStar_Syntax_Syntax.sort = t1
                                }));
                          FStar_Syntax_Syntax.p =
                            (uu___939_5029.FStar_Syntax_Syntax.p)
                        }
                    | uu____5035 when top -> p4
                    | uu____5036 ->
                        FStar_Errors.raise_error
                          (FStar_Errors.Fatal_TypeWithinPatternsAllowedOnVariablesOnly,
                            "Type ascriptions within patterns are only allowed on variables")
                          orig.FStar_Parser_AST.prange
                     in
                  let uu____5041 =
                    match binder with
                    | LetBinder uu____5062 -> failwith "impossible"
                    | LocalBinder (x,aq) ->
                        let t1 =
                          let uu____5087 = close_fun env1 t  in
                          desugar_term env1 uu____5087  in
                        let x1 =
                          let uu___952_5089 = x  in
                          {
                            FStar_Syntax_Syntax.ppname =
                              (uu___952_5089.FStar_Syntax_Syntax.ppname);
                            FStar_Syntax_Syntax.index =
                              (uu___952_5089.FStar_Syntax_Syntax.index);
                            FStar_Syntax_Syntax.sort = t1
                          }  in
                        ([(x1, t1)], (LocalBinder (x1, aq)))
                     in
                  (match uu____5041 with
                   | (annots',binder1) ->
                       (loc1, env', binder1, p3,
                         (FStar_List.append annots' annots), imp))))
        | FStar_Parser_AST.PatWild aq ->
            let imp =
              aq = (FStar_Pervasives_Native.Some FStar_Parser_AST.Implicit)
               in
            let aq1 = trans_aqual env1 aq  in
            let x =
              FStar_Syntax_Syntax.new_bv
                (FStar_Pervasives_Native.Some (p1.FStar_Parser_AST.prange))
                FStar_Syntax_Syntax.tun
               in
            let uu____5157 =
              FStar_All.pipe_left pos (FStar_Syntax_Syntax.Pat_wild x)  in
            (loc, env1, (LocalBinder (x, aq1)), uu____5157, [], imp)
        | FStar_Parser_AST.PatConst c ->
            let x =
              FStar_Syntax_Syntax.new_bv
                (FStar_Pervasives_Native.Some (p1.FStar_Parser_AST.prange))
                FStar_Syntax_Syntax.tun
               in
            let uu____5171 =
              FStar_All.pipe_left pos (FStar_Syntax_Syntax.Pat_constant c)
               in
            (loc, env1, (LocalBinder (x, FStar_Pervasives_Native.None)),
              uu____5171, [], false)
        | FStar_Parser_AST.PatTvar (x,aq) ->
            let imp =
              aq = (FStar_Pervasives_Native.Some FStar_Parser_AST.Implicit)
               in
            let aq1 = trans_aqual env1 aq  in
            let uu____5195 = resolvex loc env1 x  in
            (match uu____5195 with
             | (loc1,env2,xbv) ->
                 let uu____5224 =
                   FStar_All.pipe_left pos (FStar_Syntax_Syntax.Pat_var xbv)
                    in
                 (loc1, env2, (LocalBinder (xbv, aq1)), uu____5224, [], imp))
        | FStar_Parser_AST.PatVar (x,aq) ->
            let imp =
              aq = (FStar_Pervasives_Native.Some FStar_Parser_AST.Implicit)
               in
            let aq1 = trans_aqual env1 aq  in
            let uu____5247 = resolvex loc env1 x  in
            (match uu____5247 with
             | (loc1,env2,xbv) ->
                 let uu____5276 =
                   FStar_All.pipe_left pos (FStar_Syntax_Syntax.Pat_var xbv)
                    in
                 (loc1, env2, (LocalBinder (xbv, aq1)), uu____5276, [], imp))
        | FStar_Parser_AST.PatName l ->
            let l1 =
              FStar_Syntax_DsEnv.fail_or env1
                (FStar_Syntax_DsEnv.try_lookup_datacon env1) l
               in
            let x =
              FStar_Syntax_Syntax.new_bv
                (FStar_Pervasives_Native.Some (p1.FStar_Parser_AST.prange))
                FStar_Syntax_Syntax.tun
               in
            let uu____5291 =
              FStar_All.pipe_left pos (FStar_Syntax_Syntax.Pat_cons (l1, []))
               in
            (loc, env1, (LocalBinder (x, FStar_Pervasives_Native.None)),
              uu____5291, [], false)
        | FStar_Parser_AST.PatApp
            ({ FStar_Parser_AST.pat = FStar_Parser_AST.PatName l;
               FStar_Parser_AST.prange = uu____5321;_},args)
            ->
            let uu____5327 =
              FStar_List.fold_right
                (fun arg  ->
                   fun uu____5388  ->
                     match uu____5388 with
                     | (loc1,env2,annots,args1) ->
                         let uu____5469 = aux loc1 env2 arg  in
                         (match uu____5469 with
                          | (loc2,env3,uu____5516,arg1,ans,imp) ->
                              (loc2, env3, (FStar_List.append ans annots),
                                ((arg1, imp) :: args1)))) args
                (loc, env1, [], [])
               in
            (match uu____5327 with
             | (loc1,env2,annots,args1) ->
                 let l1 =
                   FStar_Syntax_DsEnv.fail_or env2
                     (FStar_Syntax_DsEnv.try_lookup_datacon env2) l
                    in
                 let x =
                   FStar_Syntax_Syntax.new_bv
                     (FStar_Pervasives_Native.Some
                        (p1.FStar_Parser_AST.prange)) FStar_Syntax_Syntax.tun
                    in
                 let uu____5648 =
                   FStar_All.pipe_left pos
                     (FStar_Syntax_Syntax.Pat_cons (l1, args1))
                    in
                 (loc1, env2,
                   (LocalBinder (x, FStar_Pervasives_Native.None)),
                   uu____5648, annots, false))
        | FStar_Parser_AST.PatApp uu____5666 ->
            FStar_Errors.raise_error
              (FStar_Errors.Fatal_UnexpectedPattern, "Unexpected pattern")
              p1.FStar_Parser_AST.prange
        | FStar_Parser_AST.PatList pats ->
            let uu____5697 =
              FStar_List.fold_right
                (fun pat  ->
                   fun uu____5748  ->
                     match uu____5748 with
                     | (loc1,env2,annots,pats1) ->
                         let uu____5809 = aux loc1 env2 pat  in
                         (match uu____5809 with
                          | (loc2,env3,uu____5851,pat1,ans,uu____5854) ->
                              (loc2, env3, (FStar_List.append ans annots),
                                (pat1 :: pats1)))) pats (loc, env1, [], [])
               in
            (match uu____5697 with
             | (loc1,env2,annots,pats1) ->
                 let pat =
                   let uu____5951 =
                     let uu____5954 =
                       let uu____5961 =
                         FStar_Range.end_range p1.FStar_Parser_AST.prange  in
                       pos_r uu____5961  in
                     let uu____5962 =
                       let uu____5963 =
                         let uu____5977 =
                           FStar_Syntax_Syntax.lid_as_fv
                             FStar_Parser_Const.nil_lid
                             FStar_Syntax_Syntax.delta_constant
                             (FStar_Pervasives_Native.Some
                                FStar_Syntax_Syntax.Data_ctor)
                            in
                         (uu____5977, [])  in
                       FStar_Syntax_Syntax.Pat_cons uu____5963  in
                     FStar_All.pipe_left uu____5954 uu____5962  in
                   FStar_List.fold_right
                     (fun hd1  ->
                        fun tl1  ->
                          let r =
                            FStar_Range.union_ranges
                              hd1.FStar_Syntax_Syntax.p
                              tl1.FStar_Syntax_Syntax.p
                             in
                          let uu____6011 =
                            let uu____6012 =
                              let uu____6026 =
                                FStar_Syntax_Syntax.lid_as_fv
                                  FStar_Parser_Const.cons_lid
                                  FStar_Syntax_Syntax.delta_constant
                                  (FStar_Pervasives_Native.Some
                                     FStar_Syntax_Syntax.Data_ctor)
                                 in
                              (uu____6026, [(hd1, false); (tl1, false)])  in
                            FStar_Syntax_Syntax.Pat_cons uu____6012  in
                          FStar_All.pipe_left (pos_r r) uu____6011) pats1
                     uu____5951
                    in
                 let x =
                   FStar_Syntax_Syntax.new_bv
                     (FStar_Pervasives_Native.Some
                        (p1.FStar_Parser_AST.prange)) FStar_Syntax_Syntax.tun
                    in
                 (loc1, env2,
                   (LocalBinder (x, FStar_Pervasives_Native.None)), pat,
                   annots, false))
        | FStar_Parser_AST.PatTuple (args,dep1) ->
            let uu____6084 =
              FStar_List.fold_left
                (fun uu____6144  ->
                   fun p2  ->
                     match uu____6144 with
                     | (loc1,env2,annots,pats) ->
                         let uu____6226 = aux loc1 env2 p2  in
                         (match uu____6226 with
                          | (loc2,env3,uu____6273,pat,ans,uu____6276) ->
                              (loc2, env3, (FStar_List.append ans annots),
                                ((pat, false) :: pats)))) (loc, env1, [], [])
                args
               in
            (match uu____6084 with
             | (loc1,env2,annots,args1) ->
                 let args2 = FStar_List.rev args1  in
                 let l =
                   if dep1
                   then
                     FStar_Parser_Const.mk_dtuple_data_lid
                       (FStar_List.length args2) p1.FStar_Parser_AST.prange
                   else
                     FStar_Parser_Const.mk_tuple_data_lid
                       (FStar_List.length args2) p1.FStar_Parser_AST.prange
                    in
                 let constr =
                   FStar_Syntax_DsEnv.fail_or env2
                     (FStar_Syntax_DsEnv.try_lookup_lid env2) l
                    in
                 let l1 =
                   match constr.FStar_Syntax_Syntax.n with
                   | FStar_Syntax_Syntax.Tm_fvar fv -> fv
                   | uu____6442 -> failwith "impossible"  in
                 let x =
                   FStar_Syntax_Syntax.new_bv
                     (FStar_Pervasives_Native.Some
                        (p1.FStar_Parser_AST.prange)) FStar_Syntax_Syntax.tun
                    in
                 let uu____6445 =
                   FStar_All.pipe_left pos
                     (FStar_Syntax_Syntax.Pat_cons (l1, args2))
                    in
                 (loc1, env2,
                   (LocalBinder (x, FStar_Pervasives_Native.None)),
                   uu____6445, annots, false))
        | FStar_Parser_AST.PatRecord [] ->
            FStar_Errors.raise_error
              (FStar_Errors.Fatal_UnexpectedPattern, "Unexpected pattern")
              p1.FStar_Parser_AST.prange
        | FStar_Parser_AST.PatRecord fields ->
            let record = check_fields env1 fields p1.FStar_Parser_AST.prange
               in
            let fields1 =
              FStar_All.pipe_right fields
                (FStar_List.map
                   (fun uu____6526  ->
                      match uu____6526 with
                      | (f,p2) -> ((f.FStar_Ident.ident), p2)))
               in
            let args =
              FStar_All.pipe_right record.FStar_Syntax_DsEnv.fields
                (FStar_List.map
                   (fun uu____6556  ->
                      match uu____6556 with
                      | (f,uu____6562) ->
                          let uu____6563 =
                            FStar_All.pipe_right fields1
                              (FStar_List.tryFind
                                 (fun uu____6589  ->
                                    match uu____6589 with
                                    | (g,uu____6596) ->
                                        f.FStar_Ident.idText =
                                          g.FStar_Ident.idText))
                             in
                          (match uu____6563 with
                           | FStar_Pervasives_Native.None  ->
                               FStar_Parser_AST.mk_pattern
                                 (FStar_Parser_AST.PatWild
                                    FStar_Pervasives_Native.None)
                                 p1.FStar_Parser_AST.prange
                           | FStar_Pervasives_Native.Some (uu____6602,p2) ->
                               p2)))
               in
            let app =
              let uu____6609 =
                let uu____6610 =
                  let uu____6617 =
                    let uu____6618 =
                      let uu____6619 =
                        FStar_Ident.lid_of_ids
                          (FStar_List.append
                             (record.FStar_Syntax_DsEnv.typename).FStar_Ident.ns
                             [record.FStar_Syntax_DsEnv.constrname])
                         in
                      FStar_Parser_AST.PatName uu____6619  in
                    FStar_Parser_AST.mk_pattern uu____6618
                      p1.FStar_Parser_AST.prange
                     in
                  (uu____6617, args)  in
                FStar_Parser_AST.PatApp uu____6610  in
              FStar_Parser_AST.mk_pattern uu____6609
                p1.FStar_Parser_AST.prange
               in
            let uu____6622 = aux loc env1 app  in
            (match uu____6622 with
             | (env2,e,b,p2,annots,uu____6668) ->
                 let p3 =
                   match p2.FStar_Syntax_Syntax.v with
                   | FStar_Syntax_Syntax.Pat_cons (fv,args1) ->
                       let uu____6708 =
                         let uu____6709 =
                           let uu____6723 =
                             let uu___1100_6724 = fv  in
                             let uu____6725 =
                               let uu____6728 =
                                 let uu____6729 =
                                   let uu____6736 =
                                     FStar_All.pipe_right
                                       record.FStar_Syntax_DsEnv.fields
                                       (FStar_List.map
                                          FStar_Pervasives_Native.fst)
                                      in
                                   ((record.FStar_Syntax_DsEnv.typename),
                                     uu____6736)
                                    in
                                 FStar_Syntax_Syntax.Record_ctor uu____6729
                                  in
                               FStar_Pervasives_Native.Some uu____6728  in
                             {
                               FStar_Syntax_Syntax.fv_name =
                                 (uu___1100_6724.FStar_Syntax_Syntax.fv_name);
                               FStar_Syntax_Syntax.fv_delta =
                                 (uu___1100_6724.FStar_Syntax_Syntax.fv_delta);
                               FStar_Syntax_Syntax.fv_qual = uu____6725
                             }  in
                           (uu____6723, args1)  in
                         FStar_Syntax_Syntax.Pat_cons uu____6709  in
                       FStar_All.pipe_left pos uu____6708
                   | uu____6762 -> p2  in
                 (env2, e, b, p3, annots, false))
      
      and aux loc env1 p1 = aux' false loc env1 p1
       in
      let aux_maybe_or env1 p1 =
        let loc = []  in
        match p1.FStar_Parser_AST.pat with
        | FStar_Parser_AST.PatOr [] -> failwith "impossible"
        | FStar_Parser_AST.PatOr (p2::ps) ->
            let uu____6848 = aux' true loc env1 p2  in
            (match uu____6848 with
             | (loc1,env2,var,p3,ans,uu____6892) ->
                 let uu____6907 =
                   FStar_List.fold_left
                     (fun uu____6956  ->
                        fun p4  ->
                          match uu____6956 with
                          | (loc2,env3,ps1) ->
                              let uu____7021 = aux' true loc2 env3 p4  in
                              (match uu____7021 with
                               | (loc3,env4,uu____7062,p5,ans1,uu____7065) ->
                                   (loc3, env4, ((p5, ans1) :: ps1))))
                     (loc1, env2, []) ps
                    in
                 (match uu____6907 with
                  | (loc2,env3,ps1) ->
                      let pats = (p3, ans) :: (FStar_List.rev ps1)  in
                      (env3, var, pats)))
        | uu____7226 ->
            let uu____7227 = aux' true loc env1 p1  in
            (match uu____7227 with
             | (loc1,env2,vars,pat,ans,b) -> (env2, vars, [(pat, ans)]))
         in
      let uu____7324 = aux_maybe_or env p  in
      match uu____7324 with
      | (env1,b,pats) ->
          ((let uu____7379 = FStar_List.map FStar_Pervasives_Native.fst pats
               in
            check_linear_pattern_variables uu____7379
              p.FStar_Parser_AST.prange);
           (env1, b, pats))

and (desugar_binding_pat_maybe_top :
  Prims.bool ->
    FStar_Syntax_DsEnv.env ->
      FStar_Parser_AST.pattern -> (env_t * bnd * annotated_pat Prims.list))
  =
  fun top  ->
    fun env  ->
      fun p  ->
        let mklet x ty tacopt =
          let uu____7452 =
            let uu____7453 =
              let uu____7464 = FStar_Syntax_DsEnv.qualify env x  in
              (uu____7464, (ty, tacopt))  in
            LetBinder uu____7453  in
          (env, uu____7452, [])  in
        let op_to_ident x =
          let uu____7481 =
            let uu____7487 =
              FStar_Parser_AST.compile_op Prims.int_zero x.FStar_Ident.idText
                x.FStar_Ident.idRange
               in
            (uu____7487, (x.FStar_Ident.idRange))  in
          FStar_Ident.mk_ident uu____7481  in
        if top
        then
          match p.FStar_Parser_AST.pat with
          | FStar_Parser_AST.PatOp x ->
              let uu____7509 = op_to_ident x  in
              mklet uu____7509 FStar_Syntax_Syntax.tun
                FStar_Pervasives_Native.None
          | FStar_Parser_AST.PatVar (x,uu____7511) ->
              mklet x FStar_Syntax_Syntax.tun FStar_Pervasives_Native.None
          | FStar_Parser_AST.PatAscribed
              ({ FStar_Parser_AST.pat = FStar_Parser_AST.PatOp x;
                 FStar_Parser_AST.prange = uu____7517;_},(t,tacopt))
              ->
              let tacopt1 = FStar_Util.map_opt tacopt (desugar_term env)  in
              let uu____7533 = op_to_ident x  in
              let uu____7534 = desugar_term env t  in
              mklet uu____7533 uu____7534 tacopt1
          | FStar_Parser_AST.PatAscribed
              ({
                 FStar_Parser_AST.pat = FStar_Parser_AST.PatVar
                   (x,uu____7536);
                 FStar_Parser_AST.prange = uu____7537;_},(t,tacopt))
              ->
              let tacopt1 = FStar_Util.map_opt tacopt (desugar_term env)  in
              let uu____7557 = desugar_term env t  in
              mklet x uu____7557 tacopt1
          | uu____7558 ->
              FStar_Errors.raise_error
                (FStar_Errors.Fatal_UnexpectedPattern,
                  "Unexpected pattern at the top-level")
                p.FStar_Parser_AST.prange
        else
          (let uu____7571 = desugar_data_pat env p  in
           match uu____7571 with
           | (env1,binder,p1) ->
               let p2 =
                 match p1 with
                 | ({
                      FStar_Syntax_Syntax.v = FStar_Syntax_Syntax.Pat_var
                        uu____7600;
                      FStar_Syntax_Syntax.p = uu____7601;_},uu____7602)::[]
                     -> []
                 | ({
                      FStar_Syntax_Syntax.v = FStar_Syntax_Syntax.Pat_wild
                        uu____7615;
                      FStar_Syntax_Syntax.p = uu____7616;_},uu____7617)::[]
                     -> []
                 | uu____7630 -> p1  in
               (env1, binder, p2))

and (desugar_binding_pat :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.pattern -> (env_t * bnd * annotated_pat Prims.list))
  = fun env  -> fun p  -> desugar_binding_pat_maybe_top false env p

and (desugar_match_pat_maybe_top :
  Prims.bool ->
    FStar_Syntax_DsEnv.env ->
      FStar_Parser_AST.pattern -> (env_t * annotated_pat Prims.list))
  =
  fun uu____7638  ->
    fun env  ->
      fun pat  ->
        let uu____7642 = desugar_data_pat env pat  in
        match uu____7642 with | (env1,uu____7658,pat1) -> (env1, pat1)

and (desugar_match_pat :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.pattern -> (env_t * annotated_pat Prims.list))
  = fun env  -> fun p  -> desugar_match_pat_maybe_top false env p

and (desugar_term_aq :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.term ->
      (FStar_Syntax_Syntax.term * FStar_Syntax_Syntax.antiquotations))
  =
  fun env  ->
    fun e  ->
      let env1 = FStar_Syntax_DsEnv.set_expect_typ env false  in
      desugar_term_maybe_top false env1 e

and (desugar_term :
  FStar_Syntax_DsEnv.env -> FStar_Parser_AST.term -> FStar_Syntax_Syntax.term)
  =
  fun env  ->
    fun e  ->
      let uu____7680 = desugar_term_aq env e  in
      match uu____7680 with | (t,aq) -> (check_no_aq aq; t)

and (desugar_typ_aq :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.term ->
      (FStar_Syntax_Syntax.term * FStar_Syntax_Syntax.antiquotations))
  =
  fun env  ->
    fun e  ->
      let env1 = FStar_Syntax_DsEnv.set_expect_typ env true  in
      desugar_term_maybe_top false env1 e

and (desugar_typ :
  FStar_Syntax_DsEnv.env -> FStar_Parser_AST.term -> FStar_Syntax_Syntax.term)
  =
  fun env  ->
    fun e  ->
      let uu____7699 = desugar_typ_aq env e  in
      match uu____7699 with | (t,aq) -> (check_no_aq aq; t)

and (desugar_machine_integer :
  FStar_Syntax_DsEnv.env ->
    Prims.string ->
      (FStar_Const.signedness * FStar_Const.width) ->
        FStar_Range.range -> FStar_Syntax_Syntax.term)
  =
  fun env  ->
    fun repr  ->
      fun uu____7709  ->
        fun range  ->
          match uu____7709 with
          | (signedness,width) ->
              let tnm =
                Prims.op_Hat "FStar."
                  (Prims.op_Hat
                     (match signedness with
                      | FStar_Const.Unsigned  -> "U"
                      | FStar_Const.Signed  -> "")
                     (Prims.op_Hat "Int"
                        (match width with
                         | FStar_Const.Int8  -> "8"
                         | FStar_Const.Int16  -> "16"
                         | FStar_Const.Int32  -> "32"
                         | FStar_Const.Int64  -> "64")))
                 in
              ((let uu____7731 =
                  let uu____7733 =
                    FStar_Const.within_bounds repr signedness width  in
                  Prims.op_Negation uu____7733  in
                if uu____7731
                then
                  let uu____7736 =
                    let uu____7742 =
                      FStar_Util.format2
                        "%s is not in the expected range for %s" repr tnm
                       in
                    (FStar_Errors.Error_OutOfRange, uu____7742)  in
                  FStar_Errors.log_issue range uu____7736
                else ());
               (let private_intro_nm =
                  Prims.op_Hat tnm
                    (Prims.op_Hat ".__"
                       (Prims.op_Hat
                          (match signedness with
                           | FStar_Const.Unsigned  -> "u"
                           | FStar_Const.Signed  -> "") "int_to_t"))
                   in
                let intro_nm =
                  Prims.op_Hat tnm
                    (Prims.op_Hat "."
                       (Prims.op_Hat
                          (match signedness with
                           | FStar_Const.Unsigned  -> "u"
                           | FStar_Const.Signed  -> "") "int_to_t"))
                   in
                let lid =
                  let uu____7763 = FStar_Ident.path_of_text intro_nm  in
                  FStar_Ident.lid_of_path uu____7763 range  in
                let lid1 =
                  let uu____7767 = FStar_Syntax_DsEnv.try_lookup_lid env lid
                     in
                  match uu____7767 with
                  | FStar_Pervasives_Native.Some intro_term ->
                      (match intro_term.FStar_Syntax_Syntax.n with
                       | FStar_Syntax_Syntax.Tm_fvar fv ->
                           let private_lid =
                             let uu____7777 =
                               FStar_Ident.path_of_text private_intro_nm  in
                             FStar_Ident.lid_of_path uu____7777 range  in
                           let private_fv =
                             let uu____7779 =
                               FStar_Syntax_Util.incr_delta_depth
                                 fv.FStar_Syntax_Syntax.fv_delta
                                in
                             FStar_Syntax_Syntax.lid_as_fv private_lid
                               uu____7779 fv.FStar_Syntax_Syntax.fv_qual
                              in
                           let uu___1270_7780 = intro_term  in
                           {
                             FStar_Syntax_Syntax.n =
                               (FStar_Syntax_Syntax.Tm_fvar private_fv);
                             FStar_Syntax_Syntax.pos =
                               (uu___1270_7780.FStar_Syntax_Syntax.pos);
                             FStar_Syntax_Syntax.vars =
                               (uu___1270_7780.FStar_Syntax_Syntax.vars)
                           }
                       | uu____7781 ->
                           failwith
                             (Prims.op_Hat "Unexpected non-fvar for "
                                intro_nm))
                  | FStar_Pervasives_Native.None  ->
                      let uu____7785 =
                        let uu____7791 =
                          FStar_Util.format1
                            "Unexpected numeric literal.  Restart F* to load %s."
                            tnm
                           in
                        (FStar_Errors.Fatal_UnexpectedNumericLiteral,
                          uu____7791)
                         in
                      FStar_Errors.raise_error uu____7785 range
                   in
                let repr1 =
                  FStar_Syntax_Syntax.mk
                    (FStar_Syntax_Syntax.Tm_constant
                       (FStar_Const.Const_int
                          (repr, FStar_Pervasives_Native.None)))
                    FStar_Pervasives_Native.None range
                   in
                let uu____7811 =
                  let uu____7818 =
                    let uu____7819 =
                      let uu____7836 =
                        let uu____7847 =
                          let uu____7856 =
                            FStar_Syntax_Syntax.as_implicit false  in
                          (repr1, uu____7856)  in
                        [uu____7847]  in
                      (lid1, uu____7836)  in
                    FStar_Syntax_Syntax.Tm_app uu____7819  in
                  FStar_Syntax_Syntax.mk uu____7818  in
                uu____7811 FStar_Pervasives_Native.None range))

and (desugar_term_maybe_top :
  Prims.bool ->
    env_t ->
      FStar_Parser_AST.term ->
        (FStar_Syntax_Syntax.term * FStar_Syntax_Syntax.antiquotations))
  =
  fun top_level  ->
    fun env  ->
      fun top  ->
        let mk1 e =
          FStar_Syntax_Syntax.mk e FStar_Pervasives_Native.None
            top.FStar_Parser_AST.range
           in
        let noaqs = []  in
        let join_aqs aqs = FStar_List.flatten aqs  in
        let setpos e =
          let uu___1286_7975 = e  in
          {
            FStar_Syntax_Syntax.n = (uu___1286_7975.FStar_Syntax_Syntax.n);
            FStar_Syntax_Syntax.pos = (top.FStar_Parser_AST.range);
            FStar_Syntax_Syntax.vars =
              (uu___1286_7975.FStar_Syntax_Syntax.vars)
          }  in
        let uu____7978 =
          let uu____7979 = unparen top  in uu____7979.FStar_Parser_AST.tm  in
        match uu____7978 with
        | FStar_Parser_AST.Wild  -> ((setpos FStar_Syntax_Syntax.tun), noaqs)
        | FStar_Parser_AST.Labeled uu____7984 ->
            let uu____7993 = desugar_formula env top  in (uu____7993, noaqs)
        | FStar_Parser_AST.Requires (t,lopt) ->
            let uu____8002 = desugar_formula env t  in (uu____8002, noaqs)
        | FStar_Parser_AST.Ensures (t,lopt) ->
            let uu____8011 = desugar_formula env t  in (uu____8011, noaqs)
        | FStar_Parser_AST.Attributes ts ->
            failwith
              "Attributes should not be desugared by desugar_term_maybe_top"
        | FStar_Parser_AST.Const (FStar_Const.Const_int
            (i,FStar_Pervasives_Native.Some size)) ->
            let uu____8038 =
              desugar_machine_integer env i size top.FStar_Parser_AST.range
               in
            (uu____8038, noaqs)
        | FStar_Parser_AST.Const c ->
            let uu____8040 = mk1 (FStar_Syntax_Syntax.Tm_constant c)  in
            (uu____8040, noaqs)
        | FStar_Parser_AST.Op
            ({ FStar_Ident.idText = "=!="; FStar_Ident.idRange = r;_},args)
            ->
            let e =
              let uu____8049 =
                let uu____8050 =
                  let uu____8057 = FStar_Ident.mk_ident ("==", r)  in
                  (uu____8057, args)  in
                FStar_Parser_AST.Op uu____8050  in
              FStar_Parser_AST.mk_term uu____8049 top.FStar_Parser_AST.range
                top.FStar_Parser_AST.level
               in
            let uu____8062 =
              let uu____8063 =
                let uu____8064 =
                  let uu____8071 = FStar_Ident.mk_ident ("~", r)  in
                  (uu____8071, [e])  in
                FStar_Parser_AST.Op uu____8064  in
              FStar_Parser_AST.mk_term uu____8063 top.FStar_Parser_AST.range
                top.FStar_Parser_AST.level
               in
            desugar_term_aq env uu____8062
        | FStar_Parser_AST.Op (op_star,lhs::rhs::[]) when
            (let uu____8083 = FStar_Ident.text_of_id op_star  in
             uu____8083 = "*") &&
              (let uu____8088 =
                 op_as_term env (Prims.of_int (2)) top.FStar_Parser_AST.range
                   op_star
                  in
               FStar_All.pipe_right uu____8088 FStar_Option.isNone)
            ->
            let rec flatten1 t =
              match t.FStar_Parser_AST.tm with
              | FStar_Parser_AST.Op
                  ({ FStar_Ident.idText = "*";
                     FStar_Ident.idRange = uu____8105;_},t1::t2::[])
                  when
                  let uu____8111 =
                    op_as_term env (Prims.of_int (2))
                      top.FStar_Parser_AST.range op_star
                     in
                  FStar_All.pipe_right uu____8111 FStar_Option.isNone ->
                  let uu____8118 = flatten1 t1  in
                  FStar_List.append uu____8118 [t2]
              | uu____8121 -> [t]  in
            let terms = flatten1 lhs  in
            let t =
              let uu___1334_8126 = top  in
              let uu____8127 =
                let uu____8128 =
                  let uu____8139 =
                    FStar_List.map (fun _8150  -> FStar_Util.Inr _8150) terms
                     in
                  (uu____8139, rhs)  in
                FStar_Parser_AST.Sum uu____8128  in
              {
                FStar_Parser_AST.tm = uu____8127;
                FStar_Parser_AST.range =
                  (uu___1334_8126.FStar_Parser_AST.range);
                FStar_Parser_AST.level =
                  (uu___1334_8126.FStar_Parser_AST.level)
              }  in
            desugar_term_maybe_top top_level env t
        | FStar_Parser_AST.Tvar a ->
            let uu____8158 =
              let uu____8159 =
                FStar_Syntax_DsEnv.fail_or2
                  (FStar_Syntax_DsEnv.try_lookup_id env) a
                 in
              FStar_All.pipe_left setpos uu____8159  in
            (uu____8158, noaqs)
        | FStar_Parser_AST.Uvar u ->
            let uu____8165 =
              let uu____8171 =
                let uu____8173 =
                  let uu____8175 = FStar_Ident.text_of_id u  in
                  Prims.op_Hat uu____8175 " in non-universe context"  in
                Prims.op_Hat "Unexpected universe variable " uu____8173  in
              (FStar_Errors.Fatal_UnexpectedUniverseVariable, uu____8171)  in
            FStar_Errors.raise_error uu____8165 top.FStar_Parser_AST.range
        | FStar_Parser_AST.Op (s,args) ->
            let uu____8190 =
              op_as_term env (FStar_List.length args)
                top.FStar_Parser_AST.range s
               in
            (match uu____8190 with
             | FStar_Pervasives_Native.None  ->
                 let uu____8197 =
                   let uu____8203 =
                     let uu____8205 = FStar_Ident.text_of_id s  in
                     Prims.op_Hat "Unexpected or unbound operator: "
                       uu____8205
                      in
                   (FStar_Errors.Fatal_UnepxectedOrUnboundOperator,
                     uu____8203)
                    in
                 FStar_Errors.raise_error uu____8197
                   top.FStar_Parser_AST.range
             | FStar_Pervasives_Native.Some op ->
                 if (FStar_List.length args) > Prims.int_zero
                 then
                   let uu____8220 =
                     let uu____8245 =
                       FStar_All.pipe_right args
                         (FStar_List.map
                            (fun t  ->
                               let uu____8307 = desugar_term_aq env t  in
                               match uu____8307 with
                               | (t',s1) ->
                                   ((t', FStar_Pervasives_Native.None), s1)))
                        in
                     FStar_All.pipe_right uu____8245 FStar_List.unzip  in
                   (match uu____8220 with
                    | (args1,aqs) ->
                        let uu____8440 =
                          mk1 (FStar_Syntax_Syntax.Tm_app (op, args1))  in
                        (uu____8440, (join_aqs aqs)))
                 else (op, noaqs))
        | FStar_Parser_AST.Construct (n1,(a,uu____8457)::[]) when
            n1.FStar_Ident.str = "SMTPat" ->
            let uu____8474 =
              let uu___1363_8475 = top  in
              let uu____8476 =
                let uu____8477 =
                  let uu____8484 =
                    let uu___1365_8485 = top  in
                    let uu____8486 =
                      let uu____8487 =
                        FStar_Ident.lid_of_path ["Prims"; "smt_pat"]
                          top.FStar_Parser_AST.range
                         in
                      FStar_Parser_AST.Var uu____8487  in
                    {
                      FStar_Parser_AST.tm = uu____8486;
                      FStar_Parser_AST.range =
                        (uu___1365_8485.FStar_Parser_AST.range);
                      FStar_Parser_AST.level =
                        (uu___1365_8485.FStar_Parser_AST.level)
                    }  in
                  (uu____8484, a, FStar_Parser_AST.Nothing)  in
                FStar_Parser_AST.App uu____8477  in
              {
                FStar_Parser_AST.tm = uu____8476;
                FStar_Parser_AST.range =
                  (uu___1363_8475.FStar_Parser_AST.range);
                FStar_Parser_AST.level =
                  (uu___1363_8475.FStar_Parser_AST.level)
              }  in
            desugar_term_maybe_top top_level env uu____8474
        | FStar_Parser_AST.Construct (n1,(a,uu____8495)::[]) when
            n1.FStar_Ident.str = "SMTPatT" ->
            (FStar_Errors.log_issue top.FStar_Parser_AST.range
               (FStar_Errors.Warning_SMTPatTDeprecated,
                 "SMTPatT is deprecated; please just use SMTPat");
             (let uu____8515 =
                let uu___1375_8516 = top  in
                let uu____8517 =
                  let uu____8518 =
                    let uu____8525 =
                      let uu___1377_8526 = top  in
                      let uu____8527 =
                        let uu____8528 =
                          FStar_Ident.lid_of_path ["Prims"; "smt_pat"]
                            top.FStar_Parser_AST.range
                           in
                        FStar_Parser_AST.Var uu____8528  in
                      {
                        FStar_Parser_AST.tm = uu____8527;
                        FStar_Parser_AST.range =
                          (uu___1377_8526.FStar_Parser_AST.range);
                        FStar_Parser_AST.level =
                          (uu___1377_8526.FStar_Parser_AST.level)
                      }  in
                    (uu____8525, a, FStar_Parser_AST.Nothing)  in
                  FStar_Parser_AST.App uu____8518  in
                {
                  FStar_Parser_AST.tm = uu____8517;
                  FStar_Parser_AST.range =
                    (uu___1375_8516.FStar_Parser_AST.range);
                  FStar_Parser_AST.level =
                    (uu___1375_8516.FStar_Parser_AST.level)
                }  in
              desugar_term_maybe_top top_level env uu____8515))
        | FStar_Parser_AST.Construct (n1,(a,uu____8536)::[]) when
            n1.FStar_Ident.str = "SMTPatOr" ->
            let uu____8553 =
              let uu___1386_8554 = top  in
              let uu____8555 =
                let uu____8556 =
                  let uu____8563 =
                    let uu___1388_8564 = top  in
                    let uu____8565 =
                      let uu____8566 =
                        FStar_Ident.lid_of_path ["Prims"; "smt_pat_or"]
                          top.FStar_Parser_AST.range
                         in
                      FStar_Parser_AST.Var uu____8566  in
                    {
                      FStar_Parser_AST.tm = uu____8565;
                      FStar_Parser_AST.range =
                        (uu___1388_8564.FStar_Parser_AST.range);
                      FStar_Parser_AST.level =
                        (uu___1388_8564.FStar_Parser_AST.level)
                    }  in
                  (uu____8563, a, FStar_Parser_AST.Nothing)  in
                FStar_Parser_AST.App uu____8556  in
              {
                FStar_Parser_AST.tm = uu____8555;
                FStar_Parser_AST.range =
                  (uu___1386_8554.FStar_Parser_AST.range);
                FStar_Parser_AST.level =
                  (uu___1386_8554.FStar_Parser_AST.level)
              }  in
            desugar_term_maybe_top top_level env uu____8553
        | FStar_Parser_AST.Name
            { FStar_Ident.ns = uu____8572; FStar_Ident.ident = uu____8573;
              FStar_Ident.nsstr = uu____8574; FStar_Ident.str = "Type0";_}
            ->
            let uu____8579 =
              mk1 (FStar_Syntax_Syntax.Tm_type FStar_Syntax_Syntax.U_zero)
               in
            (uu____8579, noaqs)
        | FStar_Parser_AST.Name
            { FStar_Ident.ns = uu____8580; FStar_Ident.ident = uu____8581;
              FStar_Ident.nsstr = uu____8582; FStar_Ident.str = "Type";_}
            ->
            let uu____8587 =
              mk1 (FStar_Syntax_Syntax.Tm_type FStar_Syntax_Syntax.U_unknown)
               in
            (uu____8587, noaqs)
        | FStar_Parser_AST.Construct
            ({ FStar_Ident.ns = uu____8588; FStar_Ident.ident = uu____8589;
               FStar_Ident.nsstr = uu____8590; FStar_Ident.str = "Type";_},
             (t,FStar_Parser_AST.UnivApp )::[])
            ->
            let uu____8610 =
              let uu____8611 =
                let uu____8612 = desugar_universe t  in
                FStar_Syntax_Syntax.Tm_type uu____8612  in
              mk1 uu____8611  in
            (uu____8610, noaqs)
        | FStar_Parser_AST.Name
            { FStar_Ident.ns = uu____8613; FStar_Ident.ident = uu____8614;
              FStar_Ident.nsstr = uu____8615; FStar_Ident.str = "Effect";_}
            ->
            let uu____8620 =
              mk1 (FStar_Syntax_Syntax.Tm_constant FStar_Const.Const_effect)
               in
            (uu____8620, noaqs)
        | FStar_Parser_AST.Name
            { FStar_Ident.ns = uu____8621; FStar_Ident.ident = uu____8622;
              FStar_Ident.nsstr = uu____8623; FStar_Ident.str = "True";_}
            ->
            let uu____8628 =
              let uu____8629 =
                FStar_Ident.set_lid_range FStar_Parser_Const.true_lid
                  top.FStar_Parser_AST.range
                 in
              FStar_Syntax_Syntax.fvar uu____8629
                FStar_Syntax_Syntax.delta_constant
                FStar_Pervasives_Native.None
               in
            (uu____8628, noaqs)
        | FStar_Parser_AST.Name
            { FStar_Ident.ns = uu____8630; FStar_Ident.ident = uu____8631;
              FStar_Ident.nsstr = uu____8632; FStar_Ident.str = "False";_}
            ->
            let uu____8637 =
              let uu____8638 =
                FStar_Ident.set_lid_range FStar_Parser_Const.false_lid
                  top.FStar_Parser_AST.range
                 in
              FStar_Syntax_Syntax.fvar uu____8638
                FStar_Syntax_Syntax.delta_constant
                FStar_Pervasives_Native.None
               in
            (uu____8637, noaqs)
        | FStar_Parser_AST.Projector
            (eff_name,{ FStar_Ident.idText = txt;
                        FStar_Ident.idRange = uu____8641;_})
            when
            (is_special_effect_combinator txt) &&
              (FStar_Syntax_DsEnv.is_effect_name env eff_name)
            ->
            (FStar_Syntax_DsEnv.fail_if_qualified_by_curmodule env eff_name;
             (let uu____8644 =
                FStar_Syntax_DsEnv.try_lookup_effect_defn env eff_name  in
              match uu____8644 with
              | FStar_Pervasives_Native.Some ed ->
                  let lid = FStar_Syntax_Util.dm4f_lid ed txt  in
                  let uu____8653 =
                    FStar_Syntax_Syntax.fvar lid
                      (FStar_Syntax_Syntax.Delta_constant_at_level
                         Prims.int_one) FStar_Pervasives_Native.None
                     in
                  (uu____8653, noaqs)
              | FStar_Pervasives_Native.None  ->
                  let uu____8655 =
                    let uu____8657 = FStar_Ident.text_of_lid eff_name  in
                    FStar_Util.format2
                      "Member %s of effect %s is not accessible (using an effect abbreviation instead of the original effect ?)"
                      uu____8657 txt
                     in
                  failwith uu____8655))
        | FStar_Parser_AST.Var l ->
            (FStar_Syntax_DsEnv.fail_if_qualified_by_curmodule env l;
             (let uu____8666 = desugar_name mk1 setpos env true l  in
              (uu____8666, noaqs)))
        | FStar_Parser_AST.Name l ->
            (FStar_Syntax_DsEnv.fail_if_qualified_by_curmodule env l;
             (let uu____8675 = desugar_name mk1 setpos env true l  in
              (uu____8675, noaqs)))
        | FStar_Parser_AST.Projector (l,i) ->
            (FStar_Syntax_DsEnv.fail_if_qualified_by_curmodule env l;
             (let name =
                let uu____8693 = FStar_Syntax_DsEnv.try_lookup_datacon env l
                   in
                match uu____8693 with
                | FStar_Pervasives_Native.Some uu____8703 ->
                    FStar_Pervasives_Native.Some (true, l)
                | FStar_Pervasives_Native.None  ->
                    let uu____8711 =
                      FStar_Syntax_DsEnv.try_lookup_root_effect_name env l
                       in
                    (match uu____8711 with
                     | FStar_Pervasives_Native.Some new_name ->
                         FStar_Pervasives_Native.Some (false, new_name)
                     | uu____8729 -> FStar_Pervasives_Native.None)
                 in
              match name with
              | FStar_Pervasives_Native.Some (resolve,new_name) ->
                  let uu____8750 =
                    let uu____8751 =
                      FStar_Syntax_Util.mk_field_projector_name_from_ident
                        new_name i
                       in
                    desugar_name mk1 setpos env resolve uu____8751  in
                  (uu____8750, noaqs)
              | uu____8757 ->
                  let uu____8765 =
                    let uu____8771 =
                      FStar_Util.format1
                        "Data constructor or effect %s not found"
                        l.FStar_Ident.str
                       in
                    (FStar_Errors.Fatal_EffectNotFound, uu____8771)  in
                  FStar_Errors.raise_error uu____8765
                    top.FStar_Parser_AST.range))
        | FStar_Parser_AST.Discrim lid ->
            (FStar_Syntax_DsEnv.fail_if_qualified_by_curmodule env lid;
             (let uu____8781 = FStar_Syntax_DsEnv.try_lookup_datacon env lid
                 in
              match uu____8781 with
              | FStar_Pervasives_Native.None  ->
                  let uu____8788 =
                    let uu____8794 =
                      FStar_Util.format1 "Data constructor %s not found"
                        lid.FStar_Ident.str
                       in
                    (FStar_Errors.Fatal_DataContructorNotFound, uu____8794)
                     in
                  FStar_Errors.raise_error uu____8788
                    top.FStar_Parser_AST.range
              | uu____8802 ->
                  let lid' = FStar_Syntax_Util.mk_discriminator lid  in
                  let uu____8806 = desugar_name mk1 setpos env true lid'  in
                  (uu____8806, noaqs)))
        | FStar_Parser_AST.Construct (l,args) ->
            (FStar_Syntax_DsEnv.fail_if_qualified_by_curmodule env l;
             (let uu____8828 = FStar_Syntax_DsEnv.try_lookup_datacon env l
                 in
              match uu____8828 with
              | FStar_Pervasives_Native.Some head1 ->
                  let head2 = mk1 (FStar_Syntax_Syntax.Tm_fvar head1)  in
                  (match args with
                   | [] -> (head2, noaqs)
                   | uu____8847 ->
                       let uu____8854 =
                         FStar_Util.take
                           (fun uu____8878  ->
                              match uu____8878 with
                              | (uu____8884,imp) ->
                                  imp = FStar_Parser_AST.UnivApp) args
                          in
                       (match uu____8854 with
                        | (universes,args1) ->
                            let universes1 =
                              FStar_List.map
                                (fun x  ->
                                   desugar_universe
                                     (FStar_Pervasives_Native.fst x))
                                universes
                               in
                            let uu____8929 =
                              let uu____8954 =
                                FStar_List.map
                                  (fun uu____8997  ->
                                     match uu____8997 with
                                     | (t,imp) ->
                                         let uu____9014 =
                                           desugar_term_aq env t  in
                                         (match uu____9014 with
                                          | (te,aq) ->
                                              ((arg_withimp_e imp te), aq)))
                                  args1
                                 in
                              FStar_All.pipe_right uu____8954
                                FStar_List.unzip
                               in
                            (match uu____8929 with
                             | (args2,aqs) ->
                                 let head3 =
                                   if universes1 = []
                                   then head2
                                   else
                                     mk1
                                       (FStar_Syntax_Syntax.Tm_uinst
                                          (head2, universes1))
                                    in
                                 let uu____9157 =
                                   mk1
                                     (FStar_Syntax_Syntax.Tm_app
                                        (head3, args2))
                                    in
                                 (uu____9157, (join_aqs aqs)))))
              | FStar_Pervasives_Native.None  ->
                  let err =
                    let uu____9176 =
                      FStar_Syntax_DsEnv.try_lookup_effect_name env l  in
                    match uu____9176 with
                    | FStar_Pervasives_Native.None  ->
                        (FStar_Errors.Fatal_ConstructorNotFound,
                          (Prims.op_Hat "Constructor "
                             (Prims.op_Hat l.FStar_Ident.str " not found")))
                    | FStar_Pervasives_Native.Some uu____9187 ->
                        (FStar_Errors.Fatal_UnexpectedEffect,
                          (Prims.op_Hat "Effect "
                             (Prims.op_Hat l.FStar_Ident.str
                                " used at an unexpected position")))
                     in
                  FStar_Errors.raise_error err top.FStar_Parser_AST.range))
        | FStar_Parser_AST.Sum (binders,t) when
            FStar_Util.for_all
              (fun uu___8_9215  ->
                 match uu___8_9215 with
                 | FStar_Util.Inr uu____9221 -> true
                 | uu____9223 -> false) binders
            ->
            let terms =
              let uu____9232 =
                FStar_All.pipe_right binders
                  (FStar_List.map
                     (fun uu___9_9249  ->
                        match uu___9_9249 with
                        | FStar_Util.Inr x -> x
                        | FStar_Util.Inl uu____9255 -> failwith "Impossible"))
                 in
              FStar_List.append uu____9232 [t]  in
            let uu____9257 =
              let uu____9282 =
                FStar_All.pipe_right terms
                  (FStar_List.map
                     (fun t1  ->
                        let uu____9339 = desugar_typ_aq env t1  in
                        match uu____9339 with
                        | (t',aq) ->
                            let uu____9350 = FStar_Syntax_Syntax.as_arg t'
                               in
                            (uu____9350, aq)))
                 in
              FStar_All.pipe_right uu____9282 FStar_List.unzip  in
            (match uu____9257 with
             | (targs,aqs) ->
                 let tup =
                   let uu____9460 =
                     FStar_Parser_Const.mk_tuple_lid
                       (FStar_List.length targs) top.FStar_Parser_AST.range
                      in
                   FStar_Syntax_DsEnv.fail_or env
                     (FStar_Syntax_DsEnv.try_lookup_lid env) uu____9460
                    in
                 let uu____9469 =
                   mk1 (FStar_Syntax_Syntax.Tm_app (tup, targs))  in
                 (uu____9469, (join_aqs aqs)))
        | FStar_Parser_AST.Sum (binders,t) ->
            let uu____9496 =
              let uu____9513 =
                let uu____9520 =
                  let uu____9527 =
                    FStar_All.pipe_left (fun _9536  -> FStar_Util.Inl _9536)
                      (FStar_Parser_AST.mk_binder (FStar_Parser_AST.NoName t)
                         t.FStar_Parser_AST.range FStar_Parser_AST.Type_level
                         FStar_Pervasives_Native.None)
                     in
                  [uu____9527]  in
                FStar_List.append binders uu____9520  in
              FStar_List.fold_left
                (fun uu____9581  ->
                   fun b  ->
                     match uu____9581 with
                     | (env1,tparams,typs) ->
                         let uu____9642 =
                           match b with
                           | FStar_Util.Inl b1 -> desugar_binder env1 b1
                           | FStar_Util.Inr t1 ->
                               let uu____9657 = desugar_typ env1 t1  in
                               (FStar_Pervasives_Native.None, uu____9657)
                            in
                         (match uu____9642 with
                          | (xopt,t1) ->
                              let uu____9682 =
                                match xopt with
                                | FStar_Pervasives_Native.None  ->
                                    let uu____9691 =
                                      FStar_Syntax_Syntax.new_bv
                                        (FStar_Pervasives_Native.Some
                                           (top.FStar_Parser_AST.range))
                                        FStar_Syntax_Syntax.tun
                                       in
                                    (env1, uu____9691)
                                | FStar_Pervasives_Native.Some x ->
                                    FStar_Syntax_DsEnv.push_bv env1 x
                                 in
                              (match uu____9682 with
                               | (env2,x) ->
                                   let uu____9711 =
                                     let uu____9714 =
                                       let uu____9717 =
                                         let uu____9718 =
                                           no_annot_abs tparams t1  in
                                         FStar_All.pipe_left
                                           FStar_Syntax_Syntax.as_arg
                                           uu____9718
                                          in
                                       [uu____9717]  in
                                     FStar_List.append typs uu____9714  in
                                   (env2,
                                     (FStar_List.append tparams
                                        [(((let uu___1547_9744 = x  in
                                            {
                                              FStar_Syntax_Syntax.ppname =
                                                (uu___1547_9744.FStar_Syntax_Syntax.ppname);
                                              FStar_Syntax_Syntax.index =
                                                (uu___1547_9744.FStar_Syntax_Syntax.index);
                                              FStar_Syntax_Syntax.sort = t1
                                            })),
                                           FStar_Pervasives_Native.None)]),
                                     uu____9711)))) (env, [], []) uu____9513
               in
            (match uu____9496 with
             | (env1,uu____9772,targs) ->
                 let tup =
                   let uu____9795 =
                     FStar_Parser_Const.mk_dtuple_lid
                       (FStar_List.length targs) top.FStar_Parser_AST.range
                      in
                   FStar_Syntax_DsEnv.fail_or env1
                     (FStar_Syntax_DsEnv.try_lookup_lid env1) uu____9795
                    in
                 let uu____9796 =
                   FStar_All.pipe_left mk1
                     (FStar_Syntax_Syntax.Tm_app (tup, targs))
                    in
                 (uu____9796, noaqs))
        | FStar_Parser_AST.Product (binders,t) ->
            let uu____9815 = uncurry binders t  in
            (match uu____9815 with
             | (bs,t1) ->
                 let rec aux env1 bs1 uu___10_9859 =
                   match uu___10_9859 with
                   | [] ->
                       let cod =
                         desugar_comp top.FStar_Parser_AST.range true env1 t1
                          in
                       let uu____9876 =
                         FStar_Syntax_Util.arrow (FStar_List.rev bs1) cod  in
                       FStar_All.pipe_left setpos uu____9876
                   | hd1::tl1 ->
                       let bb = desugar_binder env1 hd1  in
                       let uu____9900 =
                         as_binder env1 hd1.FStar_Parser_AST.aqual bb  in
                       (match uu____9900 with
                        | (b,env2) -> aux env2 (b :: bs1) tl1)
                    in
                 let uu____9933 = aux env [] bs  in (uu____9933, noaqs))
        | FStar_Parser_AST.Refine (b,f) ->
            let uu____9942 = desugar_binder env b  in
            (match uu____9942 with
             | (FStar_Pervasives_Native.None ,uu____9953) ->
                 failwith "Missing binder in refinement"
             | b1 ->
                 let uu____9968 =
                   as_binder env FStar_Pervasives_Native.None b1  in
                 (match uu____9968 with
                  | ((x,uu____9984),env1) ->
                      let f1 = desugar_formula env1 f  in
                      let uu____9997 =
                        let uu____9998 = FStar_Syntax_Util.refine x f1  in
                        FStar_All.pipe_left setpos uu____9998  in
                      (uu____9997, noaqs)))
        | FStar_Parser_AST.Abs (binders,body) ->
            let bvss =
              FStar_List.map (gather_pattern_bound_vars false) binders  in
            let check_disjoint sets =
              let rec aux acc sets1 =
                match sets1 with
                | [] -> FStar_Pervasives_Native.None
                | set1::sets2 ->
                    let i = FStar_Util.set_intersect acc set1  in
                    let uu____10077 = FStar_Util.set_is_empty i  in
                    if uu____10077
                    then
                      let uu____10082 = FStar_Util.set_union acc set1  in
                      aux uu____10082 sets2
                    else
                      (let uu____10087 =
                         let uu____10088 = FStar_Util.set_elements i  in
                         FStar_List.hd uu____10088  in
                       FStar_Pervasives_Native.Some uu____10087)
                 in
              let uu____10091 = FStar_Syntax_Syntax.new_id_set ()  in
              aux uu____10091 sets  in
            ((let uu____10095 = check_disjoint bvss  in
              match uu____10095 with
              | FStar_Pervasives_Native.None  -> ()
              | FStar_Pervasives_Native.Some id1 ->
                  let uu____10099 =
                    let uu____10105 =
                      FStar_Util.format1
                        "Non-linear patterns are not permitted: `%s` appears more than once in this function definition."
                        id1.FStar_Ident.idText
                       in
                    (FStar_Errors.Fatal_NonLinearPatternNotPermitted,
                      uu____10105)
                     in
                  let uu____10109 = FStar_Ident.range_of_id id1  in
                  FStar_Errors.raise_error uu____10099 uu____10109);
             (let binders1 =
                FStar_All.pipe_right binders
                  (FStar_List.map replace_unit_pattern)
                 in
              let uu____10117 =
                FStar_List.fold_left
                  (fun uu____10137  ->
                     fun pat  ->
                       match uu____10137 with
                       | (env1,ftvs) ->
                           (match pat.FStar_Parser_AST.pat with
                            | FStar_Parser_AST.PatAscribed
                                (uu____10163,(t,FStar_Pervasives_Native.None
                                              ))
                                ->
                                let uu____10173 =
                                  let uu____10176 = free_type_vars env1 t  in
                                  FStar_List.append uu____10176 ftvs  in
                                (env1, uu____10173)
                            | FStar_Parser_AST.PatAscribed
                                (uu____10181,(t,FStar_Pervasives_Native.Some
                                              tac))
                                ->
                                let uu____10192 =
                                  let uu____10195 = free_type_vars env1 t  in
                                  let uu____10198 =
                                    let uu____10201 = free_type_vars env1 tac
                                       in
                                    FStar_List.append uu____10201 ftvs  in
                                  FStar_List.append uu____10195 uu____10198
                                   in
                                (env1, uu____10192)
                            | uu____10206 -> (env1, ftvs))) (env, [])
                  binders1
                 in
              match uu____10117 with
              | (uu____10215,ftv) ->
                  let ftv1 = sort_ftv ftv  in
                  let binders2 =
                    let uu____10227 =
                      FStar_All.pipe_right ftv1
                        (FStar_List.map
                           (fun a  ->
                              FStar_Parser_AST.mk_pattern
                                (FStar_Parser_AST.PatTvar
                                   (a,
                                     (FStar_Pervasives_Native.Some
                                        FStar_Parser_AST.Implicit)))
                                top.FStar_Parser_AST.range))
                       in
                    FStar_List.append uu____10227 binders1  in
                  let rec aux env1 bs sc_pat_opt uu___11_10284 =
                    match uu___11_10284 with
                    | [] ->
                        let uu____10311 = desugar_term_aq env1 body  in
                        (match uu____10311 with
                         | (body1,aq) ->
                             let body2 =
                               match sc_pat_opt with
                               | FStar_Pervasives_Native.Some (sc,pat) ->
                                   let body2 =
                                     let uu____10348 =
                                       let uu____10349 =
                                         FStar_Syntax_Syntax.pat_bvs pat  in
                                       FStar_All.pipe_right uu____10349
                                         (FStar_List.map
                                            FStar_Syntax_Syntax.mk_binder)
                                        in
                                     FStar_Syntax_Subst.close uu____10348
                                       body1
                                      in
                                   FStar_Syntax_Syntax.mk
                                     (FStar_Syntax_Syntax.Tm_match
                                        (sc,
                                          [(pat,
                                             FStar_Pervasives_Native.None,
                                             body2)]))
                                     FStar_Pervasives_Native.None
                                     body2.FStar_Syntax_Syntax.pos
                               | FStar_Pervasives_Native.None  -> body1  in
                             let uu____10418 =
                               let uu____10421 =
                                 no_annot_abs (FStar_List.rev bs) body2  in
                               setpos uu____10421  in
                             (uu____10418, aq))
                    | p::rest ->
                        let uu____10436 = desugar_binding_pat env1 p  in
                        (match uu____10436 with
                         | (env2,b,pat) ->
                             let pat1 =
                               match pat with
                               | [] -> FStar_Pervasives_Native.None
                               | (p1,uu____10470)::[] ->
                                   FStar_Pervasives_Native.Some p1
                               | uu____10485 ->
                                   FStar_Errors.raise_error
                                     (FStar_Errors.Fatal_UnsupportedDisjuctivePatterns,
                                       "Disjunctive patterns are not supported in abstractions")
                                     p.FStar_Parser_AST.prange
                                in
                             let uu____10494 =
                               match b with
                               | LetBinder uu____10535 ->
                                   failwith "Impossible"
                               | LocalBinder (x,aq) ->
                                   let sc_pat_opt1 =
                                     match (pat1, sc_pat_opt) with
                                     | (FStar_Pervasives_Native.None
                                        ,uu____10604) -> sc_pat_opt
                                     | (FStar_Pervasives_Native.Some
                                        p1,FStar_Pervasives_Native.None ) ->
                                         let uu____10658 =
                                           let uu____10667 =
                                             FStar_Syntax_Syntax.bv_to_name x
                                              in
                                           (uu____10667, p1)  in
                                         FStar_Pervasives_Native.Some
                                           uu____10658
                                     | (FStar_Pervasives_Native.Some
                                        p1,FStar_Pervasives_Native.Some
                                        (sc,p')) ->
                                         (match ((sc.FStar_Syntax_Syntax.n),
                                                  (p'.FStar_Syntax_Syntax.v))
                                          with
                                          | (FStar_Syntax_Syntax.Tm_name
                                             uu____10729,uu____10730) ->
                                              let tup2 =
                                                let uu____10732 =
                                                  FStar_Parser_Const.mk_tuple_data_lid
                                                    (Prims.of_int (2))
                                                    top.FStar_Parser_AST.range
                                                   in
                                                FStar_Syntax_Syntax.lid_as_fv
                                                  uu____10732
                                                  FStar_Syntax_Syntax.delta_constant
                                                  (FStar_Pervasives_Native.Some
                                                     FStar_Syntax_Syntax.Data_ctor)
                                                 in
                                              let sc1 =
                                                let uu____10737 =
                                                  let uu____10744 =
                                                    let uu____10745 =
                                                      let uu____10762 =
                                                        mk1
                                                          (FStar_Syntax_Syntax.Tm_fvar
                                                             tup2)
                                                         in
                                                      let uu____10765 =
                                                        let uu____10776 =
                                                          FStar_Syntax_Syntax.as_arg
                                                            sc
                                                           in
                                                        let uu____10785 =
                                                          let uu____10796 =
                                                            let uu____10805 =
                                                              FStar_Syntax_Syntax.bv_to_name
                                                                x
                                                               in
                                                            FStar_All.pipe_left
                                                              FStar_Syntax_Syntax.as_arg
                                                              uu____10805
                                                             in
                                                          [uu____10796]  in
                                                        uu____10776 ::
                                                          uu____10785
                                                         in
                                                      (uu____10762,
                                                        uu____10765)
                                                       in
                                                    FStar_Syntax_Syntax.Tm_app
                                                      uu____10745
                                                     in
                                                  FStar_Syntax_Syntax.mk
                                                    uu____10744
                                                   in
                                                uu____10737
                                                  FStar_Pervasives_Native.None
                                                  top.FStar_Parser_AST.range
                                                 in
                                              let p2 =
                                                let uu____10853 =
                                                  FStar_Range.union_ranges
                                                    p'.FStar_Syntax_Syntax.p
                                                    p1.FStar_Syntax_Syntax.p
                                                   in
                                                FStar_Syntax_Syntax.withinfo
                                                  (FStar_Syntax_Syntax.Pat_cons
                                                     (tup2,
                                                       [(p', false);
                                                       (p1, false)]))
                                                  uu____10853
                                                 in
                                              FStar_Pervasives_Native.Some
                                                (sc1, p2)
                                          | (FStar_Syntax_Syntax.Tm_app
                                             (uu____10904,args),FStar_Syntax_Syntax.Pat_cons
                                             (uu____10906,pats)) ->
                                              let tupn =
                                                let uu____10951 =
                                                  FStar_Parser_Const.mk_tuple_data_lid
                                                    (Prims.int_one +
                                                       (FStar_List.length
                                                          args))
                                                    top.FStar_Parser_AST.range
                                                   in
                                                FStar_Syntax_Syntax.lid_as_fv
                                                  uu____10951
                                                  FStar_Syntax_Syntax.delta_constant
                                                  (FStar_Pervasives_Native.Some
                                                     FStar_Syntax_Syntax.Data_ctor)
                                                 in
                                              let sc1 =
                                                let uu____10964 =
                                                  let uu____10965 =
                                                    let uu____10982 =
                                                      mk1
                                                        (FStar_Syntax_Syntax.Tm_fvar
                                                           tupn)
                                                       in
                                                    let uu____10985 =
                                                      let uu____10996 =
                                                        let uu____11007 =
                                                          let uu____11016 =
                                                            FStar_Syntax_Syntax.bv_to_name
                                                              x
                                                             in
                                                          FStar_All.pipe_left
                                                            FStar_Syntax_Syntax.as_arg
                                                            uu____11016
                                                           in
                                                        [uu____11007]  in
                                                      FStar_List.append args
                                                        uu____10996
                                                       in
                                                    (uu____10982,
                                                      uu____10985)
                                                     in
                                                  FStar_Syntax_Syntax.Tm_app
                                                    uu____10965
                                                   in
                                                mk1 uu____10964  in
                                              let p2 =
                                                let uu____11064 =
                                                  FStar_Range.union_ranges
                                                    p'.FStar_Syntax_Syntax.p
                                                    p1.FStar_Syntax_Syntax.p
                                                   in
                                                FStar_Syntax_Syntax.withinfo
                                                  (FStar_Syntax_Syntax.Pat_cons
                                                     (tupn,
                                                       (FStar_List.append
                                                          pats [(p1, false)])))
                                                  uu____11064
                                                 in
                                              FStar_Pervasives_Native.Some
                                                (sc1, p2)
                                          | uu____11111 ->
                                              failwith "Impossible")
                                      in
                                   ((x, aq), sc_pat_opt1)
                                in
                             (match uu____10494 with
                              | (b1,sc_pat_opt1) ->
                                  aux env2 (b1 :: bs) sc_pat_opt1 rest))
                     in
                  aux env [] FStar_Pervasives_Native.None binders2))
        | FStar_Parser_AST.App
            (uu____11205,uu____11206,FStar_Parser_AST.UnivApp ) ->
            let rec aux universes e =
              let uu____11228 =
                let uu____11229 = unparen e  in
                uu____11229.FStar_Parser_AST.tm  in
              match uu____11228 with
              | FStar_Parser_AST.App (e1,t,FStar_Parser_AST.UnivApp ) ->
                  let univ_arg = desugar_universe t  in
                  aux (univ_arg :: universes) e1
              | uu____11239 ->
                  let uu____11240 = desugar_term_aq env e  in
                  (match uu____11240 with
                   | (head1,aq) ->
                       let uu____11253 =
                         mk1
                           (FStar_Syntax_Syntax.Tm_uinst (head1, universes))
                          in
                       (uu____11253, aq))
               in
            aux [] top
        | FStar_Parser_AST.App uu____11260 ->
            let rec aux args aqs e =
              let uu____11337 =
                let uu____11338 = unparen e  in
                uu____11338.FStar_Parser_AST.tm  in
              match uu____11337 with
              | FStar_Parser_AST.App (e1,t,imp) when
                  imp <> FStar_Parser_AST.UnivApp ->
                  let uu____11356 = desugar_term_aq env t  in
                  (match uu____11356 with
                   | (t1,aq) ->
                       let arg = arg_withimp_e imp t1  in
                       aux (arg :: args) (aq :: aqs) e1)
              | uu____11404 ->
                  let uu____11405 = desugar_term_aq env e  in
                  (match uu____11405 with
                   | (head1,aq) ->
                       let uu____11426 =
                         mk1 (FStar_Syntax_Syntax.Tm_app (head1, args))  in
                       (uu____11426, (join_aqs (aq :: aqs))))
               in
            aux [] [] top
        | FStar_Parser_AST.Bind (x,t1,t2) ->
            let xpat =
              FStar_Parser_AST.mk_pattern
                (FStar_Parser_AST.PatVar (x, FStar_Pervasives_Native.None))
                x.FStar_Ident.idRange
               in
            let k =
              FStar_Parser_AST.mk_term (FStar_Parser_AST.Abs ([xpat], t2))
                t2.FStar_Parser_AST.range t2.FStar_Parser_AST.level
               in
            let bind_lid =
              FStar_Ident.lid_of_path ["bind"] x.FStar_Ident.idRange  in
            let bind1 =
              FStar_Parser_AST.mk_term (FStar_Parser_AST.Var bind_lid)
                x.FStar_Ident.idRange FStar_Parser_AST.Expr
               in
            let uu____11489 =
              FStar_Parser_AST.mkExplicitApp bind1 [t1; k]
                top.FStar_Parser_AST.range
               in
            desugar_term_aq env uu____11489
        | FStar_Parser_AST.Seq (t1,t2) ->
            let t =
              FStar_Parser_AST.mk_term
                (FStar_Parser_AST.Let
                   (FStar_Parser_AST.NoLetQualifier,
                     [(FStar_Pervasives_Native.None,
                        ((FStar_Parser_AST.mk_pattern
                            (FStar_Parser_AST.PatWild
                               FStar_Pervasives_Native.None)
                            t1.FStar_Parser_AST.range), t1))], t2))
                top.FStar_Parser_AST.range FStar_Parser_AST.Expr
               in
            let uu____11541 = desugar_term_aq env t  in
            (match uu____11541 with
             | (tm,s) ->
                 let uu____11552 =
                   mk1
                     (FStar_Syntax_Syntax.Tm_meta
                        (tm,
                          (FStar_Syntax_Syntax.Meta_desugared
                             FStar_Syntax_Syntax.Sequence)))
                    in
                 (uu____11552, s))
        | FStar_Parser_AST.LetOpen (lid,e) ->
            let env1 = FStar_Syntax_DsEnv.push_namespace env lid  in
            let uu____11558 =
              let uu____11571 = FStar_Syntax_DsEnv.expect_typ env1  in
              if uu____11571 then desugar_typ_aq else desugar_term_aq  in
            uu____11558 env1 e
        | FStar_Parser_AST.Let (qual,lbs,body) ->
            let is_rec = qual = FStar_Parser_AST.Rec  in
            let ds_let_rec_or_app uu____11638 =
              let bindings = lbs  in
              let funs =
                FStar_All.pipe_right bindings
                  (FStar_List.map
                     (fun uu____11781  ->
                        match uu____11781 with
                        | (attr_opt,(p,def)) ->
                            let uu____11839 = is_app_pattern p  in
                            if uu____11839
                            then
                              let uu____11872 =
                                destruct_app_pattern env top_level p  in
                              (attr_opt, uu____11872, def)
                            else
                              (match FStar_Parser_AST.un_function p def with
                               | FStar_Pervasives_Native.Some (p1,def1) ->
                                   let uu____11955 =
                                     destruct_app_pattern env top_level p1
                                      in
                                   (attr_opt, uu____11955, def1)
                               | uu____12000 ->
                                   (match p.FStar_Parser_AST.pat with
                                    | FStar_Parser_AST.PatAscribed
                                        ({
                                           FStar_Parser_AST.pat =
                                             FStar_Parser_AST.PatVar
                                             (id1,uu____12038);
                                           FStar_Parser_AST.prange =
                                             uu____12039;_},t)
                                        ->
                                        if top_level
                                        then
                                          let uu____12088 =
                                            let uu____12109 =
                                              let uu____12114 =
                                                FStar_Syntax_DsEnv.qualify
                                                  env id1
                                                 in
                                              FStar_Util.Inr uu____12114  in
                                            (uu____12109, [],
                                              (FStar_Pervasives_Native.Some t))
                                             in
                                          (attr_opt, uu____12088, def)
                                        else
                                          (attr_opt,
                                            ((FStar_Util.Inl id1), [],
                                              (FStar_Pervasives_Native.Some t)),
                                            def)
                                    | FStar_Parser_AST.PatVar
                                        (id1,uu____12206) ->
                                        if top_level
                                        then
                                          let uu____12242 =
                                            let uu____12263 =
                                              let uu____12268 =
                                                FStar_Syntax_DsEnv.qualify
                                                  env id1
                                                 in
                                              FStar_Util.Inr uu____12268  in
                                            (uu____12263, [],
                                              FStar_Pervasives_Native.None)
                                             in
                                          (attr_opt, uu____12242, def)
                                        else
                                          (attr_opt,
                                            ((FStar_Util.Inl id1), [],
                                              FStar_Pervasives_Native.None),
                                            def)
                                    | uu____12359 ->
                                        FStar_Errors.raise_error
                                          (FStar_Errors.Fatal_UnexpectedLetBinding,
                                            "Unexpected let binding")
                                          p.FStar_Parser_AST.prange))))
                 in
              let uu____12392 =
                FStar_List.fold_left
                  (fun uu____12481  ->
                     fun uu____12482  ->
                       match (uu____12481, uu____12482) with
                       | ((env1,fnames,rec_bindings,used_markers),(_attr_opt,
                                                                   (f,uu____12612,uu____12613),uu____12614))
                           ->
                           let uu____12748 =
                             match f with
                             | FStar_Util.Inl x ->
                                 let uu____12788 =
                                   FStar_Syntax_DsEnv.push_bv' env1 x  in
                                 (match uu____12788 with
                                  | (env2,xx,used_marker) ->
                                      let dummy_ref = FStar_Util.mk_ref true
                                         in
                                      let uu____12823 =
                                        let uu____12826 =
                                          FStar_Syntax_Syntax.mk_binder xx
                                           in
                                        uu____12826 :: rec_bindings  in
                                      (env2, (FStar_Util.Inl xx),
                                        uu____12823, (used_marker ::
                                        used_markers)))
                             | FStar_Util.Inr l ->
                                 let uu____12842 =
                                   FStar_Syntax_DsEnv.push_top_level_rec_binding
                                     env1 l.FStar_Ident.ident
                                     FStar_Syntax_Syntax.delta_equational
                                    in
                                 (match uu____12842 with
                                  | (env2,used_marker) ->
                                      (env2, (FStar_Util.Inr l),
                                        rec_bindings, (used_marker ::
                                        used_markers)))
                              in
                           (match uu____12748 with
                            | (env2,lbname,rec_bindings1,used_markers1) ->
                                (env2, (lbname :: fnames), rec_bindings1,
                                  used_markers1))) (env, [], [], []) funs
                 in
              match uu____12392 with
              | (env',fnames,rec_bindings,used_markers) ->
                  let fnames1 = FStar_List.rev fnames  in
                  let rec_bindings1 = FStar_List.rev rec_bindings  in
                  let used_markers1 = FStar_List.rev used_markers  in
                  let desugar_one_def env1 lbname uu____13095 =
                    match uu____13095 with
                    | (attrs_opt,(uu____13135,args,result_t),def) ->
                        let args1 =
                          FStar_All.pipe_right args
                            (FStar_List.map replace_unit_pattern)
                           in
                        let pos = def.FStar_Parser_AST.range  in
                        let def1 =
                          match result_t with
                          | FStar_Pervasives_Native.None  -> def
                          | FStar_Pervasives_Native.Some (t,tacopt) ->
                              let t1 =
                                let uu____13227 = is_comp_type env1 t  in
                                if uu____13227
                                then
                                  ((let uu____13231 =
                                      FStar_All.pipe_right args1
                                        (FStar_List.tryFind
                                           (fun x  ->
                                              let uu____13241 =
                                                is_var_pattern x  in
                                              Prims.op_Negation uu____13241))
                                       in
                                    match uu____13231 with
                                    | FStar_Pervasives_Native.None  -> ()
                                    | FStar_Pervasives_Native.Some p ->
                                        FStar_Errors.raise_error
                                          (FStar_Errors.Fatal_ComputationTypeNotAllowed,
                                            "Computation type annotations are only permitted on let-bindings without inlined patterns; replace this pattern with a variable")
                                          p.FStar_Parser_AST.prange);
                                   t)
                                else
                                  (let uu____13248 =
                                     ((FStar_Options.ml_ish ()) &&
                                        (let uu____13251 =
                                           FStar_Syntax_DsEnv.try_lookup_effect_name
                                             env1
                                             FStar_Parser_Const.effect_ML_lid
                                            in
                                         FStar_Option.isSome uu____13251))
                                       &&
                                       ((Prims.op_Negation is_rec) ||
                                          ((FStar_List.length args1) <>
                                             Prims.int_zero))
                                      in
                                   if uu____13248
                                   then FStar_Parser_AST.ml_comp t
                                   else FStar_Parser_AST.tot_comp t)
                                 in
                              FStar_Parser_AST.mk_term
                                (FStar_Parser_AST.Ascribed (def, t1, tacopt))
                                def.FStar_Parser_AST.range
                                FStar_Parser_AST.Expr
                           in
                        let def2 =
                          match args1 with
                          | [] -> def1
                          | uu____13262 ->
                              FStar_Parser_AST.mk_term
                                (FStar_Parser_AST.un_curry_abs args1 def1)
                                top.FStar_Parser_AST.range
                                top.FStar_Parser_AST.level
                           in
                        let uu____13265 = desugar_term_aq env1 def2  in
                        (match uu____13265 with
                         | (body1,aq) ->
                             let lbname1 =
                               match lbname with
                               | FStar_Util.Inl x -> FStar_Util.Inl x
                               | FStar_Util.Inr l ->
                                   let uu____13287 =
                                     let uu____13288 =
                                       FStar_Syntax_Util.incr_delta_qualifier
                                         body1
                                        in
                                     FStar_Syntax_Syntax.lid_as_fv l
                                       uu____13288
                                       FStar_Pervasives_Native.None
                                      in
                                   FStar_Util.Inr uu____13287
                                in
                             let body2 =
                               if is_rec
                               then
                                 FStar_Syntax_Subst.close rec_bindings1 body1
                               else body1  in
                             let attrs =
                               match attrs_opt with
                               | FStar_Pervasives_Native.None  -> []
                               | FStar_Pervasives_Native.Some l ->
                                   FStar_List.map (desugar_term env1) l
                                in
                             ((mk_lb
                                 (attrs, lbname1, FStar_Syntax_Syntax.tun,
                                   body2, pos)), aq))
                     in
                  let uu____13329 =
                    let uu____13346 =
                      FStar_List.map2
                        (desugar_one_def (if is_rec then env' else env))
                        fnames1 funs
                       in
                    FStar_All.pipe_right uu____13346 FStar_List.unzip  in
                  (match uu____13329 with
                   | (lbs1,aqss) ->
                       let uu____13488 = desugar_term_aq env' body  in
                       (match uu____13488 with
                        | (body1,aq) ->
                            (if is_rec
                             then
                               FStar_List.iter2
                                 (fun uu____13594  ->
                                    fun used_marker  ->
                                      match uu____13594 with
                                      | (_attr_opt,(f,uu____13668,uu____13669),uu____13670)
                                          ->
                                          let uu____13727 =
                                            let uu____13729 =
                                              FStar_ST.op_Bang used_marker
                                               in
                                            Prims.op_Negation uu____13729  in
                                          if uu____13727
                                          then
                                            let uu____13753 =
                                              match f with
                                              | FStar_Util.Inl x ->
                                                  let uu____13771 =
                                                    FStar_Ident.string_of_ident
                                                      x
                                                     in
                                                  let uu____13773 =
                                                    FStar_Ident.range_of_id x
                                                     in
                                                  (uu____13771, "Local",
                                                    uu____13773)
                                              | FStar_Util.Inr l ->
                                                  let uu____13778 =
                                                    FStar_Ident.string_of_lid
                                                      l
                                                     in
                                                  let uu____13780 =
                                                    FStar_Ident.range_of_lid
                                                      l
                                                     in
                                                  (uu____13778, "Global",
                                                    uu____13780)
                                               in
                                            (match uu____13753 with
                                             | (nm,gl,rng) ->
                                                 let uu____13791 =
                                                   let uu____13797 =
                                                     FStar_Util.format2
                                                       "%s binding %s is recursive but not used in its body"
                                                       gl nm
                                                      in
                                                   (FStar_Errors.Warning_UnusedLetRec,
                                                     uu____13797)
                                                    in
                                                 FStar_Errors.log_issue rng
                                                   uu____13791)
                                          else ()) funs used_markers1
                             else ();
                             (let uu____13805 =
                                let uu____13808 =
                                  let uu____13809 =
                                    let uu____13823 =
                                      FStar_Syntax_Subst.close rec_bindings1
                                        body1
                                       in
                                    ((is_rec, lbs1), uu____13823)  in
                                  FStar_Syntax_Syntax.Tm_let uu____13809  in
                                FStar_All.pipe_left mk1 uu____13808  in
                              (uu____13805,
                                (FStar_List.append aq
                                   (FStar_List.flatten aqss)))))))
               in
            let ds_non_rec attrs_opt pat t1 t2 =
              let attrs =
                match attrs_opt with
                | FStar_Pervasives_Native.None  -> []
                | FStar_Pervasives_Native.Some l ->
                    FStar_List.map (desugar_term env) l
                 in
              let uu____13925 = desugar_term_aq env t1  in
              match uu____13925 with
              | (t11,aq0) ->
                  let uu____13946 =
                    desugar_binding_pat_maybe_top top_level env pat  in
                  (match uu____13946 with
                   | (env1,binder,pat1) ->
                       let uu____13976 =
                         match binder with
                         | LetBinder (l,(t,_tacopt)) ->
                             let uu____14018 = desugar_term_aq env1 t2  in
                             (match uu____14018 with
                              | (body1,aq) ->
                                  let fv =
                                    let uu____14040 =
                                      FStar_Syntax_Util.incr_delta_qualifier
                                        t11
                                       in
                                    FStar_Syntax_Syntax.lid_as_fv l
                                      uu____14040
                                      FStar_Pervasives_Native.None
                                     in
                                  let uu____14041 =
                                    FStar_All.pipe_left mk1
                                      (FStar_Syntax_Syntax.Tm_let
                                         ((false,
                                            [mk_lb
                                               (attrs, (FStar_Util.Inr fv),
                                                 t, t11,
                                                 (t11.FStar_Syntax_Syntax.pos))]),
                                           body1))
                                     in
                                  (uu____14041, aq))
                         | LocalBinder (x,uu____14082) ->
                             let uu____14083 = desugar_term_aq env1 t2  in
                             (match uu____14083 with
                              | (body1,aq) ->
                                  let body2 =
                                    match pat1 with
                                    | [] -> body1
                                    | ({
                                         FStar_Syntax_Syntax.v =
                                           FStar_Syntax_Syntax.Pat_wild
                                           uu____14105;
                                         FStar_Syntax_Syntax.p = uu____14106;_},uu____14107)::[]
                                        -> body1
                                    | uu____14120 ->
                                        let uu____14123 =
                                          let uu____14130 =
                                            let uu____14131 =
                                              let uu____14154 =
                                                FStar_Syntax_Syntax.bv_to_name
                                                  x
                                                 in
                                              let uu____14157 =
                                                desugar_disjunctive_pattern
                                                  pat1
                                                  FStar_Pervasives_Native.None
                                                  body1
                                                 in
                                              (uu____14154, uu____14157)  in
                                            FStar_Syntax_Syntax.Tm_match
                                              uu____14131
                                             in
                                          FStar_Syntax_Syntax.mk uu____14130
                                           in
                                        uu____14123
                                          FStar_Pervasives_Native.None
                                          top.FStar_Parser_AST.range
                                     in
                                  let uu____14194 =
                                    let uu____14197 =
                                      let uu____14198 =
                                        let uu____14212 =
                                          let uu____14215 =
                                            let uu____14216 =
                                              FStar_Syntax_Syntax.mk_binder x
                                               in
                                            [uu____14216]  in
                                          FStar_Syntax_Subst.close
                                            uu____14215 body2
                                           in
                                        ((false,
                                           [mk_lb
                                              (attrs, (FStar_Util.Inl x),
                                                (x.FStar_Syntax_Syntax.sort),
                                                t11,
                                                (t11.FStar_Syntax_Syntax.pos))]),
                                          uu____14212)
                                         in
                                      FStar_Syntax_Syntax.Tm_let uu____14198
                                       in
                                    FStar_All.pipe_left mk1 uu____14197  in
                                  (uu____14194, aq))
                          in
                       (match uu____13976 with
                        | (tm,aq1) -> (tm, (FStar_List.append aq0 aq1))))
               in
            let uu____14324 = FStar_List.hd lbs  in
            (match uu____14324 with
             | (attrs,(head_pat,defn)) ->
                 let uu____14368 = is_rec || (is_app_pattern head_pat)  in
                 if uu____14368
                 then ds_let_rec_or_app ()
                 else ds_non_rec attrs head_pat defn body)
        | FStar_Parser_AST.If (t1,t2,t3) ->
            let x =
              FStar_Syntax_Syntax.new_bv
                (FStar_Pervasives_Native.Some (t3.FStar_Parser_AST.range))
                FStar_Syntax_Syntax.tun
               in
            let t_bool1 =
              let uu____14384 =
                let uu____14385 =
                  FStar_Syntax_Syntax.lid_as_fv FStar_Parser_Const.bool_lid
                    FStar_Syntax_Syntax.delta_constant
                    FStar_Pervasives_Native.None
                   in
                FStar_Syntax_Syntax.Tm_fvar uu____14385  in
              mk1 uu____14384  in
            let uu____14386 = desugar_term_aq env t1  in
            (match uu____14386 with
             | (t1',aq1) ->
                 let uu____14397 = desugar_term_aq env t2  in
                 (match uu____14397 with
                  | (t2',aq2) ->
                      let uu____14408 = desugar_term_aq env t3  in
                      (match uu____14408 with
                       | (t3',aq3) ->
                           let uu____14419 =
                             let uu____14420 =
                               let uu____14421 =
                                 let uu____14444 =
                                   let uu____14461 =
                                     let uu____14476 =
                                       FStar_Syntax_Syntax.withinfo
                                         (FStar_Syntax_Syntax.Pat_constant
                                            (FStar_Const.Const_bool true))
                                         t1.FStar_Parser_AST.range
                                        in
                                     (uu____14476,
                                       FStar_Pervasives_Native.None, t2')
                                      in
                                   let uu____14490 =
                                     let uu____14507 =
                                       let uu____14522 =
                                         FStar_Syntax_Syntax.withinfo
                                           (FStar_Syntax_Syntax.Pat_wild x)
                                           t1.FStar_Parser_AST.range
                                          in
                                       (uu____14522,
                                         FStar_Pervasives_Native.None, t3')
                                        in
                                     [uu____14507]  in
                                   uu____14461 :: uu____14490  in
                                 (t1', uu____14444)  in
                               FStar_Syntax_Syntax.Tm_match uu____14421  in
                             mk1 uu____14420  in
                           (uu____14419, (join_aqs [aq1; aq2; aq3])))))
        | FStar_Parser_AST.TryWith (e,branches) ->
            let r = top.FStar_Parser_AST.range  in
            let handler = FStar_Parser_AST.mk_function branches r r  in
            let body =
              FStar_Parser_AST.mk_function
                [((FStar_Parser_AST.mk_pattern
                     (FStar_Parser_AST.PatConst FStar_Const.Const_unit) r),
                   FStar_Pervasives_Native.None, e)] r r
               in
            let try_with_lid1 = FStar_Ident.lid_of_path ["try_with"] r  in
            let try_with1 =
              FStar_Parser_AST.mk_term (FStar_Parser_AST.Var try_with_lid1) r
                FStar_Parser_AST.Expr
               in
            let a1 =
              FStar_Parser_AST.mk_term
                (FStar_Parser_AST.App
                   (try_with1, body, FStar_Parser_AST.Nothing)) r
                top.FStar_Parser_AST.level
               in
            let a2 =
              FStar_Parser_AST.mk_term
                (FStar_Parser_AST.App (a1, handler, FStar_Parser_AST.Nothing))
                r top.FStar_Parser_AST.level
               in
            desugar_term_aq env a2
        | FStar_Parser_AST.Match (e,branches) ->
            let desugar_branch uu____14718 =
              match uu____14718 with
              | (pat,wopt,b) ->
                  let uu____14740 = desugar_match_pat env pat  in
                  (match uu____14740 with
                   | (env1,pat1) ->
                       let wopt1 =
                         match wopt with
                         | FStar_Pervasives_Native.None  ->
                             FStar_Pervasives_Native.None
                         | FStar_Pervasives_Native.Some e1 ->
                             let uu____14771 = desugar_term env1 e1  in
                             FStar_Pervasives_Native.Some uu____14771
                          in
                       let uu____14776 = desugar_term_aq env1 b  in
                       (match uu____14776 with
                        | (b1,aq) ->
                            let uu____14789 =
                              desugar_disjunctive_pattern pat1 wopt1 b1  in
                            (uu____14789, aq)))
               in
            let uu____14794 = desugar_term_aq env e  in
            (match uu____14794 with
             | (e1,aq) ->
                 let uu____14805 =
                   let uu____14836 =
                     let uu____14869 = FStar_List.map desugar_branch branches
                        in
                     FStar_All.pipe_right uu____14869 FStar_List.unzip  in
                   FStar_All.pipe_right uu____14836
                     (fun uu____15087  ->
                        match uu____15087 with
                        | (x,y) -> ((FStar_List.flatten x), y))
                    in
                 (match uu____14805 with
                  | (brs,aqs) ->
                      let uu____15306 =
                        FStar_All.pipe_left mk1
                          (FStar_Syntax_Syntax.Tm_match (e1, brs))
                         in
                      (uu____15306, (join_aqs (aq :: aqs)))))
        | FStar_Parser_AST.Ascribed (e,t,tac_opt) ->
            let uu____15340 =
              let uu____15361 = is_comp_type env t  in
              if uu____15361
              then
                let comp = desugar_comp t.FStar_Parser_AST.range true env t
                   in
                ((FStar_Util.Inr comp), [])
              else
                (let uu____15416 = desugar_term_aq env t  in
                 match uu____15416 with
                 | (tm,aq) -> ((FStar_Util.Inl tm), aq))
               in
            (match uu____15340 with
             | (annot,aq0) ->
                 let tac_opt1 = FStar_Util.map_opt tac_opt (desugar_term env)
                    in
                 let uu____15508 = desugar_term_aq env e  in
                 (match uu____15508 with
                  | (e1,aq) ->
                      let uu____15519 =
                        FStar_All.pipe_left mk1
                          (FStar_Syntax_Syntax.Tm_ascribed
                             (e1, (annot, tac_opt1),
                               FStar_Pervasives_Native.None))
                         in
                      (uu____15519, (FStar_List.append aq0 aq))))
        | FStar_Parser_AST.Record (uu____15558,[]) ->
            FStar_Errors.raise_error
              (FStar_Errors.Fatal_UnexpectedEmptyRecord,
                "Unexpected empty record") top.FStar_Parser_AST.range
        | FStar_Parser_AST.Record (eopt,fields) ->
            let record = check_fields env fields top.FStar_Parser_AST.range
               in
            let user_ns =
              let uu____15601 = FStar_List.hd fields  in
              match uu____15601 with | (f,uu____15613) -> f.FStar_Ident.ns
               in
            let get_field xopt f =
              let found =
                FStar_All.pipe_right fields
                  (FStar_Util.find_opt
                     (fun uu____15659  ->
                        match uu____15659 with
                        | (g,uu____15666) ->
                            f.FStar_Ident.idText =
                              (g.FStar_Ident.ident).FStar_Ident.idText))
                 in
              let fn = FStar_Ident.lid_of_ids (FStar_List.append user_ns [f])
                 in
              match found with
              | FStar_Pervasives_Native.Some (uu____15673,e) -> (fn, e)
              | FStar_Pervasives_Native.None  ->
                  (match xopt with
                   | FStar_Pervasives_Native.None  ->
                       let uu____15687 =
                         let uu____15693 =
                           FStar_Util.format2
                             "Field %s of record type %s is missing"
                             f.FStar_Ident.idText
                             (record.FStar_Syntax_DsEnv.typename).FStar_Ident.str
                            in
                         (FStar_Errors.Fatal_MissingFieldInRecord,
                           uu____15693)
                          in
                       FStar_Errors.raise_error uu____15687
                         top.FStar_Parser_AST.range
                   | FStar_Pervasives_Native.Some x ->
                       (fn,
                         (FStar_Parser_AST.mk_term
                            (FStar_Parser_AST.Project (x, fn))
                            x.FStar_Parser_AST.range x.FStar_Parser_AST.level)))
               in
            let user_constrname =
              FStar_Ident.lid_of_ids
                (FStar_List.append user_ns
                   [record.FStar_Syntax_DsEnv.constrname])
               in
            let recterm =
              match eopt with
              | FStar_Pervasives_Native.None  ->
                  let uu____15704 =
                    let uu____15715 =
                      FStar_All.pipe_right record.FStar_Syntax_DsEnv.fields
                        (FStar_List.map
                           (fun uu____15746  ->
                              match uu____15746 with
                              | (f,uu____15756) ->
                                  let uu____15757 =
                                    let uu____15758 =
                                      get_field FStar_Pervasives_Native.None
                                        f
                                       in
                                    FStar_All.pipe_left
                                      FStar_Pervasives_Native.snd uu____15758
                                     in
                                  (uu____15757, FStar_Parser_AST.Nothing)))
                       in
                    (user_constrname, uu____15715)  in
                  FStar_Parser_AST.Construct uu____15704
              | FStar_Pervasives_Native.Some e ->
                  let x = FStar_Ident.gen e.FStar_Parser_AST.range  in
                  let xterm =
                    let uu____15776 =
                      let uu____15777 = FStar_Ident.lid_of_ids [x]  in
                      FStar_Parser_AST.Var uu____15777  in
                    FStar_Parser_AST.mk_term uu____15776
                      x.FStar_Ident.idRange FStar_Parser_AST.Expr
                     in
                  let record1 =
                    let uu____15779 =
                      let uu____15792 =
                        FStar_All.pipe_right record.FStar_Syntax_DsEnv.fields
                          (FStar_List.map
                             (fun uu____15822  ->
                                match uu____15822 with
                                | (f,uu____15832) ->
                                    get_field
                                      (FStar_Pervasives_Native.Some xterm) f))
                         in
                      (FStar_Pervasives_Native.None, uu____15792)  in
                    FStar_Parser_AST.Record uu____15779  in
                  FStar_Parser_AST.Let
                    (FStar_Parser_AST.NoLetQualifier,
                      [(FStar_Pervasives_Native.None,
                         ((FStar_Parser_AST.mk_pattern
                             (FStar_Parser_AST.PatVar
                                (x, FStar_Pervasives_Native.None))
                             x.FStar_Ident.idRange), e))],
                      (FStar_Parser_AST.mk_term record1
                         top.FStar_Parser_AST.range
                         top.FStar_Parser_AST.level))
               in
            let recterm1 =
              FStar_Parser_AST.mk_term recterm top.FStar_Parser_AST.range
                top.FStar_Parser_AST.level
               in
            let uu____15892 = desugar_term_aq env recterm1  in
            (match uu____15892 with
             | (e,s) ->
                 (match e.FStar_Syntax_Syntax.n with
                  | FStar_Syntax_Syntax.Tm_app
                      ({
                         FStar_Syntax_Syntax.n = FStar_Syntax_Syntax.Tm_fvar
                           fv;
                         FStar_Syntax_Syntax.pos = uu____15908;
                         FStar_Syntax_Syntax.vars = uu____15909;_},args)
                      ->
                      let uu____15935 =
                        let uu____15936 =
                          let uu____15937 =
                            let uu____15954 =
                              let uu____15957 =
                                FStar_Ident.set_lid_range
                                  (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v
                                  e.FStar_Syntax_Syntax.pos
                                 in
                              let uu____15958 =
                                let uu____15961 =
                                  let uu____15962 =
                                    let uu____15969 =
                                      FStar_All.pipe_right
                                        record.FStar_Syntax_DsEnv.fields
                                        (FStar_List.map
                                           FStar_Pervasives_Native.fst)
                                       in
                                    ((record.FStar_Syntax_DsEnv.typename),
                                      uu____15969)
                                     in
                                  FStar_Syntax_Syntax.Record_ctor uu____15962
                                   in
                                FStar_Pervasives_Native.Some uu____15961  in
                              FStar_Syntax_Syntax.fvar uu____15957
                                FStar_Syntax_Syntax.delta_constant
                                uu____15958
                               in
                            (uu____15954, args)  in
                          FStar_Syntax_Syntax.Tm_app uu____15937  in
                        FStar_All.pipe_left mk1 uu____15936  in
                      (uu____15935, s)
                  | uu____15998 -> (e, s)))
        | FStar_Parser_AST.Project (e,f) ->
            (FStar_Syntax_DsEnv.fail_if_qualified_by_curmodule env f;
             (let uu____16002 =
                FStar_Syntax_DsEnv.fail_or env
                  (FStar_Syntax_DsEnv.try_lookup_dc_by_field_name env) f
                 in
              match uu____16002 with
              | (constrname,is_rec) ->
                  let uu____16021 = desugar_term_aq env e  in
                  (match uu____16021 with
                   | (e1,s) ->
                       let projname =
                         FStar_Syntax_Util.mk_field_projector_name_from_ident
                           constrname f.FStar_Ident.ident
                          in
                       let qual =
                         if is_rec
                         then
                           FStar_Pervasives_Native.Some
                             (FStar_Syntax_Syntax.Record_projector
                                (constrname, (f.FStar_Ident.ident)))
                         else FStar_Pervasives_Native.None  in
                       let uu____16041 =
                         let uu____16042 =
                           let uu____16043 =
                             let uu____16060 =
                               let uu____16063 =
                                 let uu____16064 = FStar_Ident.range_of_lid f
                                    in
                                 FStar_Ident.set_lid_range projname
                                   uu____16064
                                  in
                               FStar_Syntax_Syntax.fvar uu____16063
                                 (FStar_Syntax_Syntax.Delta_equational_at_level
                                    Prims.int_one) qual
                                in
                             let uu____16066 =
                               let uu____16077 =
                                 FStar_Syntax_Syntax.as_arg e1  in
                               [uu____16077]  in
                             (uu____16060, uu____16066)  in
                           FStar_Syntax_Syntax.Tm_app uu____16043  in
                         FStar_All.pipe_left mk1 uu____16042  in
                       (uu____16041, s))))
        | FStar_Parser_AST.NamedTyp (n1,uu____16115) ->
            let uu____16116 = FStar_Ident.range_of_id n1  in
            FStar_Errors.raise_error
              (FStar_Errors.Fatal_SyntaxError, "Syntax error") uu____16116
        | FStar_Parser_AST.Paren e -> failwith "impossible"
        | FStar_Parser_AST.VQuote e ->
            let tm = desugar_term env e  in
            let uu____16131 =
              let uu____16132 = FStar_Syntax_Subst.compress tm  in
              uu____16132.FStar_Syntax_Syntax.n  in
            (match uu____16131 with
             | FStar_Syntax_Syntax.Tm_fvar fv ->
                 let uu____16140 =
                   let uu___2115_16141 =
                     let uu____16142 =
                       let uu____16144 = FStar_Syntax_Syntax.lid_of_fv fv  in
                       FStar_Ident.string_of_lid uu____16144  in
                     FStar_Syntax_Util.exp_string uu____16142  in
                   {
                     FStar_Syntax_Syntax.n =
                       (uu___2115_16141.FStar_Syntax_Syntax.n);
                     FStar_Syntax_Syntax.pos = (e.FStar_Parser_AST.range);
                     FStar_Syntax_Syntax.vars =
                       (uu___2115_16141.FStar_Syntax_Syntax.vars)
                   }  in
                 (uu____16140, noaqs)
             | uu____16145 ->
                 let uu____16146 =
                   let uu____16152 =
                     let uu____16154 = FStar_Syntax_Print.term_to_string tm
                        in
                     Prims.op_Hat "VQuote, expected an fvar, got: "
                       uu____16154
                      in
                   (FStar_Errors.Fatal_UnexpectedTermVQuote, uu____16152)  in
                 FStar_Errors.raise_error uu____16146
                   top.FStar_Parser_AST.range)
        | FStar_Parser_AST.Quote (e,FStar_Parser_AST.Static ) ->
            let uu____16163 = desugar_term_aq env e  in
            (match uu____16163 with
             | (tm,vts) ->
                 let qi =
                   {
                     FStar_Syntax_Syntax.qkind =
                       FStar_Syntax_Syntax.Quote_static;
                     FStar_Syntax_Syntax.antiquotes = vts
                   }  in
                 let uu____16175 =
                   FStar_All.pipe_left mk1
                     (FStar_Syntax_Syntax.Tm_quoted (tm, qi))
                    in
                 (uu____16175, noaqs))
        | FStar_Parser_AST.Antiquote e ->
            let bv =
              FStar_Syntax_Syntax.new_bv
                (FStar_Pervasives_Native.Some (e.FStar_Parser_AST.range))
                FStar_Syntax_Syntax.tun
               in
            let uu____16180 = FStar_Syntax_Syntax.bv_to_name bv  in
            let uu____16181 =
              let uu____16182 =
                let uu____16189 = desugar_term env e  in (bv, uu____16189)
                 in
              [uu____16182]  in
            (uu____16180, uu____16181)
        | FStar_Parser_AST.Quote (e,FStar_Parser_AST.Dynamic ) ->
            let qi =
              {
                FStar_Syntax_Syntax.qkind = FStar_Syntax_Syntax.Quote_dynamic;
                FStar_Syntax_Syntax.antiquotes = []
              }  in
            let uu____16214 =
              let uu____16215 =
                let uu____16216 =
                  let uu____16223 = desugar_term env e  in (uu____16223, qi)
                   in
                FStar_Syntax_Syntax.Tm_quoted uu____16216  in
              FStar_All.pipe_left mk1 uu____16215  in
            (uu____16214, noaqs)
        | FStar_Parser_AST.CalcProof (rel,init_expr,steps) ->
            let eta_and_annot rel1 =
              let x = FStar_Ident.gen rel1.FStar_Parser_AST.range  in
              let y = FStar_Ident.gen rel1.FStar_Parser_AST.range  in
              let xt =
                FStar_Parser_AST.mk_term (FStar_Parser_AST.Tvar x)
                  rel1.FStar_Parser_AST.range FStar_Parser_AST.Expr
                 in
              let yt =
                FStar_Parser_AST.mk_term (FStar_Parser_AST.Tvar y)
                  rel1.FStar_Parser_AST.range FStar_Parser_AST.Expr
                 in
              let pats =
                [FStar_Parser_AST.mk_pattern
                   (FStar_Parser_AST.PatVar (x, FStar_Pervasives_Native.None))
                   rel1.FStar_Parser_AST.range;
                FStar_Parser_AST.mk_pattern
                  (FStar_Parser_AST.PatVar (y, FStar_Pervasives_Native.None))
                  rel1.FStar_Parser_AST.range]
                 in
              let uu____16252 =
                let uu____16253 =
                  let uu____16260 =
                    let uu____16261 =
                      let uu____16262 =
                        let uu____16271 =
                          FStar_Parser_AST.mkApp rel1
                            [(xt, FStar_Parser_AST.Nothing);
                            (yt, FStar_Parser_AST.Nothing)]
                            rel1.FStar_Parser_AST.range
                           in
                        let uu____16284 =
                          let uu____16285 =
                            let uu____16286 = FStar_Ident.lid_of_str "Type0"
                               in
                            FStar_Parser_AST.Name uu____16286  in
                          FStar_Parser_AST.mk_term uu____16285
                            rel1.FStar_Parser_AST.range FStar_Parser_AST.Expr
                           in
                        (uu____16271, uu____16284,
                          FStar_Pervasives_Native.None)
                         in
                      FStar_Parser_AST.Ascribed uu____16262  in
                    FStar_Parser_AST.mk_term uu____16261
                      rel1.FStar_Parser_AST.range FStar_Parser_AST.Expr
                     in
                  (pats, uu____16260)  in
                FStar_Parser_AST.Abs uu____16253  in
              FStar_Parser_AST.mk_term uu____16252
                rel1.FStar_Parser_AST.range FStar_Parser_AST.Expr
               in
            let rel1 = eta_and_annot rel  in
            let wild r =
              FStar_Parser_AST.mk_term FStar_Parser_AST.Wild r
                FStar_Parser_AST.Expr
               in
            let init1 =
              FStar_Parser_AST.mk_term
                (FStar_Parser_AST.Var FStar_Parser_Const.calc_init_lid)
                FStar_Range.dummyRange FStar_Parser_AST.Expr
               in
            let last_expr =
              let uu____16301 = FStar_List.last steps  in
              match uu____16301 with
              | FStar_Pervasives_Native.Some (FStar_Parser_AST.CalcStep
                  (uu____16304,uu____16305,last_expr)) -> last_expr
              | uu____16307 -> failwith "impossible: no last_expr on calc"
               in
            let step r =
              FStar_Parser_AST.mk_term
                (FStar_Parser_AST.Var FStar_Parser_Const.calc_step_lid) r
                FStar_Parser_AST.Expr
               in
            let finish1 =
              FStar_Parser_AST.mkApp
                (FStar_Parser_AST.mk_term
                   (FStar_Parser_AST.Var FStar_Parser_Const.calc_finish_lid)
                   top.FStar_Parser_AST.range FStar_Parser_AST.Expr)
                [(rel1, FStar_Parser_AST.Nothing)] top.FStar_Parser_AST.range
               in
            let e =
              FStar_Parser_AST.mkApp init1
                [(init_expr, FStar_Parser_AST.Nothing)]
                FStar_Range.dummyRange
               in
            let uu____16335 =
              FStar_List.fold_left
                (fun uu____16352  ->
                   fun uu____16353  ->
                     match (uu____16352, uu____16353) with
                     | ((e1,prev),FStar_Parser_AST.CalcStep
                        (rel2,just,next_expr)) ->
                         let pf =
                           let uu____16376 =
                             let uu____16383 =
                               let uu____16390 =
                                 let uu____16397 =
                                   let uu____16404 =
                                     let uu____16409 = eta_and_annot rel2  in
                                     (uu____16409, FStar_Parser_AST.Nothing)
                                      in
                                   let uu____16410 =
                                     let uu____16417 =
                                       let uu____16424 =
                                         let uu____16429 =
                                           FStar_Parser_AST.thunk e1  in
                                         (uu____16429,
                                           FStar_Parser_AST.Nothing)
                                          in
                                       let uu____16430 =
                                         let uu____16437 =
                                           let uu____16442 =
                                             FStar_Parser_AST.thunk just  in
                                           (uu____16442,
                                             FStar_Parser_AST.Nothing)
                                            in
                                         [uu____16437]  in
                                       uu____16424 :: uu____16430  in
                                     (next_expr, FStar_Parser_AST.Nothing) ::
                                       uu____16417
                                      in
                                   uu____16404 :: uu____16410  in
                                 (prev, FStar_Parser_AST.Hash) :: uu____16397
                                  in
                               (init_expr, FStar_Parser_AST.Hash) ::
                                 uu____16390
                                in
                             ((wild rel2.FStar_Parser_AST.range),
                               FStar_Parser_AST.Hash) :: uu____16383
                              in
                           FStar_Parser_AST.mkApp
                             (step rel2.FStar_Parser_AST.range) uu____16376
                             FStar_Range.dummyRange
                            in
                         (pf, next_expr)) (e, init_expr) steps
               in
            (match uu____16335 with
             | (e1,uu____16480) ->
                 let e2 =
                   let uu____16482 =
                     let uu____16489 =
                       let uu____16496 =
                         let uu____16503 =
                           let uu____16508 = FStar_Parser_AST.thunk e1  in
                           (uu____16508, FStar_Parser_AST.Nothing)  in
                         [uu____16503]  in
                       (last_expr, FStar_Parser_AST.Hash) :: uu____16496  in
                     (init_expr, FStar_Parser_AST.Hash) :: uu____16489  in
                   FStar_Parser_AST.mkApp finish1 uu____16482
                     FStar_Range.dummyRange
                    in
                 desugar_term_maybe_top top_level env e2)
        | uu____16525 when
            top.FStar_Parser_AST.level = FStar_Parser_AST.Formula ->
            let uu____16526 = desugar_formula env top  in
            (uu____16526, noaqs)
        | uu____16527 ->
            let uu____16528 =
              let uu____16534 =
                let uu____16536 = FStar_Parser_AST.term_to_string top  in
                Prims.op_Hat "Unexpected term: " uu____16536  in
              (FStar_Errors.Fatal_UnexpectedTerm, uu____16534)  in
            FStar_Errors.raise_error uu____16528 top.FStar_Parser_AST.range

and (desugar_args :
  FStar_Syntax_DsEnv.env ->
    (FStar_Parser_AST.term * FStar_Parser_AST.imp) Prims.list ->
      (FStar_Syntax_Syntax.term * FStar_Syntax_Syntax.arg_qualifier
        FStar_Pervasives_Native.option) Prims.list)
  =
  fun env  ->
    fun args  ->
      FStar_All.pipe_right args
        (FStar_List.map
           (fun uu____16580  ->
              match uu____16580 with
              | (a,imp) ->
                  let uu____16593 = desugar_term env a  in
                  arg_withimp_e imp uu____16593))

and (desugar_comp :
  FStar_Range.range ->
    Prims.bool ->
      FStar_Syntax_DsEnv.env ->
        FStar_Parser_AST.term ->
          FStar_Syntax_Syntax.comp' FStar_Syntax_Syntax.syntax)
  =
  fun r  ->
    fun allow_type_promotion  ->
      fun env  ->
        fun t  ->
          let fail1 err = FStar_Errors.raise_error err r  in
          let is_requires uu____16630 =
            match uu____16630 with
            | (t1,uu____16637) ->
                let uu____16638 =
                  let uu____16639 = unparen t1  in
                  uu____16639.FStar_Parser_AST.tm  in
                (match uu____16638 with
                 | FStar_Parser_AST.Requires uu____16641 -> true
                 | uu____16650 -> false)
             in
          let is_ensures uu____16662 =
            match uu____16662 with
            | (t1,uu____16669) ->
                let uu____16670 =
                  let uu____16671 = unparen t1  in
                  uu____16671.FStar_Parser_AST.tm  in
                (match uu____16670 with
                 | FStar_Parser_AST.Ensures uu____16673 -> true
                 | uu____16682 -> false)
             in
          let is_app head1 uu____16700 =
            match uu____16700 with
            | (t1,uu____16708) ->
                let uu____16709 =
                  let uu____16710 = unparen t1  in
                  uu____16710.FStar_Parser_AST.tm  in
                (match uu____16709 with
                 | FStar_Parser_AST.App
                     ({ FStar_Parser_AST.tm = FStar_Parser_AST.Var d;
                        FStar_Parser_AST.range = uu____16713;
                        FStar_Parser_AST.level = uu____16714;_},uu____16715,uu____16716)
                     -> (d.FStar_Ident.ident).FStar_Ident.idText = head1
                 | uu____16718 -> false)
             in
          let is_smt_pat uu____16730 =
            match uu____16730 with
            | (t1,uu____16737) ->
                let uu____16738 =
                  let uu____16739 = unparen t1  in
                  uu____16739.FStar_Parser_AST.tm  in
                (match uu____16738 with
                 | FStar_Parser_AST.Construct
                     (cons1,({
                               FStar_Parser_AST.tm =
                                 FStar_Parser_AST.Construct
                                 (smtpat,uu____16743);
                               FStar_Parser_AST.range = uu____16744;
                               FStar_Parser_AST.level = uu____16745;_},uu____16746)::uu____16747::[])
                     ->
                     (FStar_Ident.lid_equals cons1
                        FStar_Parser_Const.cons_lid)
                       &&
                       (FStar_Util.for_some
                          (fun s  -> smtpat.FStar_Ident.str = s)
                          ["SMTPat"; "SMTPatT"; "SMTPatOr"])
                 | FStar_Parser_AST.Construct
                     (cons1,({
                               FStar_Parser_AST.tm = FStar_Parser_AST.Var
                                 smtpat;
                               FStar_Parser_AST.range = uu____16796;
                               FStar_Parser_AST.level = uu____16797;_},uu____16798)::uu____16799::[])
                     ->
                     (FStar_Ident.lid_equals cons1
                        FStar_Parser_Const.cons_lid)
                       &&
                       (FStar_Util.for_some
                          (fun s  -> smtpat.FStar_Ident.str = s)
                          ["smt_pat"; "smt_pat_or"])
                 | uu____16832 -> false)
             in
          let is_decreases = is_app "decreases"  in
          let pre_process_comp_typ t1 =
            let uu____16867 = head_and_args t1  in
            match uu____16867 with
            | (head1,args) ->
                (match head1.FStar_Parser_AST.tm with
                 | FStar_Parser_AST.Name lemma when
                     (lemma.FStar_Ident.ident).FStar_Ident.idText = "Lemma"
                     ->
                     let unit_tm =
                       ((FStar_Parser_AST.mk_term
                           (FStar_Parser_AST.Name FStar_Parser_Const.unit_lid)
                           t1.FStar_Parser_AST.range
                           FStar_Parser_AST.Type_level),
                         FStar_Parser_AST.Nothing)
                        in
                     let nil_pat =
                       ((FStar_Parser_AST.mk_term
                           (FStar_Parser_AST.Name FStar_Parser_Const.nil_lid)
                           t1.FStar_Parser_AST.range FStar_Parser_AST.Expr),
                         FStar_Parser_AST.Nothing)
                        in
                     let req_true =
                       let req =
                         FStar_Parser_AST.Requires
                           ((FStar_Parser_AST.mk_term
                               (FStar_Parser_AST.Name
                                  FStar_Parser_Const.true_lid)
                               t1.FStar_Parser_AST.range
                               FStar_Parser_AST.Formula),
                             FStar_Pervasives_Native.None)
                          in
                       ((FStar_Parser_AST.mk_term req
                           t1.FStar_Parser_AST.range
                           FStar_Parser_AST.Type_level),
                         FStar_Parser_AST.Nothing)
                        in
                     let thunk_ens uu____16960 =
                       match uu____16960 with
                       | (e,i) ->
                           let uu____16971 = FStar_Parser_AST.thunk e  in
                           (uu____16971, i)
                        in
                     let fail_lemma uu____16983 =
                       let expected_one_of =
                         ["Lemma post";
                         "Lemma (ensures post)";
                         "Lemma (requires pre) (ensures post)";
                         "Lemma post [SMTPat ...]";
                         "Lemma (ensures post) [SMTPat ...]";
                         "Lemma (ensures post) (decreases d)";
                         "Lemma (ensures post) (decreases d) [SMTPat ...]";
                         "Lemma (requires pre) (ensures post) (decreases d)";
                         "Lemma (requires pre) (ensures post) [SMTPat ...]";
                         "Lemma (requires pre) (ensures post) (decreases d) [SMTPat ...]"]
                          in
                       let msg = FStar_String.concat "\n\t" expected_one_of
                          in
                       FStar_Errors.raise_error
                         (FStar_Errors.Fatal_InvalidLemmaArgument,
                           (Prims.op_Hat
                              "Invalid arguments to 'Lemma'; expected one of the following:\n\t"
                              msg)) t1.FStar_Parser_AST.range
                        in
                     let args1 =
                       match args with
                       | [] -> fail_lemma ()
                       | req::[] when is_requires req -> fail_lemma ()
                       | smtpat::[] when is_smt_pat smtpat -> fail_lemma ()
                       | dec::[] when is_decreases dec -> fail_lemma ()
                       | ens::[] ->
                           let uu____17089 =
                             let uu____17096 =
                               let uu____17103 = thunk_ens ens  in
                               [uu____17103; nil_pat]  in
                             req_true :: uu____17096  in
                           unit_tm :: uu____17089
                       | req::ens::[] when
                           (is_requires req) && (is_ensures ens) ->
                           let uu____17150 =
                             let uu____17157 =
                               let uu____17164 = thunk_ens ens  in
                               [uu____17164; nil_pat]  in
                             req :: uu____17157  in
                           unit_tm :: uu____17150
                       | ens::smtpat::[] when
                           (((let uu____17213 = is_requires ens  in
                              Prims.op_Negation uu____17213) &&
                               (let uu____17216 = is_smt_pat ens  in
                                Prims.op_Negation uu____17216))
                              &&
                              (let uu____17219 = is_decreases ens  in
                               Prims.op_Negation uu____17219))
                             && (is_smt_pat smtpat)
                           ->
                           let uu____17221 =
                             let uu____17228 =
                               let uu____17235 = thunk_ens ens  in
                               [uu____17235; smtpat]  in
                             req_true :: uu____17228  in
                           unit_tm :: uu____17221
                       | ens::dec::[] when
                           (is_ensures ens) && (is_decreases dec) ->
                           let uu____17282 =
                             let uu____17289 =
                               let uu____17296 = thunk_ens ens  in
                               [uu____17296; nil_pat; dec]  in
                             req_true :: uu____17289  in
                           unit_tm :: uu____17282
                       | ens::dec::smtpat::[] when
                           ((is_ensures ens) && (is_decreases dec)) &&
                             (is_smt_pat smtpat)
                           ->
                           let uu____17356 =
                             let uu____17363 =
                               let uu____17370 = thunk_ens ens  in
                               [uu____17370; smtpat; dec]  in
                             req_true :: uu____17363  in
                           unit_tm :: uu____17356
                       | req::ens::dec::[] when
                           ((is_requires req) && (is_ensures ens)) &&
                             (is_decreases dec)
                           ->
                           let uu____17430 =
                             let uu____17437 =
                               let uu____17444 = thunk_ens ens  in
                               [uu____17444; nil_pat; dec]  in
                             req :: uu____17437  in
                           unit_tm :: uu____17430
                       | req::ens::smtpat::[] when
                           ((is_requires req) && (is_ensures ens)) &&
                             (is_smt_pat smtpat)
                           ->
                           let uu____17504 =
                             let uu____17511 =
                               let uu____17518 = thunk_ens ens  in
                               [uu____17518; smtpat]  in
                             req :: uu____17511  in
                           unit_tm :: uu____17504
                       | req::ens::dec::smtpat::[] when
                           (((is_requires req) && (is_ensures ens)) &&
                              (is_smt_pat smtpat))
                             && (is_decreases dec)
                           ->
                           let uu____17583 =
                             let uu____17590 =
                               let uu____17597 = thunk_ens ens  in
                               [uu____17597; dec; smtpat]  in
                             req :: uu____17590  in
                           unit_tm :: uu____17583
                       | _other -> fail_lemma ()  in
                     let head_and_attributes =
                       FStar_Syntax_DsEnv.fail_or env
                         (FStar_Syntax_DsEnv.try_lookup_effect_name_and_attributes
                            env) lemma
                        in
                     (head_and_attributes, args1)
                 | FStar_Parser_AST.Name l when
                     FStar_Syntax_DsEnv.is_effect_name env l ->
                     let uu____17659 =
                       FStar_Syntax_DsEnv.fail_or env
                         (FStar_Syntax_DsEnv.try_lookup_effect_name_and_attributes
                            env) l
                        in
                     (uu____17659, args)
                 | FStar_Parser_AST.Name l when
                     (let uu____17687 = FStar_Syntax_DsEnv.current_module env
                         in
                      FStar_Ident.lid_equals uu____17687
                        FStar_Parser_Const.prims_lid)
                       && ((l.FStar_Ident.ident).FStar_Ident.idText = "Tot")
                     ->
                     let uu____17690 =
                       let uu____17697 =
                         FStar_Ident.set_lid_range
                           FStar_Parser_Const.effect_Tot_lid
                           head1.FStar_Parser_AST.range
                          in
                       (uu____17697, [])  in
                     (uu____17690, args)
                 | FStar_Parser_AST.Name l when
                     (let uu____17715 = FStar_Syntax_DsEnv.current_module env
                         in
                      FStar_Ident.lid_equals uu____17715
                        FStar_Parser_Const.prims_lid)
                       && ((l.FStar_Ident.ident).FStar_Ident.idText = "GTot")
                     ->
                     let uu____17718 =
                       let uu____17725 =
                         FStar_Ident.set_lid_range
                           FStar_Parser_Const.effect_GTot_lid
                           head1.FStar_Parser_AST.range
                          in
                       (uu____17725, [])  in
                     (uu____17718, args)
                 | FStar_Parser_AST.Name l when
                     (((l.FStar_Ident.ident).FStar_Ident.idText = "Type") ||
                        ((l.FStar_Ident.ident).FStar_Ident.idText = "Type0"))
                       ||
                       ((l.FStar_Ident.ident).FStar_Ident.idText = "Effect")
                     ->
                     let uu____17747 =
                       let uu____17754 =
                         FStar_Ident.set_lid_range
                           FStar_Parser_Const.effect_Tot_lid
                           head1.FStar_Parser_AST.range
                          in
                       (uu____17754, [])  in
                     (uu____17747, [(t1, FStar_Parser_AST.Nothing)])
                 | uu____17777 when allow_type_promotion ->
                     let default_effect =
                       let uu____17779 = FStar_Options.ml_ish ()  in
                       if uu____17779
                       then FStar_Parser_Const.effect_ML_lid
                       else
                         ((let uu____17785 =
                             FStar_Options.warn_default_effects ()  in
                           if uu____17785
                           then
                             FStar_Errors.log_issue
                               head1.FStar_Parser_AST.range
                               (FStar_Errors.Warning_UseDefaultEffect,
                                 "Using default effect Tot")
                           else ());
                          FStar_Parser_Const.effect_Tot_lid)
                        in
                     let uu____17792 =
                       let uu____17799 =
                         FStar_Ident.set_lid_range default_effect
                           head1.FStar_Parser_AST.range
                          in
                       (uu____17799, [])  in
                     (uu____17792, [(t1, FStar_Parser_AST.Nothing)])
                 | uu____17822 ->
                     FStar_Errors.raise_error
                       (FStar_Errors.Fatal_EffectNotFound,
                         "Expected an effect constructor")
                       t1.FStar_Parser_AST.range)
             in
          let uu____17841 = pre_process_comp_typ t  in
          match uu____17841 with
          | ((eff,cattributes),args) ->
              (if (FStar_List.length args) = Prims.int_zero
               then
                 (let uu____17893 =
                    let uu____17899 =
                      let uu____17901 = FStar_Syntax_Print.lid_to_string eff
                         in
                      FStar_Util.format1 "Not enough args to effect %s"
                        uu____17901
                       in
                    (FStar_Errors.Fatal_NotEnoughArgsToEffect, uu____17899)
                     in
                  fail1 uu____17893)
               else ();
               (let is_universe uu____17917 =
                  match uu____17917 with
                  | (uu____17923,imp) -> imp = FStar_Parser_AST.UnivApp  in
                let uu____17925 = FStar_Util.take is_universe args  in
                match uu____17925 with
                | (universes,args1) ->
                    let universes1 =
                      FStar_List.map
                        (fun uu____17984  ->
                           match uu____17984 with
                           | (u,imp) -> desugar_universe u) universes
                       in
                    let uu____17991 =
                      let uu____18006 = FStar_List.hd args1  in
                      let uu____18015 = FStar_List.tl args1  in
                      (uu____18006, uu____18015)  in
                    (match uu____17991 with
                     | (result_arg,rest) ->
                         let result_typ =
                           desugar_typ env
                             (FStar_Pervasives_Native.fst result_arg)
                            in
                         let rest1 = desugar_args env rest  in
                         let uu____18070 =
                           let is_decrease uu____18109 =
                             match uu____18109 with
                             | (t1,uu____18120) ->
                                 (match t1.FStar_Syntax_Syntax.n with
                                  | FStar_Syntax_Syntax.Tm_app
                                      ({
                                         FStar_Syntax_Syntax.n =
                                           FStar_Syntax_Syntax.Tm_fvar fv;
                                         FStar_Syntax_Syntax.pos =
                                           uu____18131;
                                         FStar_Syntax_Syntax.vars =
                                           uu____18132;_},uu____18133::[])
                                      ->
                                      FStar_Syntax_Syntax.fv_eq_lid fv
                                        FStar_Parser_Const.decreases_lid
                                  | uu____18172 -> false)
                              in
                           FStar_All.pipe_right rest1
                             (FStar_List.partition is_decrease)
                            in
                         (match uu____18070 with
                          | (dec,rest2) ->
                              let decreases_clause =
                                FStar_All.pipe_right dec
                                  (FStar_List.map
                                     (fun uu____18289  ->
                                        match uu____18289 with
                                        | (t1,uu____18299) ->
                                            (match t1.FStar_Syntax_Syntax.n
                                             with
                                             | FStar_Syntax_Syntax.Tm_app
                                                 (uu____18308,(arg,uu____18310)::[])
                                                 ->
                                                 FStar_Syntax_Syntax.DECREASES
                                                   arg
                                             | uu____18349 ->
                                                 failwith "impos")))
                                 in
                              let no_additional_args =
                                let is_empty l =
                                  match l with
                                  | [] -> true
                                  | uu____18370 -> false  in
                                (((is_empty decreases_clause) &&
                                    (is_empty rest2))
                                   && (is_empty cattributes))
                                  && (is_empty universes1)
                                 in
                              let uu____18382 =
                                no_additional_args &&
                                  (FStar_Ident.lid_equals eff
                                     FStar_Parser_Const.effect_Tot_lid)
                                 in
                              if uu____18382
                              then FStar_Syntax_Syntax.mk_Total result_typ
                              else
                                (let uu____18389 =
                                   no_additional_args &&
                                     (FStar_Ident.lid_equals eff
                                        FStar_Parser_Const.effect_GTot_lid)
                                    in
                                 if uu____18389
                                 then
                                   FStar_Syntax_Syntax.mk_GTotal result_typ
                                 else
                                   (let flags =
                                      let uu____18399 =
                                        FStar_Ident.lid_equals eff
                                          FStar_Parser_Const.effect_Lemma_lid
                                         in
                                      if uu____18399
                                      then [FStar_Syntax_Syntax.LEMMA]
                                      else
                                        (let uu____18406 =
                                           FStar_Ident.lid_equals eff
                                             FStar_Parser_Const.effect_Tot_lid
                                            in
                                         if uu____18406
                                         then [FStar_Syntax_Syntax.TOTAL]
                                         else
                                           (let uu____18413 =
                                              FStar_Ident.lid_equals eff
                                                FStar_Parser_Const.effect_ML_lid
                                               in
                                            if uu____18413
                                            then
                                              [FStar_Syntax_Syntax.MLEFFECT]
                                            else
                                              (let uu____18420 =
                                                 FStar_Ident.lid_equals eff
                                                   FStar_Parser_Const.effect_GTot_lid
                                                  in
                                               if uu____18420
                                               then
                                                 [FStar_Syntax_Syntax.SOMETRIVIAL]
                                               else [])))
                                       in
                                    let flags1 =
                                      FStar_List.append flags cattributes  in
                                    let rest3 =
                                      let uu____18441 =
                                        FStar_Ident.lid_equals eff
                                          FStar_Parser_Const.effect_Lemma_lid
                                         in
                                      if uu____18441
                                      then
                                        match rest2 with
                                        | req::ens::(pat,aq)::[] ->
                                            let pat1 =
                                              match pat.FStar_Syntax_Syntax.n
                                              with
                                              | FStar_Syntax_Syntax.Tm_fvar
                                                  fv when
                                                  FStar_Syntax_Syntax.fv_eq_lid
                                                    fv
                                                    FStar_Parser_Const.nil_lid
                                                  ->
                                                  let nil =
                                                    FStar_Syntax_Syntax.mk_Tm_uinst
                                                      pat
                                                      [FStar_Syntax_Syntax.U_zero]
                                                     in
                                                  let pattern =
                                                    let uu____18532 =
                                                      FStar_Ident.set_lid_range
                                                        FStar_Parser_Const.pattern_lid
                                                        pat.FStar_Syntax_Syntax.pos
                                                       in
                                                    FStar_Syntax_Syntax.fvar
                                                      uu____18532
                                                      FStar_Syntax_Syntax.delta_constant
                                                      FStar_Pervasives_Native.None
                                                     in
                                                  FStar_Syntax_Syntax.mk_Tm_app
                                                    nil
                                                    [(pattern,
                                                       (FStar_Pervasives_Native.Some
                                                          FStar_Syntax_Syntax.imp_tag))]
                                                    FStar_Pervasives_Native.None
                                                    pat.FStar_Syntax_Syntax.pos
                                              | uu____18553 -> pat  in
                                            let uu____18554 =
                                              let uu____18565 =
                                                let uu____18576 =
                                                  let uu____18585 =
                                                    FStar_Syntax_Syntax.mk
                                                      (FStar_Syntax_Syntax.Tm_meta
                                                         (pat1,
                                                           (FStar_Syntax_Syntax.Meta_desugared
                                                              FStar_Syntax_Syntax.Meta_smt_pat)))
                                                      FStar_Pervasives_Native.None
                                                      pat1.FStar_Syntax_Syntax.pos
                                                     in
                                                  (uu____18585, aq)  in
                                                [uu____18576]  in
                                              ens :: uu____18565  in
                                            req :: uu____18554
                                        | uu____18626 -> rest2
                                      else rest2  in
                                    FStar_Syntax_Syntax.mk_Comp
                                      {
                                        FStar_Syntax_Syntax.comp_univs =
                                          universes1;
                                        FStar_Syntax_Syntax.effect_name = eff;
                                        FStar_Syntax_Syntax.result_typ =
                                          result_typ;
                                        FStar_Syntax_Syntax.effect_args =
                                          rest3;
                                        FStar_Syntax_Syntax.flags =
                                          (FStar_List.append flags1
                                             decreases_clause)
                                      }))))))

and (desugar_formula :
  FStar_Syntax_DsEnv.env -> FStar_Parser_AST.term -> FStar_Syntax_Syntax.term)
  =
  fun env  ->
    fun f  ->
      let mk1 t =
        FStar_Syntax_Syntax.mk t FStar_Pervasives_Native.None
          f.FStar_Parser_AST.range
         in
      let setpos t =
        let uu___2410_18661 = t  in
        {
          FStar_Syntax_Syntax.n = (uu___2410_18661.FStar_Syntax_Syntax.n);
          FStar_Syntax_Syntax.pos = (f.FStar_Parser_AST.range);
          FStar_Syntax_Syntax.vars =
            (uu___2410_18661.FStar_Syntax_Syntax.vars)
        }  in
      let desugar_quant q b pats body =
        let tk =
          desugar_binder env
            (let uu___2417_18715 = b  in
             {
               FStar_Parser_AST.b = (uu___2417_18715.FStar_Parser_AST.b);
               FStar_Parser_AST.brange =
                 (uu___2417_18715.FStar_Parser_AST.brange);
               FStar_Parser_AST.blevel = FStar_Parser_AST.Formula;
               FStar_Parser_AST.aqual =
                 (uu___2417_18715.FStar_Parser_AST.aqual)
             })
           in
        let with_pats env1 uu____18744 body1 =
          match uu____18744 with
          | (names1,pats1) ->
              (match (names1, pats1) with
               | ([],[]) -> body1
               | ([],uu____18790::uu____18791) ->
                   failwith
                     "Impossible: Annotated pattern without binders in scope"
               | uu____18809 ->
                   let names2 =
                     FStar_All.pipe_right names1
                       (FStar_List.map
                          (fun i  ->
                             let uu___2436_18836 =
                               FStar_Syntax_DsEnv.fail_or2
                                 (FStar_Syntax_DsEnv.try_lookup_id env1) i
                                in
                             {
                               FStar_Syntax_Syntax.n =
                                 (uu___2436_18836.FStar_Syntax_Syntax.n);
                               FStar_Syntax_Syntax.pos =
                                 (i.FStar_Ident.idRange);
                               FStar_Syntax_Syntax.vars =
                                 (uu___2436_18836.FStar_Syntax_Syntax.vars)
                             }))
                      in
                   let pats2 =
                     FStar_All.pipe_right pats1
                       (FStar_List.map
                          (fun es  ->
                             FStar_All.pipe_right es
                               (FStar_List.map
                                  (fun e  ->
                                     let uu____18899 = desugar_term env1 e
                                        in
                                     FStar_All.pipe_left
                                       (arg_withimp_t
                                          FStar_Parser_AST.Nothing)
                                       uu____18899))))
                      in
                   mk1
                     (FStar_Syntax_Syntax.Tm_meta
                        (body1,
                          (FStar_Syntax_Syntax.Meta_pattern (names2, pats2)))))
           in
        match tk with
        | (FStar_Pervasives_Native.Some a,k) ->
            let uu____18930 = FStar_Syntax_DsEnv.push_bv env a  in
            (match uu____18930 with
             | (env1,a1) ->
                 let a2 =
                   let uu___2449_18940 = a1  in
                   {
                     FStar_Syntax_Syntax.ppname =
                       (uu___2449_18940.FStar_Syntax_Syntax.ppname);
                     FStar_Syntax_Syntax.index =
                       (uu___2449_18940.FStar_Syntax_Syntax.index);
                     FStar_Syntax_Syntax.sort = k
                   }  in
                 let body1 = desugar_formula env1 body  in
                 let body2 = with_pats env1 pats body1  in
                 let body3 =
                   let uu____18946 =
                     let uu____18949 =
                       let uu____18950 = FStar_Syntax_Syntax.mk_binder a2  in
                       [uu____18950]  in
                     no_annot_abs uu____18949 body2  in
                   FStar_All.pipe_left setpos uu____18946  in
                 let uu____18971 =
                   let uu____18972 =
                     let uu____18989 =
                       let uu____18992 =
                         FStar_Ident.set_lid_range q
                           b.FStar_Parser_AST.brange
                          in
                       FStar_Syntax_Syntax.fvar uu____18992
                         (FStar_Syntax_Syntax.Delta_constant_at_level
                            Prims.int_one) FStar_Pervasives_Native.None
                        in
                     let uu____18994 =
                       let uu____19005 = FStar_Syntax_Syntax.as_arg body3  in
                       [uu____19005]  in
                     (uu____18989, uu____18994)  in
                   FStar_Syntax_Syntax.Tm_app uu____18972  in
                 FStar_All.pipe_left mk1 uu____18971)
        | uu____19044 -> failwith "impossible"  in
      let push_quant q binders pats body =
        match binders with
        | b::b'::_rest ->
            let rest = b' :: _rest  in
            let body1 =
              let uu____19109 = q (rest, pats, body)  in
              let uu____19112 =
                FStar_Range.union_ranges b'.FStar_Parser_AST.brange
                  body.FStar_Parser_AST.range
                 in
              FStar_Parser_AST.mk_term uu____19109 uu____19112
                FStar_Parser_AST.Formula
               in
            let uu____19113 = q ([b], ([], []), body1)  in
            FStar_Parser_AST.mk_term uu____19113 f.FStar_Parser_AST.range
              FStar_Parser_AST.Formula
        | uu____19124 -> failwith "impossible"  in
      let uu____19128 =
        let uu____19129 = unparen f  in uu____19129.FStar_Parser_AST.tm  in
      match uu____19128 with
      | FStar_Parser_AST.Labeled (f1,l,p) ->
          let f2 = desugar_formula env f1  in
          FStar_All.pipe_left mk1
            (FStar_Syntax_Syntax.Tm_meta
               (f2,
                 (FStar_Syntax_Syntax.Meta_labeled
                    (l, (f2.FStar_Syntax_Syntax.pos), p))))
      | FStar_Parser_AST.QForall ([],uu____19142,uu____19143) ->
          failwith "Impossible: Quantifier without binders"
      | FStar_Parser_AST.QExists ([],uu____19167,uu____19168) ->
          failwith "Impossible: Quantifier without binders"
      | FStar_Parser_AST.QForall (_1::_2::_3,pats,body) ->
          let binders = _1 :: _2 :: _3  in
          let uu____19224 =
            push_quant (fun x  -> FStar_Parser_AST.QForall x) binders pats
              body
             in
          desugar_formula env uu____19224
      | FStar_Parser_AST.QExists (_1::_2::_3,pats,body) ->
          let binders = _1 :: _2 :: _3  in
          let uu____19268 =
            push_quant (fun x  -> FStar_Parser_AST.QExists x) binders pats
              body
             in
          desugar_formula env uu____19268
      | FStar_Parser_AST.QForall (b::[],pats,body) ->
          desugar_quant FStar_Parser_Const.forall_lid b pats body
      | FStar_Parser_AST.QExists (b::[],pats,body) ->
          desugar_quant FStar_Parser_Const.exists_lid b pats body
      | FStar_Parser_AST.Paren f1 -> failwith "impossible"
      | uu____19332 -> desugar_term env f

and (desugar_binder :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.binder ->
      (FStar_Ident.ident FStar_Pervasives_Native.option *
        FStar_Syntax_Syntax.term))
  =
  fun env  ->
    fun b  ->
      match b.FStar_Parser_AST.b with
      | FStar_Parser_AST.TAnnotated (x,t) ->
          let uu____19343 = desugar_typ env t  in
          ((FStar_Pervasives_Native.Some x), uu____19343)
      | FStar_Parser_AST.Annotated (x,t) ->
          let uu____19348 = desugar_typ env t  in
          ((FStar_Pervasives_Native.Some x), uu____19348)
      | FStar_Parser_AST.TVariable x ->
          let uu____19352 =
            FStar_Syntax_Syntax.mk
              (FStar_Syntax_Syntax.Tm_type FStar_Syntax_Syntax.U_unknown)
              FStar_Pervasives_Native.None x.FStar_Ident.idRange
             in
          ((FStar_Pervasives_Native.Some x), uu____19352)
      | FStar_Parser_AST.NoName t ->
          let uu____19356 = desugar_typ env t  in
          (FStar_Pervasives_Native.None, uu____19356)
      | FStar_Parser_AST.Variable x ->
          ((FStar_Pervasives_Native.Some x), FStar_Syntax_Syntax.tun)

and (as_binder :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.arg_qualifier FStar_Pervasives_Native.option ->
      (FStar_Ident.ident FStar_Pervasives_Native.option *
        FStar_Syntax_Syntax.term) ->
        ((FStar_Syntax_Syntax.bv * FStar_Syntax_Syntax.arg_qualifier
          FStar_Pervasives_Native.option) * FStar_Syntax_DsEnv.env))
  =
  fun env  ->
    fun imp  ->
      fun uu___12_19364  ->
        match uu___12_19364 with
        | (FStar_Pervasives_Native.None ,k) ->
            let uu____19386 = FStar_Syntax_Syntax.null_binder k  in
            (uu____19386, env)
        | (FStar_Pervasives_Native.Some a,k) ->
            let uu____19403 = FStar_Syntax_DsEnv.push_bv env a  in
            (match uu____19403 with
             | (env1,a1) ->
                 let uu____19420 =
                   let uu____19427 = trans_aqual env1 imp  in
                   ((let uu___2549_19433 = a1  in
                     {
                       FStar_Syntax_Syntax.ppname =
                         (uu___2549_19433.FStar_Syntax_Syntax.ppname);
                       FStar_Syntax_Syntax.index =
                         (uu___2549_19433.FStar_Syntax_Syntax.index);
                       FStar_Syntax_Syntax.sort = k
                     }), uu____19427)
                    in
                 (uu____19420, env1))

and (trans_aqual :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.arg_qualifier FStar_Pervasives_Native.option ->
      FStar_Syntax_Syntax.aqual)
  =
  fun env  ->
    fun uu___13_19441  ->
      match uu___13_19441 with
      | FStar_Pervasives_Native.Some (FStar_Parser_AST.Implicit ) ->
          FStar_Pervasives_Native.Some FStar_Syntax_Syntax.imp_tag
      | FStar_Pervasives_Native.Some (FStar_Parser_AST.Equality ) ->
          FStar_Pervasives_Native.Some FStar_Syntax_Syntax.Equality
      | FStar_Pervasives_Native.Some (FStar_Parser_AST.Meta t) ->
          let uu____19445 =
            let uu____19446 = desugar_term env t  in
            FStar_Syntax_Syntax.Meta uu____19446  in
          FStar_Pervasives_Native.Some uu____19445
      | FStar_Pervasives_Native.None  -> FStar_Pervasives_Native.None

let (typars_of_binders :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.binder Prims.list ->
      (FStar_Syntax_DsEnv.env * (FStar_Syntax_Syntax.bv *
        FStar_Syntax_Syntax.aqual) Prims.list))
  =
  fun env  ->
    fun bs  ->
      let uu____19474 =
        FStar_List.fold_left
          (fun uu____19507  ->
             fun b  ->
               match uu____19507 with
               | (env1,out) ->
                   let tk =
                     desugar_binder env1
                       (let uu___2567_19551 = b  in
                        {
                          FStar_Parser_AST.b =
                            (uu___2567_19551.FStar_Parser_AST.b);
                          FStar_Parser_AST.brange =
                            (uu___2567_19551.FStar_Parser_AST.brange);
                          FStar_Parser_AST.blevel = FStar_Parser_AST.Formula;
                          FStar_Parser_AST.aqual =
                            (uu___2567_19551.FStar_Parser_AST.aqual)
                        })
                      in
                   (match tk with
                    | (FStar_Pervasives_Native.Some a,k) ->
                        let uu____19566 = FStar_Syntax_DsEnv.push_bv env1 a
                           in
                        (match uu____19566 with
                         | (env2,a1) ->
                             let a2 =
                               let uu___2577_19584 = a1  in
                               {
                                 FStar_Syntax_Syntax.ppname =
                                   (uu___2577_19584.FStar_Syntax_Syntax.ppname);
                                 FStar_Syntax_Syntax.index =
                                   (uu___2577_19584.FStar_Syntax_Syntax.index);
                                 FStar_Syntax_Syntax.sort = k
                               }  in
                             let uu____19585 =
                               let uu____19592 =
                                 let uu____19597 =
                                   trans_aqual env2 b.FStar_Parser_AST.aqual
                                    in
                                 (a2, uu____19597)  in
                               uu____19592 :: out  in
                             (env2, uu____19585))
                    | uu____19608 ->
                        FStar_Errors.raise_error
                          (FStar_Errors.Fatal_UnexpectedBinder,
                            "Unexpected binder") b.FStar_Parser_AST.brange))
          (env, []) bs
         in
      match uu____19474 with | (env1,tpars) -> (env1, (FStar_List.rev tpars))
  
let (desugar_attributes :
  env_t ->
    FStar_Parser_AST.term Prims.list -> FStar_Syntax_Syntax.cflag Prims.list)
  =
  fun env  ->
    fun cattributes  ->
      let desugar_attribute t =
        let uu____19696 =
          let uu____19697 = unparen t  in uu____19697.FStar_Parser_AST.tm  in
        match uu____19696 with
        | FStar_Parser_AST.Var
            { FStar_Ident.ns = uu____19698; FStar_Ident.ident = uu____19699;
              FStar_Ident.nsstr = uu____19700; FStar_Ident.str = "cps";_}
            -> FStar_Syntax_Syntax.CPS
        | uu____19705 ->
            let uu____19706 =
              let uu____19712 =
                let uu____19714 = FStar_Parser_AST.term_to_string t  in
                Prims.op_Hat "Unknown attribute " uu____19714  in
              (FStar_Errors.Fatal_UnknownAttribute, uu____19712)  in
            FStar_Errors.raise_error uu____19706 t.FStar_Parser_AST.range
         in
      FStar_List.map desugar_attribute cattributes
  
let (binder_ident :
  FStar_Parser_AST.binder -> FStar_Ident.ident FStar_Pervasives_Native.option)
  =
  fun b  ->
    match b.FStar_Parser_AST.b with
    | FStar_Parser_AST.TAnnotated (x,uu____19731) ->
        FStar_Pervasives_Native.Some x
    | FStar_Parser_AST.Annotated (x,uu____19733) ->
        FStar_Pervasives_Native.Some x
    | FStar_Parser_AST.TVariable x -> FStar_Pervasives_Native.Some x
    | FStar_Parser_AST.Variable x -> FStar_Pervasives_Native.Some x
    | FStar_Parser_AST.NoName uu____19736 -> FStar_Pervasives_Native.None
  
let (binder_idents :
  FStar_Parser_AST.binder Prims.list -> FStar_Ident.ident Prims.list) =
  fun bs  ->
    FStar_List.collect
      (fun b  ->
         let uu____19754 = binder_ident b  in
         FStar_Common.list_of_option uu____19754) bs
  
let (mk_data_discriminators :
  FStar_Syntax_Syntax.qualifier Prims.list ->
    FStar_Syntax_DsEnv.env ->
      FStar_Ident.lident Prims.list -> FStar_Syntax_Syntax.sigelt Prims.list)
  =
  fun quals  ->
    fun env  ->
      fun datas  ->
        let quals1 =
          FStar_All.pipe_right quals
            (FStar_List.filter
               (fun uu___14_19791  ->
                  match uu___14_19791 with
                  | FStar_Syntax_Syntax.NoExtract  -> true
                  | FStar_Syntax_Syntax.Abstract  -> true
                  | FStar_Syntax_Syntax.Private  -> true
                  | uu____19796 -> false))
           in
        let quals2 q =
          let uu____19810 =
            (let uu____19814 = FStar_Syntax_DsEnv.iface env  in
             Prims.op_Negation uu____19814) ||
              (FStar_Syntax_DsEnv.admitted_iface env)
             in
          if uu____19810
          then FStar_List.append (FStar_Syntax_Syntax.Assumption :: q) quals1
          else FStar_List.append q quals1  in
        FStar_All.pipe_right datas
          (FStar_List.map
             (fun d  ->
                let disc_name = FStar_Syntax_Util.mk_discriminator d  in
                let uu____19831 = FStar_Ident.range_of_lid disc_name  in
                let uu____19832 =
                  quals2
                    [FStar_Syntax_Syntax.OnlyName;
                    FStar_Syntax_Syntax.Discriminator d]
                   in
                {
                  FStar_Syntax_Syntax.sigel =
                    (FStar_Syntax_Syntax.Sig_declare_typ
                       (disc_name, [], FStar_Syntax_Syntax.tun));
                  FStar_Syntax_Syntax.sigrng = uu____19831;
                  FStar_Syntax_Syntax.sigquals = uu____19832;
                  FStar_Syntax_Syntax.sigmeta =
                    FStar_Syntax_Syntax.default_sigmeta;
                  FStar_Syntax_Syntax.sigattrs = [];
                  FStar_Syntax_Syntax.sigopts = FStar_Pervasives_Native.None
                }))
  
let (mk_indexed_projector_names :
  FStar_Syntax_Syntax.qualifier Prims.list ->
    FStar_Syntax_Syntax.fv_qual ->
      FStar_Syntax_DsEnv.env ->
        FStar_Ident.lident ->
          FStar_Syntax_Syntax.binder Prims.list ->
            FStar_Syntax_Syntax.sigelt Prims.list)
  =
  fun iquals  ->
    fun fvq  ->
      fun env  ->
        fun lid  ->
          fun fields  ->
            let p = FStar_Ident.range_of_lid lid  in
            let uu____19872 =
              FStar_All.pipe_right fields
                (FStar_List.mapi
                   (fun i  ->
                      fun uu____19910  ->
                        match uu____19910 with
                        | (x,uu____19921) ->
                            let uu____19926 =
                              FStar_Syntax_Util.mk_field_projector_name lid x
                                i
                               in
                            (match uu____19926 with
                             | (field_name,uu____19934) ->
                                 let only_decl =
                                   ((let uu____19939 =
                                       FStar_Syntax_DsEnv.current_module env
                                        in
                                     FStar_Ident.lid_equals
                                       FStar_Parser_Const.prims_lid
                                       uu____19939)
                                      ||
                                      (fvq <> FStar_Syntax_Syntax.Data_ctor))
                                     ||
                                     (let uu____19941 =
                                        let uu____19943 =
                                          FStar_Syntax_DsEnv.current_module
                                            env
                                           in
                                        uu____19943.FStar_Ident.str  in
                                      FStar_Options.dont_gen_projectors
                                        uu____19941)
                                    in
                                 let no_decl =
                                   FStar_Syntax_Syntax.is_type
                                     x.FStar_Syntax_Syntax.sort
                                    in
                                 let quals q =
                                   if only_decl
                                   then
                                     let uu____19961 =
                                       FStar_List.filter
                                         (fun uu___15_19965  ->
                                            match uu___15_19965 with
                                            | FStar_Syntax_Syntax.Abstract 
                                                -> false
                                            | uu____19968 -> true) q
                                        in
                                     FStar_Syntax_Syntax.Assumption ::
                                       uu____19961
                                   else q  in
                                 let quals1 =
                                   let iquals1 =
                                     FStar_All.pipe_right iquals
                                       (FStar_List.filter
                                          (fun uu___16_19983  ->
                                             match uu___16_19983 with
                                             | FStar_Syntax_Syntax.NoExtract 
                                                 -> true
                                             | FStar_Syntax_Syntax.Abstract 
                                                 -> true
                                             | FStar_Syntax_Syntax.Private 
                                                 -> true
                                             | uu____19988 -> false))
                                      in
                                   quals (FStar_Syntax_Syntax.OnlyName ::
                                     (FStar_Syntax_Syntax.Projector
                                        (lid, (x.FStar_Syntax_Syntax.ppname)))
                                     :: iquals1)
                                    in
                                 let decl =
                                   let uu____19991 =
                                     FStar_Ident.range_of_lid field_name  in
                                   {
                                     FStar_Syntax_Syntax.sigel =
                                       (FStar_Syntax_Syntax.Sig_declare_typ
                                          (field_name, [],
                                            FStar_Syntax_Syntax.tun));
                                     FStar_Syntax_Syntax.sigrng = uu____19991;
                                     FStar_Syntax_Syntax.sigquals = quals1;
                                     FStar_Syntax_Syntax.sigmeta =
                                       FStar_Syntax_Syntax.default_sigmeta;
                                     FStar_Syntax_Syntax.sigattrs = [];
                                     FStar_Syntax_Syntax.sigopts =
                                       FStar_Pervasives_Native.None
                                   }  in
                                 if only_decl
                                 then [decl]
                                 else
                                   (let dd =
                                      let uu____19998 =
                                        FStar_All.pipe_right quals1
                                          (FStar_List.contains
                                             FStar_Syntax_Syntax.Abstract)
                                         in
                                      if uu____19998
                                      then
                                        FStar_Syntax_Syntax.Delta_abstract
                                          (FStar_Syntax_Syntax.Delta_equational_at_level
                                             Prims.int_one)
                                      else
                                        FStar_Syntax_Syntax.Delta_equational_at_level
                                          Prims.int_one
                                       in
                                    let lb =
                                      let uu____20009 =
                                        let uu____20014 =
                                          FStar_Syntax_Syntax.lid_as_fv
                                            field_name dd
                                            FStar_Pervasives_Native.None
                                           in
                                        FStar_Util.Inr uu____20014  in
                                      {
                                        FStar_Syntax_Syntax.lbname =
                                          uu____20009;
                                        FStar_Syntax_Syntax.lbunivs = [];
                                        FStar_Syntax_Syntax.lbtyp =
                                          FStar_Syntax_Syntax.tun;
                                        FStar_Syntax_Syntax.lbeff =
                                          FStar_Parser_Const.effect_Tot_lid;
                                        FStar_Syntax_Syntax.lbdef =
                                          FStar_Syntax_Syntax.tun;
                                        FStar_Syntax_Syntax.lbattrs = [];
                                        FStar_Syntax_Syntax.lbpos =
                                          FStar_Range.dummyRange
                                      }  in
                                    let impl =
                                      let uu____20018 =
                                        let uu____20019 =
                                          let uu____20026 =
                                            let uu____20029 =
                                              let uu____20030 =
                                                FStar_All.pipe_right
                                                  lb.FStar_Syntax_Syntax.lbname
                                                  FStar_Util.right
                                                 in
                                              FStar_All.pipe_right
                                                uu____20030
                                                (fun fv  ->
                                                   (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v)
                                               in
                                            [uu____20029]  in
                                          ((false, [lb]), uu____20026)  in
                                        FStar_Syntax_Syntax.Sig_let
                                          uu____20019
                                         in
                                      {
                                        FStar_Syntax_Syntax.sigel =
                                          uu____20018;
                                        FStar_Syntax_Syntax.sigrng = p;
                                        FStar_Syntax_Syntax.sigquals = quals1;
                                        FStar_Syntax_Syntax.sigmeta =
                                          FStar_Syntax_Syntax.default_sigmeta;
                                        FStar_Syntax_Syntax.sigattrs = [];
                                        FStar_Syntax_Syntax.sigopts =
                                          FStar_Pervasives_Native.None
                                      }  in
                                    if no_decl then [impl] else [decl; impl]))))
               in
            FStar_All.pipe_right uu____19872 FStar_List.flatten
  
let (mk_data_projector_names :
  FStar_Syntax_Syntax.qualifier Prims.list ->
    FStar_Syntax_DsEnv.env ->
      FStar_Syntax_Syntax.sigelt -> FStar_Syntax_Syntax.sigelt Prims.list)
  =
  fun iquals  ->
    fun env  ->
      fun se  ->
        match se.FStar_Syntax_Syntax.sigel with
        | FStar_Syntax_Syntax.Sig_datacon
            (lid,uu____20079,t,uu____20081,n1,uu____20083) when
            let uu____20090 =
              FStar_Ident.lid_equals lid FStar_Parser_Const.lexcons_lid  in
            Prims.op_Negation uu____20090 ->
            let uu____20092 = FStar_Syntax_Util.arrow_formals t  in
            (match uu____20092 with
             | (formals,uu____20110) ->
                 (match formals with
                  | [] -> []
                  | uu____20139 ->
                      let filter_records uu___17_20155 =
                        match uu___17_20155 with
                        | FStar_Syntax_Syntax.RecordConstructor
                            (uu____20158,fns) ->
                            FStar_Pervasives_Native.Some
                              (FStar_Syntax_Syntax.Record_ctor (lid, fns))
                        | uu____20170 -> FStar_Pervasives_Native.None  in
                      let fv_qual =
                        let uu____20172 =
                          FStar_Util.find_map se.FStar_Syntax_Syntax.sigquals
                            filter_records
                           in
                        match uu____20172 with
                        | FStar_Pervasives_Native.None  ->
                            FStar_Syntax_Syntax.Data_ctor
                        | FStar_Pervasives_Native.Some q -> q  in
                      let iquals1 =
                        if
                          (FStar_List.contains FStar_Syntax_Syntax.Abstract
                             iquals)
                            &&
                            (Prims.op_Negation
                               (FStar_List.contains
                                  FStar_Syntax_Syntax.Private iquals))
                        then FStar_Syntax_Syntax.Private :: iquals
                        else iquals  in
                      let uu____20184 = FStar_Util.first_N n1 formals  in
                      (match uu____20184 with
                       | (uu____20213,rest) ->
                           mk_indexed_projector_names iquals1 fv_qual env lid
                             rest)))
        | uu____20247 -> []
  
let (mk_typ_abbrev :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.decl ->
      FStar_Ident.lident ->
        FStar_Syntax_Syntax.univ_name Prims.list ->
          (FStar_Syntax_Syntax.bv * FStar_Syntax_Syntax.arg_qualifier
            FStar_Pervasives_Native.option) Prims.list ->
            FStar_Syntax_Syntax.typ FStar_Pervasives_Native.option ->
              FStar_Syntax_Syntax.term' FStar_Syntax_Syntax.syntax ->
                FStar_Ident.lident Prims.list ->
                  FStar_Syntax_Syntax.qualifier Prims.list ->
                    FStar_Range.range -> FStar_Syntax_Syntax.sigelt)
  =
  fun env  ->
    fun d  ->
      fun lid  ->
        fun uvs  ->
          fun typars  ->
            fun kopt  ->
              fun t  ->
                fun lids  ->
                  fun quals  ->
                    fun rng  ->
                      let attrs =
                        FStar_List.map (desugar_term env)
                          d.FStar_Parser_AST.attrs
                         in
                      let val_attrs =
                        let uu____20341 =
                          FStar_Syntax_DsEnv.lookup_letbinding_quals_and_attrs
                            env lid
                           in
                        FStar_All.pipe_right uu____20341
                          FStar_Pervasives_Native.snd
                         in
                      let dd =
                        let uu____20365 =
                          FStar_All.pipe_right quals
                            (FStar_List.contains FStar_Syntax_Syntax.Abstract)
                           in
                        if uu____20365
                        then
                          let uu____20371 =
                            FStar_Syntax_Util.incr_delta_qualifier t  in
                          FStar_Syntax_Syntax.Delta_abstract uu____20371
                        else FStar_Syntax_Util.incr_delta_qualifier t  in
                      let lb =
                        let uu____20375 =
                          let uu____20380 =
                            FStar_Syntax_Syntax.lid_as_fv lid dd
                              FStar_Pervasives_Native.None
                             in
                          FStar_Util.Inr uu____20380  in
                        let uu____20381 =
                          if FStar_Util.is_some kopt
                          then
                            let uu____20387 =
                              let uu____20390 =
                                FStar_All.pipe_right kopt FStar_Util.must  in
                              FStar_Syntax_Syntax.mk_Total uu____20390  in
                            FStar_Syntax_Util.arrow typars uu____20387
                          else FStar_Syntax_Syntax.tun  in
                        let uu____20395 = no_annot_abs typars t  in
                        {
                          FStar_Syntax_Syntax.lbname = uu____20375;
                          FStar_Syntax_Syntax.lbunivs = uvs;
                          FStar_Syntax_Syntax.lbtyp = uu____20381;
                          FStar_Syntax_Syntax.lbeff =
                            FStar_Parser_Const.effect_Tot_lid;
                          FStar_Syntax_Syntax.lbdef = uu____20395;
                          FStar_Syntax_Syntax.lbattrs = [];
                          FStar_Syntax_Syntax.lbpos = rng
                        }  in
                      {
                        FStar_Syntax_Syntax.sigel =
                          (FStar_Syntax_Syntax.Sig_let ((false, [lb]), lids));
                        FStar_Syntax_Syntax.sigrng = rng;
                        FStar_Syntax_Syntax.sigquals = quals;
                        FStar_Syntax_Syntax.sigmeta =
                          FStar_Syntax_Syntax.default_sigmeta;
                        FStar_Syntax_Syntax.sigattrs =
                          (FStar_List.append val_attrs attrs);
                        FStar_Syntax_Syntax.sigopts =
                          FStar_Pervasives_Native.None
                      }
  
let rec (desugar_tycon :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.decl ->
      FStar_Syntax_Syntax.qualifier Prims.list ->
        FStar_Parser_AST.tycon Prims.list ->
          (env_t * FStar_Syntax_Syntax.sigelts))
  =
  fun env  ->
    fun d  ->
      fun quals  ->
        fun tcs  ->
          let rng = d.FStar_Parser_AST.drange  in
          let tycon_id uu___18_20449 =
            match uu___18_20449 with
            | FStar_Parser_AST.TyconAbstract (id1,uu____20451,uu____20452) ->
                id1
            | FStar_Parser_AST.TyconAbbrev
                (id1,uu____20462,uu____20463,uu____20464) -> id1
            | FStar_Parser_AST.TyconRecord
                (id1,uu____20474,uu____20475,uu____20476) -> id1
            | FStar_Parser_AST.TyconVariant
                (id1,uu____20498,uu____20499,uu____20500) -> id1
             in
          let binder_to_term1 b =
            match b.FStar_Parser_AST.b with
            | FStar_Parser_AST.Annotated (x,uu____20538) ->
                let uu____20539 =
                  let uu____20540 = FStar_Ident.lid_of_ids [x]  in
                  FStar_Parser_AST.Var uu____20540  in
                FStar_Parser_AST.mk_term uu____20539 x.FStar_Ident.idRange
                  FStar_Parser_AST.Expr
            | FStar_Parser_AST.Variable x ->
                let uu____20542 =
                  let uu____20543 = FStar_Ident.lid_of_ids [x]  in
                  FStar_Parser_AST.Var uu____20543  in
                FStar_Parser_AST.mk_term uu____20542 x.FStar_Ident.idRange
                  FStar_Parser_AST.Expr
            | FStar_Parser_AST.TAnnotated (a,uu____20545) ->
                FStar_Parser_AST.mk_term (FStar_Parser_AST.Tvar a)
                  a.FStar_Ident.idRange FStar_Parser_AST.Type_level
            | FStar_Parser_AST.TVariable a ->
                FStar_Parser_AST.mk_term (FStar_Parser_AST.Tvar a)
                  a.FStar_Ident.idRange FStar_Parser_AST.Type_level
            | FStar_Parser_AST.NoName t -> t  in
          let tot =
            FStar_Parser_AST.mk_term
              (FStar_Parser_AST.Name FStar_Parser_Const.effect_Tot_lid) rng
              FStar_Parser_AST.Expr
             in
          let with_constructor_effect t =
            FStar_Parser_AST.mk_term
              (FStar_Parser_AST.App (tot, t, FStar_Parser_AST.Nothing))
              t.FStar_Parser_AST.range t.FStar_Parser_AST.level
             in
          let apply_binders t binders =
            let imp_of_aqual b =
              match b.FStar_Parser_AST.aqual with
              | FStar_Pervasives_Native.Some (FStar_Parser_AST.Implicit ) ->
                  FStar_Parser_AST.Hash
              | uu____20576 -> FStar_Parser_AST.Nothing  in
            FStar_List.fold_left
              (fun out  ->
                 fun b  ->
                   let uu____20584 =
                     let uu____20585 =
                       let uu____20592 = binder_to_term1 b  in
                       (out, uu____20592, (imp_of_aqual b))  in
                     FStar_Parser_AST.App uu____20585  in
                   FStar_Parser_AST.mk_term uu____20584
                     out.FStar_Parser_AST.range out.FStar_Parser_AST.level) t
              binders
             in
          let tycon_record_as_variant uu___19_20604 =
            match uu___19_20604 with
            | FStar_Parser_AST.TyconRecord (id1,parms,kopt,fields) ->
                let constrName =
                  FStar_Ident.mk_ident
                    ((Prims.op_Hat "Mk" id1.FStar_Ident.idText),
                      (id1.FStar_Ident.idRange))
                   in
                let mfields =
                  FStar_List.map
                    (fun uu____20648  ->
                       match uu____20648 with
                       | (x,t) ->
                           FStar_Parser_AST.mk_binder
                             (FStar_Parser_AST.Annotated (x, t))
                             x.FStar_Ident.idRange FStar_Parser_AST.Expr
                             FStar_Pervasives_Native.None) fields
                   in
                let result =
                  let uu____20656 =
                    let uu____20657 =
                      let uu____20658 = FStar_Ident.lid_of_ids [id1]  in
                      FStar_Parser_AST.Var uu____20658  in
                    FStar_Parser_AST.mk_term uu____20657
                      id1.FStar_Ident.idRange FStar_Parser_AST.Type_level
                     in
                  apply_binders uu____20656 parms  in
                let constrTyp =
                  FStar_Parser_AST.mk_term
                    (FStar_Parser_AST.Product
                       (mfields, (with_constructor_effect result)))
                    id1.FStar_Ident.idRange FStar_Parser_AST.Type_level
                   in
                let names1 =
                  let uu____20665 = binder_idents parms  in id1 ::
                    uu____20665
                   in
                (FStar_List.iter
                   (fun uu____20678  ->
                      match uu____20678 with
                      | (f,uu____20684) ->
                          let uu____20685 =
                            FStar_Util.for_some
                              (fun i  -> FStar_Ident.ident_equals f i) names1
                             in
                          if uu____20685
                          then
                            let uu____20690 =
                              let uu____20696 =
                                let uu____20698 =
                                  FStar_Ident.string_of_ident f  in
                                FStar_Util.format1
                                  "Field %s shadows the record's name or a parameter of it, please rename it"
                                  uu____20698
                                 in
                              (FStar_Errors.Error_FieldShadow, uu____20696)
                               in
                            FStar_Errors.raise_error uu____20690
                              f.FStar_Ident.idRange
                          else ()) fields;
                 (let uu____20704 =
                    FStar_All.pipe_right fields
                      (FStar_List.map FStar_Pervasives_Native.fst)
                     in
                  ((FStar_Parser_AST.TyconVariant
                      (id1, parms, kopt,
                        [(constrName,
                           (FStar_Pervasives_Native.Some constrTyp), false)])),
                    uu____20704)))
            | uu____20758 -> failwith "impossible"  in
          let desugar_abstract_tc quals1 _env mutuals uu___20_20798 =
            match uu___20_20798 with
            | FStar_Parser_AST.TyconAbstract (id1,binders,kopt) ->
                let uu____20822 = typars_of_binders _env binders  in
                (match uu____20822 with
                 | (_env',typars) ->
                     let k =
                       match kopt with
                       | FStar_Pervasives_Native.None  ->
                           FStar_Syntax_Util.ktype
                       | FStar_Pervasives_Native.Some k ->
                           desugar_term _env' k
                        in
                     let tconstr =
                       let uu____20858 =
                         let uu____20859 =
                           let uu____20860 = FStar_Ident.lid_of_ids [id1]  in
                           FStar_Parser_AST.Var uu____20860  in
                         FStar_Parser_AST.mk_term uu____20859
                           id1.FStar_Ident.idRange
                           FStar_Parser_AST.Type_level
                          in
                       apply_binders uu____20858 binders  in
                     let qlid = FStar_Syntax_DsEnv.qualify _env id1  in
                     let typars1 = FStar_Syntax_Subst.close_binders typars
                        in
                     let k1 = FStar_Syntax_Subst.close typars1 k  in
                     let se =
                       {
                         FStar_Syntax_Syntax.sigel =
                           (FStar_Syntax_Syntax.Sig_inductive_typ
                              (qlid, [], typars1, k1, mutuals, []));
                         FStar_Syntax_Syntax.sigrng = rng;
                         FStar_Syntax_Syntax.sigquals = quals1;
                         FStar_Syntax_Syntax.sigmeta =
                           FStar_Syntax_Syntax.default_sigmeta;
                         FStar_Syntax_Syntax.sigattrs = [];
                         FStar_Syntax_Syntax.sigopts =
                           FStar_Pervasives_Native.None
                       }  in
                     let uu____20869 =
                       FStar_Syntax_DsEnv.push_top_level_rec_binding _env id1
                         FStar_Syntax_Syntax.delta_constant
                        in
                     (match uu____20869 with
                      | (_env1,uu____20886) ->
                          let uu____20893 =
                            FStar_Syntax_DsEnv.push_top_level_rec_binding
                              _env' id1 FStar_Syntax_Syntax.delta_constant
                             in
                          (match uu____20893 with
                           | (_env2,uu____20910) ->
                               (_env1, _env2, se, tconstr))))
            | uu____20917 -> failwith "Unexpected tycon"  in
          let push_tparams env1 bs =
            let uu____20960 =
              FStar_List.fold_left
                (fun uu____20994  ->
                   fun uu____20995  ->
                     match (uu____20994, uu____20995) with
                     | ((env2,tps),(x,imp)) ->
                         let uu____21064 =
                           FStar_Syntax_DsEnv.push_bv env2
                             x.FStar_Syntax_Syntax.ppname
                            in
                         (match uu____21064 with
                          | (env3,y) -> (env3, ((y, imp) :: tps))))
                (env1, []) bs
               in
            match uu____20960 with
            | (env2,bs1) -> (env2, (FStar_List.rev bs1))  in
          match tcs with
          | (FStar_Parser_AST.TyconAbstract (id1,bs,kopt))::[] ->
              let kopt1 =
                match kopt with
                | FStar_Pervasives_Native.None  ->
                    let uu____21155 = tm_type_z id1.FStar_Ident.idRange  in
                    FStar_Pervasives_Native.Some uu____21155
                | uu____21156 -> kopt  in
              let tc = FStar_Parser_AST.TyconAbstract (id1, bs, kopt1)  in
              let uu____21164 = desugar_abstract_tc quals env [] tc  in
              (match uu____21164 with
               | (uu____21177,uu____21178,se,uu____21180) ->
                   let se1 =
                     match se.FStar_Syntax_Syntax.sigel with
                     | FStar_Syntax_Syntax.Sig_inductive_typ
                         (l,uu____21183,typars,k,[],[]) ->
                         let quals1 = se.FStar_Syntax_Syntax.sigquals  in
                         let quals2 =
                           if
                             FStar_List.contains
                               FStar_Syntax_Syntax.Assumption quals1
                           then quals1
                           else
                             ((let uu____21202 =
                                 let uu____21204 = FStar_Options.ml_ish ()
                                    in
                                 Prims.op_Negation uu____21204  in
                               if uu____21202
                               then
                                 let uu____21207 =
                                   let uu____21213 =
                                     let uu____21215 =
                                       FStar_Syntax_Print.lid_to_string l  in
                                     FStar_Util.format1
                                       "Adding an implicit 'assume new' qualifier on %s"
                                       uu____21215
                                      in
                                   (FStar_Errors.Warning_AddImplicitAssumeNewQualifier,
                                     uu____21213)
                                    in
                                 FStar_Errors.log_issue
                                   se.FStar_Syntax_Syntax.sigrng uu____21207
                               else ());
                              FStar_Syntax_Syntax.Assumption
                              ::
                              FStar_Syntax_Syntax.New
                              ::
                              quals1)
                            in
                         let t =
                           match typars with
                           | [] -> k
                           | uu____21228 ->
                               let uu____21229 =
                                 let uu____21236 =
                                   let uu____21237 =
                                     let uu____21252 =
                                       FStar_Syntax_Syntax.mk_Total k  in
                                     (typars, uu____21252)  in
                                   FStar_Syntax_Syntax.Tm_arrow uu____21237
                                    in
                                 FStar_Syntax_Syntax.mk uu____21236  in
                               uu____21229 FStar_Pervasives_Native.None
                                 se.FStar_Syntax_Syntax.sigrng
                            in
                         let uu___2860_21265 = se  in
                         {
                           FStar_Syntax_Syntax.sigel =
                             (FStar_Syntax_Syntax.Sig_declare_typ (l, [], t));
                           FStar_Syntax_Syntax.sigrng =
                             (uu___2860_21265.FStar_Syntax_Syntax.sigrng);
                           FStar_Syntax_Syntax.sigquals = quals2;
                           FStar_Syntax_Syntax.sigmeta =
                             (uu___2860_21265.FStar_Syntax_Syntax.sigmeta);
                           FStar_Syntax_Syntax.sigattrs =
                             (uu___2860_21265.FStar_Syntax_Syntax.sigattrs);
                           FStar_Syntax_Syntax.sigopts =
                             (uu___2860_21265.FStar_Syntax_Syntax.sigopts)
                         }
                     | uu____21266 -> failwith "Impossible"  in
                   let env1 = FStar_Syntax_DsEnv.push_sigelt env se1  in
                   (env1, [se1]))
          | (FStar_Parser_AST.TyconAbbrev (id1,binders,kopt,t))::[] ->
              let uu____21281 = typars_of_binders env binders  in
              (match uu____21281 with
               | (env',typars) ->
                   let kopt1 =
                     match kopt with
                     | FStar_Pervasives_Native.None  ->
                         let uu____21315 =
                           FStar_Util.for_some
                             (fun uu___21_21318  ->
                                match uu___21_21318 with
                                | FStar_Syntax_Syntax.Effect  -> true
                                | uu____21321 -> false) quals
                            in
                         if uu____21315
                         then
                           FStar_Pervasives_Native.Some
                             FStar_Syntax_Syntax.teff
                         else FStar_Pervasives_Native.None
                     | FStar_Pervasives_Native.Some k ->
                         let uu____21329 = desugar_term env' k  in
                         FStar_Pervasives_Native.Some uu____21329
                      in
                   let t0 = t  in
                   let quals1 =
                     let uu____21334 =
                       FStar_All.pipe_right quals
                         (FStar_Util.for_some
                            (fun uu___22_21340  ->
                               match uu___22_21340 with
                               | FStar_Syntax_Syntax.Logic  -> true
                               | uu____21343 -> false))
                        in
                     if uu____21334
                     then quals
                     else
                       if
                         t0.FStar_Parser_AST.level = FStar_Parser_AST.Formula
                       then FStar_Syntax_Syntax.Logic :: quals
                       else quals
                      in
                   let qlid = FStar_Syntax_DsEnv.qualify env id1  in
                   let se =
                     let uu____21357 =
                       FStar_All.pipe_right quals1
                         (FStar_List.contains FStar_Syntax_Syntax.Effect)
                        in
                     if uu____21357
                     then
                       let uu____21363 =
                         let uu____21370 =
                           let uu____21371 = unparen t  in
                           uu____21371.FStar_Parser_AST.tm  in
                         match uu____21370 with
                         | FStar_Parser_AST.Construct (head1,args) ->
                             let uu____21392 =
                               match FStar_List.rev args with
                               | (last_arg,uu____21422)::args_rev ->
                                   let uu____21434 =
                                     let uu____21435 = unparen last_arg  in
                                     uu____21435.FStar_Parser_AST.tm  in
                                   (match uu____21434 with
                                    | FStar_Parser_AST.Attributes ts ->
                                        (ts, (FStar_List.rev args_rev))
                                    | uu____21463 -> ([], args))
                               | uu____21472 -> ([], args)  in
                             (match uu____21392 with
                              | (cattributes,args1) ->
                                  let uu____21511 =
                                    desugar_attributes env cattributes  in
                                  ((FStar_Parser_AST.mk_term
                                      (FStar_Parser_AST.Construct
                                         (head1, args1))
                                      t.FStar_Parser_AST.range
                                      t.FStar_Parser_AST.level), uu____21511))
                         | uu____21522 -> (t, [])  in
                       match uu____21363 with
                       | (t1,cattributes) ->
                           let c =
                             desugar_comp t1.FStar_Parser_AST.range false
                               env' t1
                              in
                           let typars1 =
                             FStar_Syntax_Subst.close_binders typars  in
                           let c1 = FStar_Syntax_Subst.close_comp typars1 c
                              in
                           let quals2 =
                             FStar_All.pipe_right quals1
                               (FStar_List.filter
                                  (fun uu___23_21545  ->
                                     match uu___23_21545 with
                                     | FStar_Syntax_Syntax.Effect  -> false
                                     | uu____21548 -> true))
                              in
                           {
                             FStar_Syntax_Syntax.sigel =
                               (FStar_Syntax_Syntax.Sig_effect_abbrev
                                  (qlid, [], typars1, c1,
                                    (FStar_List.append cattributes
                                       (FStar_Syntax_Util.comp_flags c1))));
                             FStar_Syntax_Syntax.sigrng = rng;
                             FStar_Syntax_Syntax.sigquals = quals2;
                             FStar_Syntax_Syntax.sigmeta =
                               FStar_Syntax_Syntax.default_sigmeta;
                             FStar_Syntax_Syntax.sigattrs = [];
                             FStar_Syntax_Syntax.sigopts =
                               FStar_Pervasives_Native.None
                           }
                     else
                       (let t1 = desugar_typ env' t  in
                        mk_typ_abbrev env d qlid [] typars kopt1 t1 [qlid]
                          quals1 rng)
                      in
                   let env1 = FStar_Syntax_DsEnv.push_sigelt env se  in
                   (env1, [se]))
          | (FStar_Parser_AST.TyconRecord uu____21556)::[] ->
              let trec = FStar_List.hd tcs  in
              let uu____21576 = tycon_record_as_variant trec  in
              (match uu____21576 with
               | (t,fs) ->
                   let uu____21593 =
                     let uu____21596 =
                       let uu____21597 =
                         let uu____21606 =
                           let uu____21609 =
                             FStar_Syntax_DsEnv.current_module env  in
                           FStar_Ident.ids_of_lid uu____21609  in
                         (uu____21606, fs)  in
                       FStar_Syntax_Syntax.RecordType uu____21597  in
                     uu____21596 :: quals  in
                   desugar_tycon env d uu____21593 [t])
          | uu____21614::uu____21615 ->
              let env0 = env  in
              let mutuals =
                FStar_List.map
                  (fun x  ->
                     FStar_All.pipe_left (FStar_Syntax_DsEnv.qualify env)
                       (tycon_id x)) tcs
                 in
              let rec collect_tcs quals1 et tc =
                let uu____21773 = et  in
                match uu____21773 with
                | (env1,tcs1) ->
                    (match tc with
                     | FStar_Parser_AST.TyconRecord uu____21983 ->
                         let trec = tc  in
                         let uu____22003 = tycon_record_as_variant trec  in
                         (match uu____22003 with
                          | (t,fs) ->
                              let uu____22059 =
                                let uu____22062 =
                                  let uu____22063 =
                                    let uu____22072 =
                                      let uu____22075 =
                                        FStar_Syntax_DsEnv.current_module
                                          env1
                                         in
                                      FStar_Ident.ids_of_lid uu____22075  in
                                    (uu____22072, fs)  in
                                  FStar_Syntax_Syntax.RecordType uu____22063
                                   in
                                uu____22062 :: quals1  in
                              collect_tcs uu____22059 (env1, tcs1) t)
                     | FStar_Parser_AST.TyconVariant
                         (id1,binders,kopt,constructors) ->
                         let uu____22153 =
                           desugar_abstract_tc quals1 env1 mutuals
                             (FStar_Parser_AST.TyconAbstract
                                (id1, binders, kopt))
                            in
                         (match uu____22153 with
                          | (env2,uu____22210,se,tconstr) ->
                              (env2,
                                ((FStar_Util.Inl
                                    (se, constructors, tconstr, quals1)) ::
                                tcs1)))
                     | FStar_Parser_AST.TyconAbbrev (id1,binders,kopt,t) ->
                         let uu____22347 =
                           desugar_abstract_tc quals1 env1 mutuals
                             (FStar_Parser_AST.TyconAbstract
                                (id1, binders, kopt))
                            in
                         (match uu____22347 with
                          | (env2,uu____22404,se,tconstr) ->
                              (env2,
                                ((FStar_Util.Inr (se, binders, t, quals1)) ::
                                tcs1)))
                     | uu____22520 ->
                         FStar_Errors.raise_error
                           (FStar_Errors.Fatal_NonInductiveInMutuallyDefinedType,
                             "Mutually defined type contains a non-inductive element")
                           rng)
                 in
              let uu____22566 =
                FStar_List.fold_left (collect_tcs quals) (env, []) tcs  in
              (match uu____22566 with
               | (env1,tcs1) ->
                   let tcs2 = FStar_List.rev tcs1  in
                   let tps_sigelts =
                     FStar_All.pipe_right tcs2
                       (FStar_List.collect
                          (fun uu___25_23018  ->
                             match uu___25_23018 with
                             | FStar_Util.Inr
                                 ({
                                    FStar_Syntax_Syntax.sigel =
                                      FStar_Syntax_Syntax.Sig_inductive_typ
                                      (id1,uvs,tpars,k,uu____23072,uu____23073);
                                    FStar_Syntax_Syntax.sigrng = uu____23074;
                                    FStar_Syntax_Syntax.sigquals =
                                      uu____23075;
                                    FStar_Syntax_Syntax.sigmeta = uu____23076;
                                    FStar_Syntax_Syntax.sigattrs =
                                      uu____23077;
                                    FStar_Syntax_Syntax.sigopts = uu____23078;_},binders,t,quals1)
                                 ->
                                 let t1 =
                                   let uu____23140 =
                                     typars_of_binders env1 binders  in
                                   match uu____23140 with
                                   | (env2,tpars1) ->
                                       let uu____23167 =
                                         push_tparams env2 tpars1  in
                                       (match uu____23167 with
                                        | (env_tps,tpars2) ->
                                            let t1 = desugar_typ env_tps t
                                               in
                                            let tpars3 =
                                              FStar_Syntax_Subst.close_binders
                                                tpars2
                                               in
                                            FStar_Syntax_Subst.close tpars3
                                              t1)
                                    in
                                 let uu____23196 =
                                   let uu____23207 =
                                     mk_typ_abbrev env1 d id1 uvs tpars
                                       (FStar_Pervasives_Native.Some k) t1
                                       [id1] quals1 rng
                                      in
                                   ([], uu____23207)  in
                                 [uu____23196]
                             | FStar_Util.Inl
                                 ({
                                    FStar_Syntax_Syntax.sigel =
                                      FStar_Syntax_Syntax.Sig_inductive_typ
                                      (tname,univs1,tpars,k,mutuals1,uu____23243);
                                    FStar_Syntax_Syntax.sigrng = uu____23244;
                                    FStar_Syntax_Syntax.sigquals =
                                      tname_quals;
                                    FStar_Syntax_Syntax.sigmeta = uu____23246;
                                    FStar_Syntax_Syntax.sigattrs =
                                      uu____23247;
                                    FStar_Syntax_Syntax.sigopts = uu____23248;_},constrs,tconstr,quals1)
                                 ->
                                 let mk_tot t =
                                   let tot1 =
                                     FStar_Parser_AST.mk_term
                                       (FStar_Parser_AST.Name
                                          FStar_Parser_Const.effect_Tot_lid)
                                       t.FStar_Parser_AST.range
                                       t.FStar_Parser_AST.level
                                      in
                                   FStar_Parser_AST.mk_term
                                     (FStar_Parser_AST.App
                                        (tot1, t, FStar_Parser_AST.Nothing))
                                     t.FStar_Parser_AST.range
                                     t.FStar_Parser_AST.level
                                    in
                                 let tycon = (tname, tpars, k)  in
                                 let uu____23339 = push_tparams env1 tpars
                                    in
                                 (match uu____23339 with
                                  | (env_tps,tps) ->
                                      let data_tpars =
                                        FStar_List.map
                                          (fun uu____23398  ->
                                             match uu____23398 with
                                             | (x,uu____23410) ->
                                                 (x,
                                                   (FStar_Pervasives_Native.Some
                                                      (FStar_Syntax_Syntax.Implicit
                                                         true)))) tps
                                         in
                                      let tot_tconstr = mk_tot tconstr  in
                                      let attrs =
                                        FStar_List.map (desugar_term env1)
                                          d.FStar_Parser_AST.attrs
                                         in
                                      let val_attrs =
                                        let uu____23421 =
                                          FStar_Syntax_DsEnv.lookup_letbinding_quals_and_attrs
                                            env1 tname
                                           in
                                        FStar_All.pipe_right uu____23421
                                          FStar_Pervasives_Native.snd
                                         in
                                      let uu____23444 =
                                        let uu____23463 =
                                          FStar_All.pipe_right constrs
                                            (FStar_List.map
                                               (fun uu____23540  ->
                                                  match uu____23540 with
                                                  | (id1,topt,of_notation) ->
                                                      let t =
                                                        if of_notation
                                                        then
                                                          match topt with
                                                          | FStar_Pervasives_Native.Some
                                                              t ->
                                                              FStar_Parser_AST.mk_term
                                                                (FStar_Parser_AST.Product
                                                                   ([
                                                                    FStar_Parser_AST.mk_binder
                                                                    (FStar_Parser_AST.NoName
                                                                    t)
                                                                    t.FStar_Parser_AST.range
                                                                    t.FStar_Parser_AST.level
                                                                    FStar_Pervasives_Native.None],
                                                                    tot_tconstr))
                                                                t.FStar_Parser_AST.range
                                                                t.FStar_Parser_AST.level
                                                          | FStar_Pervasives_Native.None
                                                               -> tconstr
                                                        else
                                                          (match topt with
                                                           | FStar_Pervasives_Native.None
                                                                ->
                                                               failwith
                                                                 "Impossible"
                                                           | FStar_Pervasives_Native.Some
                                                               t -> t)
                                                         in
                                                      let t1 =
                                                        let uu____23583 =
                                                          close env_tps t  in
                                                        desugar_term env_tps
                                                          uu____23583
                                                         in
                                                      let name =
                                                        FStar_Syntax_DsEnv.qualify
                                                          env1 id1
                                                         in
                                                      let quals2 =
                                                        FStar_All.pipe_right
                                                          tname_quals
                                                          (FStar_List.collect
                                                             (fun
                                                                uu___24_23594
                                                                 ->
                                                                match uu___24_23594
                                                                with
                                                                | FStar_Syntax_Syntax.RecordType
                                                                    fns ->
                                                                    [
                                                                    FStar_Syntax_Syntax.RecordConstructor
                                                                    fns]
                                                                | uu____23606
                                                                    -> []))
                                                         in
                                                      let ntps =
                                                        FStar_List.length
                                                          data_tpars
                                                         in
                                                      let uu____23614 =
                                                        let uu____23625 =
                                                          let uu____23626 =
                                                            let uu____23627 =
                                                              let uu____23643
                                                                =
                                                                let uu____23644
                                                                  =
                                                                  let uu____23647
                                                                    =
                                                                    FStar_All.pipe_right
                                                                    t1
                                                                    FStar_Syntax_Util.name_function_binders
                                                                     in
                                                                  FStar_Syntax_Syntax.mk_Total
                                                                    uu____23647
                                                                   in
                                                                FStar_Syntax_Util.arrow
                                                                  data_tpars
                                                                  uu____23644
                                                                 in
                                                              (name, univs1,
                                                                uu____23643,
                                                                tname, ntps,
                                                                mutuals1)
                                                               in
                                                            FStar_Syntax_Syntax.Sig_datacon
                                                              uu____23627
                                                             in
                                                          {
                                                            FStar_Syntax_Syntax.sigel
                                                              = uu____23626;
                                                            FStar_Syntax_Syntax.sigrng
                                                              = rng;
                                                            FStar_Syntax_Syntax.sigquals
                                                              = quals2;
                                                            FStar_Syntax_Syntax.sigmeta
                                                              =
                                                              FStar_Syntax_Syntax.default_sigmeta;
                                                            FStar_Syntax_Syntax.sigattrs
                                                              =
                                                              (FStar_List.append
                                                                 val_attrs
                                                                 attrs);
                                                            FStar_Syntax_Syntax.sigopts
                                                              =
                                                              FStar_Pervasives_Native.None
                                                          }  in
                                                        (tps, uu____23625)
                                                         in
                                                      (name, uu____23614)))
                                           in
                                        FStar_All.pipe_left FStar_List.split
                                          uu____23463
                                         in
                                      (match uu____23444 with
                                       | (constrNames,constrs1) ->
                                           ([],
                                             {
                                               FStar_Syntax_Syntax.sigel =
                                                 (FStar_Syntax_Syntax.Sig_inductive_typ
                                                    (tname, univs1, tpars, k,
                                                      mutuals1, constrNames));
                                               FStar_Syntax_Syntax.sigrng =
                                                 rng;
                                               FStar_Syntax_Syntax.sigquals =
                                                 tname_quals;
                                               FStar_Syntax_Syntax.sigmeta =
                                                 FStar_Syntax_Syntax.default_sigmeta;
                                               FStar_Syntax_Syntax.sigattrs =
                                                 (FStar_List.append val_attrs
                                                    attrs);
                                               FStar_Syntax_Syntax.sigopts =
                                                 FStar_Pervasives_Native.None
                                             })
                                           :: constrs1))
                             | uu____23779 -> failwith "impossible"))
                      in
                   let sigelts =
                     FStar_All.pipe_right tps_sigelts
                       (FStar_List.map
                          (fun uu____23860  ->
                             match uu____23860 with | (uu____23871,se) -> se))
                      in
                   let uu____23885 =
                     let uu____23892 =
                       FStar_List.collect FStar_Syntax_Util.lids_of_sigelt
                         sigelts
                        in
                     FStar_Syntax_MutRecTy.disentangle_abbrevs_from_bundle
                       sigelts quals uu____23892 rng
                      in
                   (match uu____23885 with
                    | (bundle,abbrevs) ->
                        let env2 = FStar_Syntax_DsEnv.push_sigelt env0 bundle
                           in
                        let env3 =
                          FStar_List.fold_left FStar_Syntax_DsEnv.push_sigelt
                            env2 abbrevs
                           in
                        let data_ops =
                          FStar_All.pipe_right tps_sigelts
                            (FStar_List.collect
                               (fun uu____23937  ->
                                  match uu____23937 with
                                  | (tps,se) ->
                                      mk_data_projector_names quals env3 se))
                           in
                        let discs =
                          FStar_All.pipe_right sigelts
                            (FStar_List.collect
                               (fun se  ->
                                  match se.FStar_Syntax_Syntax.sigel with
                                  | FStar_Syntax_Syntax.Sig_inductive_typ
                                      (tname,uu____23985,tps,k,uu____23988,constrs)
                                      ->
                                      let quals1 =
                                        se.FStar_Syntax_Syntax.sigquals  in
                                      let quals2 =
                                        if
                                          (FStar_List.contains
                                             FStar_Syntax_Syntax.Abstract
                                             quals1)
                                            &&
                                            (Prims.op_Negation
                                               (FStar_List.contains
                                                  FStar_Syntax_Syntax.Private
                                                  quals1))
                                        then FStar_Syntax_Syntax.Private ::
                                          quals1
                                        else quals1  in
                                      let uu____24009 =
                                        FStar_All.pipe_right constrs
                                          (FStar_List.filter
                                             (fun data_lid  ->
                                                let data_quals =
                                                  let data_se =
                                                    let uu____24024 =
                                                      FStar_All.pipe_right
                                                        sigelts
                                                        (FStar_List.find
                                                           (fun se1  ->
                                                              match se1.FStar_Syntax_Syntax.sigel
                                                              with
                                                              | FStar_Syntax_Syntax.Sig_datacon
                                                                  (name,uu____24041,uu____24042,uu____24043,uu____24044,uu____24045)
                                                                  ->
                                                                  FStar_Ident.lid_equals
                                                                    name
                                                                    data_lid
                                                              | uu____24052
                                                                  -> false))
                                                       in
                                                    FStar_All.pipe_right
                                                      uu____24024
                                                      FStar_Util.must
                                                     in
                                                  data_se.FStar_Syntax_Syntax.sigquals
                                                   in
                                                let uu____24056 =
                                                  FStar_All.pipe_right
                                                    data_quals
                                                    (FStar_List.existsb
                                                       (fun uu___26_24063  ->
                                                          match uu___26_24063
                                                          with
                                                          | FStar_Syntax_Syntax.RecordConstructor
                                                              uu____24065 ->
                                                              true
                                                          | uu____24075 ->
                                                              false))
                                                   in
                                                Prims.op_Negation uu____24056))
                                         in
                                      mk_data_discriminators quals2 env3
                                        uu____24009
                                  | uu____24077 -> []))
                           in
                        let ops = FStar_List.append discs data_ops  in
                        let env4 =
                          FStar_List.fold_left FStar_Syntax_DsEnv.push_sigelt
                            env3 ops
                           in
                        (env4,
                          (FStar_List.append [bundle]
                             (FStar_List.append abbrevs ops)))))
          | [] -> failwith "impossible"
  
let (desugar_binders :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.binder Prims.list ->
      (FStar_Syntax_DsEnv.env * (FStar_Syntax_Syntax.bv *
        FStar_Syntax_Syntax.arg_qualifier FStar_Pervasives_Native.option)
        Prims.list))
  =
  fun env  ->
    fun binders  ->
      let uu____24114 =
        FStar_List.fold_left
          (fun uu____24149  ->
             fun b  ->
               match uu____24149 with
               | (env1,binders1) ->
                   let uu____24193 = desugar_binder env1 b  in
                   (match uu____24193 with
                    | (FStar_Pervasives_Native.Some a,k) ->
                        let uu____24216 =
                          as_binder env1 b.FStar_Parser_AST.aqual
                            ((FStar_Pervasives_Native.Some a), k)
                           in
                        (match uu____24216 with
                         | (binder,env2) -> (env2, (binder :: binders1)))
                    | uu____24269 ->
                        FStar_Errors.raise_error
                          (FStar_Errors.Fatal_MissingNameInBinder,
                            "Missing name in binder")
                          b.FStar_Parser_AST.brange)) (env, []) binders
         in
      match uu____24114 with
      | (env1,binders1) -> (env1, (FStar_List.rev binders1))
  
let (push_reflect_effect :
  FStar_Syntax_DsEnv.env ->
    FStar_Syntax_Syntax.qualifier Prims.list ->
      FStar_Ident.lid -> FStar_Range.range -> FStar_Syntax_DsEnv.env)
  =
  fun env  ->
    fun quals  ->
      fun effect_name  ->
        fun range  ->
          let uu____24373 =
            FStar_All.pipe_right quals
              (FStar_Util.for_some
                 (fun uu___27_24380  ->
                    match uu___27_24380 with
                    | FStar_Syntax_Syntax.Reflectable uu____24382 -> true
                    | uu____24384 -> false))
             in
          if uu____24373
          then
            let monad_env =
              FStar_Syntax_DsEnv.enter_monad_scope env
                effect_name.FStar_Ident.ident
               in
            let reflect_lid =
              let uu____24389 = FStar_Ident.id_of_text "reflect"  in
              FStar_All.pipe_right uu____24389
                (FStar_Syntax_DsEnv.qualify monad_env)
               in
            let quals1 =
              [FStar_Syntax_Syntax.Assumption;
              FStar_Syntax_Syntax.Reflectable effect_name]  in
            let refl_decl =
              {
                FStar_Syntax_Syntax.sigel =
                  (FStar_Syntax_Syntax.Sig_declare_typ
                     (reflect_lid, [], FStar_Syntax_Syntax.tun));
                FStar_Syntax_Syntax.sigrng = range;
                FStar_Syntax_Syntax.sigquals = quals1;
                FStar_Syntax_Syntax.sigmeta =
                  FStar_Syntax_Syntax.default_sigmeta;
                FStar_Syntax_Syntax.sigattrs = [];
                FStar_Syntax_Syntax.sigopts = FStar_Pervasives_Native.None
              }  in
            FStar_Syntax_DsEnv.push_sigelt env refl_decl
          else env
  
let (parse_attr_with_list :
  Prims.bool ->
    FStar_Syntax_Syntax.term ->
      FStar_Ident.lident ->
        (Prims.int Prims.list FStar_Pervasives_Native.option * Prims.bool))
  =
  fun warn  ->
    fun at  ->
      fun head1  ->
        let warn1 uu____24440 =
          if warn
          then
            let uu____24442 =
              let uu____24448 =
                let uu____24450 = FStar_Ident.string_of_lid head1  in
                FStar_Util.format1
                  "Found ill-applied '%s', argument should be a non-empty list of integer literals"
                  uu____24450
                 in
              (FStar_Errors.Warning_UnappliedFail, uu____24448)  in
            FStar_Errors.log_issue at.FStar_Syntax_Syntax.pos uu____24442
          else ()  in
        let uu____24456 = FStar_Syntax_Util.head_and_args at  in
        match uu____24456 with
        | (hd1,args) ->
            let uu____24509 =
              let uu____24510 = FStar_Syntax_Subst.compress hd1  in
              uu____24510.FStar_Syntax_Syntax.n  in
            (match uu____24509 with
             | FStar_Syntax_Syntax.Tm_fvar fv when
                 FStar_Syntax_Syntax.fv_eq_lid fv head1 ->
                 (match args with
                  | [] -> ((FStar_Pervasives_Native.Some []), true)
                  | (a1,uu____24554)::[] ->
                      let uu____24579 =
                        let uu____24584 =
                          let uu____24593 =
                            FStar_Syntax_Embeddings.e_list
                              FStar_Syntax_Embeddings.e_int
                             in
                          FStar_Syntax_Embeddings.unembed uu____24593 a1  in
                        uu____24584 true FStar_Syntax_Embeddings.id_norm_cb
                         in
                      (match uu____24579 with
                       | FStar_Pervasives_Native.Some es ->
                           let uu____24616 =
                             let uu____24622 =
                               FStar_List.map FStar_BigInt.to_int_fs es  in
                             FStar_Pervasives_Native.Some uu____24622  in
                           (uu____24616, true)
                       | uu____24637 ->
                           (warn1 (); (FStar_Pervasives_Native.None, true)))
                  | uu____24653 ->
                      (warn1 (); (FStar_Pervasives_Native.None, true)))
             | uu____24675 -> (FStar_Pervasives_Native.None, false))
  
let (get_fail_attr :
  Prims.bool ->
    FStar_Syntax_Syntax.term ->
      (Prims.int Prims.list * Prims.bool) FStar_Pervasives_Native.option)
  =
  fun warn  ->
    fun at  ->
      let rebind res b =
        match res with
        | FStar_Pervasives_Native.None  -> FStar_Pervasives_Native.None
        | FStar_Pervasives_Native.Some l ->
            FStar_Pervasives_Native.Some (l, b)
         in
      let uu____24792 =
        parse_attr_with_list warn at FStar_Parser_Const.fail_attr  in
      match uu____24792 with
      | (res,matched) ->
          if matched
          then rebind res false
          else
            (let uu____24841 =
               parse_attr_with_list warn at FStar_Parser_Const.fail_lax_attr
                in
             match uu____24841 with | (res1,uu____24863) -> rebind res1 true)
  
let (lookup_effect_lid :
  FStar_Syntax_DsEnv.env ->
    FStar_Ident.lident -> FStar_Range.range -> FStar_Syntax_Syntax.eff_decl)
  =
  fun env  ->
    fun l  ->
      fun r  ->
        let uu____24893 = FStar_Syntax_DsEnv.try_lookup_effect_defn env l  in
        match uu____24893 with
        | FStar_Pervasives_Native.None  ->
            let uu____24896 =
              let uu____24902 =
                let uu____24904 =
                  let uu____24906 = FStar_Syntax_Print.lid_to_string l  in
                  Prims.op_Hat uu____24906 " not found"  in
                Prims.op_Hat "Effect name " uu____24904  in
              (FStar_Errors.Fatal_EffectNotFound, uu____24902)  in
            FStar_Errors.raise_error uu____24896 r
        | FStar_Pervasives_Native.Some l1 -> l1
  
let rec (desugar_effect :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.decl ->
      FStar_Parser_AST.qualifiers ->
        Prims.bool ->
          FStar_Ident.ident ->
            FStar_Parser_AST.binder Prims.list ->
              FStar_Parser_AST.term ->
                FStar_Parser_AST.decl Prims.list ->
                  FStar_Parser_AST.term Prims.list ->
                    (FStar_Syntax_DsEnv.env * FStar_Syntax_Syntax.sigelt
                      Prims.list))
  =
  fun env  ->
    fun d  ->
      fun quals  ->
        fun is_layered1  ->
          fun eff_name  ->
            fun eff_binders  ->
              fun eff_typ  ->
                fun eff_decls  ->
                  fun attrs  ->
                    let env0 = env  in
                    let monad_env =
                      FStar_Syntax_DsEnv.enter_monad_scope env eff_name  in
                    let uu____25062 = desugar_binders monad_env eff_binders
                       in
                    match uu____25062 with
                    | (env1,binders) ->
                        let eff_t = desugar_term env1 eff_typ  in
                        let num_indices =
                          let uu____25101 =
                            let uu____25110 =
                              FStar_Syntax_Util.arrow_formals eff_t  in
                            FStar_Pervasives_Native.fst uu____25110  in
                          FStar_List.length uu____25101  in
                        (if is_layered1 && (num_indices <= Prims.int_one)
                         then
                           (let uu____25144 =
                              let uu____25150 =
                                let uu____25152 =
                                  let uu____25154 =
                                    FStar_Ident.text_of_id eff_name  in
                                  Prims.op_Hat uu____25154
                                    "is defined as a layered effect but has no indices"
                                   in
                                Prims.op_Hat "Effect " uu____25152  in
                              (FStar_Errors.Fatal_NotEnoughArgumentsForEffect,
                                uu____25150)
                               in
                            FStar_Errors.raise_error uu____25144
                              d.FStar_Parser_AST.drange)
                         else ();
                         (let for_free = num_indices = Prims.int_one  in
                          let mandatory_members =
                            let rr_members = ["repr"; "return"; "bind"]  in
                            if for_free
                            then rr_members
                            else
                              if is_layered1
                              then
                                FStar_List.append rr_members
                                  ["subcomp"; "if_then_else"]
                              else
                                FStar_List.append rr_members
                                  ["return_wp";
                                  "bind_wp";
                                  "if_then_else";
                                  "ite_wp";
                                  "stronger";
                                  "close_wp";
                                  "trivial"]
                             in
                          let name_of_eff_decl decl =
                            match decl.FStar_Parser_AST.d with
                            | FStar_Parser_AST.Tycon
                                (uu____25222,uu____25223,(FStar_Parser_AST.TyconAbbrev
                                 (name,uu____25225,uu____25226,uu____25227))::[])
                                -> FStar_Ident.text_of_id name
                            | uu____25242 ->
                                failwith
                                  "Malformed effect member declaration."
                             in
                          let uu____25245 =
                            FStar_List.partition
                              (fun decl  ->
                                 let uu____25257 = name_of_eff_decl decl  in
                                 FStar_List.mem uu____25257 mandatory_members)
                              eff_decls
                             in
                          match uu____25245 with
                          | (mandatory_members_decls,actions) ->
                              let uu____25276 =
                                FStar_All.pipe_right mandatory_members_decls
                                  (FStar_List.fold_left
                                     (fun uu____25305  ->
                                        fun decl  ->
                                          match uu____25305 with
                                          | (env2,out) ->
                                              let uu____25325 =
                                                desugar_decl env2 decl  in
                                              (match uu____25325 with
                                               | (env3,ses) ->
                                                   let uu____25338 =
                                                     let uu____25341 =
                                                       FStar_List.hd ses  in
                                                     uu____25341 :: out  in
                                                   (env3, uu____25338)))
                                     (env1, []))
                                 in
                              (match uu____25276 with
                               | (env2,decls) ->
                                   let binders1 =
                                     FStar_Syntax_Subst.close_binders binders
                                      in
                                   let actions1 =
                                     FStar_All.pipe_right actions
                                       (FStar_List.map
                                          (fun d1  ->
                                             match d1.FStar_Parser_AST.d with
                                             | FStar_Parser_AST.Tycon
                                                 (uu____25387,uu____25388,(FStar_Parser_AST.TyconAbbrev
                                                  (name,action_params,uu____25391,
                                                   {
                                                     FStar_Parser_AST.tm =
                                                       FStar_Parser_AST.Construct
                                                       (uu____25392,(def,uu____25394)::
                                                        (cps_type,uu____25396)::[]);
                                                     FStar_Parser_AST.range =
                                                       uu____25397;
                                                     FStar_Parser_AST.level =
                                                       uu____25398;_}))::[])
                                                 when
                                                 Prims.op_Negation for_free
                                                 ->
                                                 let uu____25431 =
                                                   desugar_binders env2
                                                     action_params
                                                    in
                                                 (match uu____25431 with
                                                  | (env3,action_params1) ->
                                                      let action_params2 =
                                                        FStar_Syntax_Subst.close_binders
                                                          action_params1
                                                         in
                                                      let uu____25463 =
                                                        FStar_Syntax_DsEnv.qualify
                                                          env3 name
                                                         in
                                                      let uu____25464 =
                                                        let uu____25465 =
                                                          desugar_term env3
                                                            def
                                                           in
                                                        FStar_Syntax_Subst.close
                                                          (FStar_List.append
                                                             binders1
                                                             action_params2)
                                                          uu____25465
                                                         in
                                                      let uu____25472 =
                                                        let uu____25473 =
                                                          desugar_typ env3
                                                            cps_type
                                                           in
                                                        FStar_Syntax_Subst.close
                                                          (FStar_List.append
                                                             binders1
                                                             action_params2)
                                                          uu____25473
                                                         in
                                                      {
                                                        FStar_Syntax_Syntax.action_name
                                                          = uu____25463;
                                                        FStar_Syntax_Syntax.action_unqualified_name
                                                          = name;
                                                        FStar_Syntax_Syntax.action_univs
                                                          = [];
                                                        FStar_Syntax_Syntax.action_params
                                                          = action_params2;
                                                        FStar_Syntax_Syntax.action_defn
                                                          = uu____25464;
                                                        FStar_Syntax_Syntax.action_typ
                                                          = uu____25472
                                                      })
                                             | FStar_Parser_AST.Tycon
                                                 (uu____25480,uu____25481,(FStar_Parser_AST.TyconAbbrev
                                                  (name,action_params,uu____25484,defn))::[])
                                                 when for_free || is_layered1
                                                 ->
                                                 let uu____25500 =
                                                   desugar_binders env2
                                                     action_params
                                                    in
                                                 (match uu____25500 with
                                                  | (env3,action_params1) ->
                                                      let action_params2 =
                                                        FStar_Syntax_Subst.close_binders
                                                          action_params1
                                                         in
                                                      let uu____25532 =
                                                        FStar_Syntax_DsEnv.qualify
                                                          env3 name
                                                         in
                                                      let uu____25533 =
                                                        let uu____25534 =
                                                          desugar_term env3
                                                            defn
                                                           in
                                                        FStar_Syntax_Subst.close
                                                          (FStar_List.append
                                                             binders1
                                                             action_params2)
                                                          uu____25534
                                                         in
                                                      {
                                                        FStar_Syntax_Syntax.action_name
                                                          = uu____25532;
                                                        FStar_Syntax_Syntax.action_unqualified_name
                                                          = name;
                                                        FStar_Syntax_Syntax.action_univs
                                                          = [];
                                                        FStar_Syntax_Syntax.action_params
                                                          = action_params2;
                                                        FStar_Syntax_Syntax.action_defn
                                                          = uu____25533;
                                                        FStar_Syntax_Syntax.action_typ
                                                          =
                                                          FStar_Syntax_Syntax.tun
                                                      })
                                             | uu____25541 ->
                                                 FStar_Errors.raise_error
                                                   (FStar_Errors.Fatal_MalformedActionDeclaration,
                                                     "Malformed action declaration; if this is an \"effect for free\", just provide the direct-style declaration. If this is not an \"effect for free\", please provide a pair of the definition and its cps-type with arrows inserted in the right place (see examples).")
                                                   d1.FStar_Parser_AST.drange))
                                      in
                                   let eff_t1 =
                                     FStar_Syntax_Subst.close binders1 eff_t
                                      in
                                   let lookup1 s =
                                     let l =
                                       let uu____25560 =
                                         FStar_Ident.mk_ident
                                           (s, (d.FStar_Parser_AST.drange))
                                          in
                                       FStar_Syntax_DsEnv.qualify env2
                                         uu____25560
                                        in
                                     let uu____25562 =
                                       let uu____25563 =
                                         FStar_Syntax_DsEnv.fail_or env2
                                           (FStar_Syntax_DsEnv.try_lookup_definition
                                              env2) l
                                          in
                                       FStar_All.pipe_left
                                         (FStar_Syntax_Subst.close binders1)
                                         uu____25563
                                        in
                                     ([], uu____25562)  in
                                   let mname =
                                     FStar_Syntax_DsEnv.qualify env0 eff_name
                                      in
                                   let qualifiers =
                                     FStar_List.map
                                       (trans_qual d.FStar_Parser_AST.drange
                                          (FStar_Pervasives_Native.Some mname))
                                       quals
                                      in
                                   let dummy_tscheme =
                                     ([], FStar_Syntax_Syntax.tun)  in
                                   let combinators =
                                     if for_free
                                     then
                                       let uu____25585 =
                                         let uu____25586 =
                                           let uu____25589 = lookup1 "repr"
                                              in
                                           FStar_Pervasives_Native.Some
                                             uu____25589
                                            in
                                         let uu____25591 =
                                           let uu____25594 = lookup1 "return"
                                              in
                                           FStar_Pervasives_Native.Some
                                             uu____25594
                                            in
                                         let uu____25596 =
                                           let uu____25599 = lookup1 "bind"
                                              in
                                           FStar_Pervasives_Native.Some
                                             uu____25599
                                            in
                                         {
                                           FStar_Syntax_Syntax.ret_wp =
                                             dummy_tscheme;
                                           FStar_Syntax_Syntax.bind_wp =
                                             dummy_tscheme;
                                           FStar_Syntax_Syntax.stronger =
                                             dummy_tscheme;
                                           FStar_Syntax_Syntax.if_then_else =
                                             dummy_tscheme;
                                           FStar_Syntax_Syntax.ite_wp =
                                             dummy_tscheme;
                                           FStar_Syntax_Syntax.close_wp =
                                             dummy_tscheme;
                                           FStar_Syntax_Syntax.trivial =
                                             dummy_tscheme;
                                           FStar_Syntax_Syntax.repr =
                                             uu____25586;
                                           FStar_Syntax_Syntax.return_repr =
                                             uu____25591;
                                           FStar_Syntax_Syntax.bind_repr =
                                             uu____25596
                                         }  in
                                       FStar_Syntax_Syntax.DM4F_eff
                                         uu____25585
                                     else
                                       if is_layered1
                                       then
                                         (let to_comb uu____25633 =
                                            match uu____25633 with
                                            | (us,t) ->
                                                ((us, t), dummy_tscheme)
                                             in
                                          let uu____25680 =
                                            let uu____25681 =
                                              FStar_Ident.lid_of_str ""  in
                                            let uu____25683 =
                                              let uu____25688 =
                                                lookup1 "repr"  in
                                              FStar_All.pipe_right
                                                uu____25688 to_comb
                                               in
                                            let uu____25706 =
                                              let uu____25711 =
                                                lookup1 "return"  in
                                              FStar_All.pipe_right
                                                uu____25711 to_comb
                                               in
                                            let uu____25729 =
                                              let uu____25734 =
                                                lookup1 "bind"  in
                                              FStar_All.pipe_right
                                                uu____25734 to_comb
                                               in
                                            let uu____25752 =
                                              let uu____25757 =
                                                lookup1 "subcomp"  in
                                              FStar_All.pipe_right
                                                uu____25757 to_comb
                                               in
                                            let uu____25775 =
                                              let uu____25780 =
                                                lookup1 "if_then_else"  in
                                              FStar_All.pipe_right
                                                uu____25780 to_comb
                                               in
                                            {
                                              FStar_Syntax_Syntax.l_base_effect
                                                = uu____25681;
                                              FStar_Syntax_Syntax.l_repr =
                                                uu____25683;
                                              FStar_Syntax_Syntax.l_return =
                                                uu____25706;
                                              FStar_Syntax_Syntax.l_bind =
                                                uu____25729;
                                              FStar_Syntax_Syntax.l_subcomp =
                                                uu____25752;
                                              FStar_Syntax_Syntax.l_if_then_else
                                                = uu____25775
                                            }  in
                                          FStar_Syntax_Syntax.Layered_eff
                                            uu____25680)
                                       else
                                         (let rr =
                                            FStar_Util.for_some
                                              (fun uu___28_25803  ->
                                                 match uu___28_25803 with
                                                 | FStar_Syntax_Syntax.Reifiable
                                                      -> true
                                                 | FStar_Syntax_Syntax.Reflectable
                                                     uu____25806 -> true
                                                 | uu____25808 -> false)
                                              qualifiers
                                             in
                                          let uu____25810 =
                                            let uu____25811 =
                                              lookup1 "return_wp"  in
                                            let uu____25813 =
                                              lookup1 "bind_wp"  in
                                            let uu____25815 =
                                              lookup1 "stronger"  in
                                            let uu____25817 =
                                              lookup1 "if_then_else"  in
                                            let uu____25819 =
                                              lookup1 "ite_wp"  in
                                            let uu____25821 =
                                              lookup1 "close_wp"  in
                                            let uu____25823 =
                                              lookup1 "trivial"  in
                                            let uu____25825 =
                                              if rr
                                              then
                                                let uu____25831 =
                                                  lookup1 "repr"  in
                                                FStar_Pervasives_Native.Some
                                                  uu____25831
                                              else
                                                FStar_Pervasives_Native.None
                                               in
                                            let uu____25835 =
                                              if rr
                                              then
                                                let uu____25841 =
                                                  lookup1 "return"  in
                                                FStar_Pervasives_Native.Some
                                                  uu____25841
                                              else
                                                FStar_Pervasives_Native.None
                                               in
                                            let uu____25845 =
                                              if rr
                                              then
                                                let uu____25851 =
                                                  lookup1 "bind"  in
                                                FStar_Pervasives_Native.Some
                                                  uu____25851
                                              else
                                                FStar_Pervasives_Native.None
                                               in
                                            {
                                              FStar_Syntax_Syntax.ret_wp =
                                                uu____25811;
                                              FStar_Syntax_Syntax.bind_wp =
                                                uu____25813;
                                              FStar_Syntax_Syntax.stronger =
                                                uu____25815;
                                              FStar_Syntax_Syntax.if_then_else
                                                = uu____25817;
                                              FStar_Syntax_Syntax.ite_wp =
                                                uu____25819;
                                              FStar_Syntax_Syntax.close_wp =
                                                uu____25821;
                                              FStar_Syntax_Syntax.trivial =
                                                uu____25823;
                                              FStar_Syntax_Syntax.repr =
                                                uu____25825;
                                              FStar_Syntax_Syntax.return_repr
                                                = uu____25835;
                                              FStar_Syntax_Syntax.bind_repr =
                                                uu____25845
                                            }  in
                                          FStar_Syntax_Syntax.Primitive_eff
                                            uu____25810)
                                      in
                                   let sigel =
                                     let uu____25856 =
                                       let uu____25857 =
                                         FStar_List.map (desugar_term env2)
                                           attrs
                                          in
                                       {
                                         FStar_Syntax_Syntax.mname = mname;
                                         FStar_Syntax_Syntax.cattributes = [];
                                         FStar_Syntax_Syntax.univs = [];
                                         FStar_Syntax_Syntax.binders =
                                           binders1;
                                         FStar_Syntax_Syntax.signature =
                                           ([], eff_t1);
                                         FStar_Syntax_Syntax.combinators =
                                           combinators;
                                         FStar_Syntax_Syntax.actions =
                                           actions1;
                                         FStar_Syntax_Syntax.eff_attrs =
                                           uu____25857
                                       }  in
                                     FStar_Syntax_Syntax.Sig_new_effect
                                       uu____25856
                                      in
                                   let se =
                                     {
                                       FStar_Syntax_Syntax.sigel = sigel;
                                       FStar_Syntax_Syntax.sigrng =
                                         (d.FStar_Parser_AST.drange);
                                       FStar_Syntax_Syntax.sigquals =
                                         qualifiers;
                                       FStar_Syntax_Syntax.sigmeta =
                                         FStar_Syntax_Syntax.default_sigmeta;
                                       FStar_Syntax_Syntax.sigattrs = [];
                                       FStar_Syntax_Syntax.sigopts =
                                         FStar_Pervasives_Native.None
                                     }  in
                                   let env3 =
                                     FStar_Syntax_DsEnv.push_sigelt env0 se
                                      in
                                   let env4 =
                                     FStar_All.pipe_right actions1
                                       (FStar_List.fold_left
                                          (fun env4  ->
                                             fun a  ->
                                               let uu____25874 =
                                                 FStar_Syntax_Util.action_as_lb
                                                   mname a
                                                   (a.FStar_Syntax_Syntax.action_defn).FStar_Syntax_Syntax.pos
                                                  in
                                               FStar_Syntax_DsEnv.push_sigelt
                                                 env4 uu____25874) env3)
                                      in
                                   let env5 =
                                     push_reflect_effect env4 qualifiers
                                       mname d.FStar_Parser_AST.drange
                                      in
                                   (env5, [se]))))

and (desugar_redefine_effect :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.decl ->
      (FStar_Ident.lident FStar_Pervasives_Native.option ->
         FStar_Parser_AST.qualifier -> FStar_Syntax_Syntax.qualifier)
        ->
        FStar_Parser_AST.qualifier Prims.list ->
          FStar_Ident.ident ->
            FStar_Parser_AST.binder Prims.list ->
              FStar_Parser_AST.term ->
                (FStar_Syntax_DsEnv.env * FStar_Syntax_Syntax.sigelt
                  Prims.list))
  =
  fun env  ->
    fun d  ->
      fun trans_qual1  ->
        fun quals  ->
          fun eff_name  ->
            fun eff_binders  ->
              fun defn  ->
                let env0 = env  in
                let env1 = FStar_Syntax_DsEnv.enter_monad_scope env eff_name
                   in
                let uu____25897 = desugar_binders env1 eff_binders  in
                match uu____25897 with
                | (env2,binders) ->
                    let uu____25934 =
                      let uu____25945 = head_and_args defn  in
                      match uu____25945 with
                      | (head1,args) ->
                          let lid =
                            match head1.FStar_Parser_AST.tm with
                            | FStar_Parser_AST.Name l -> l
                            | uu____25982 ->
                                let uu____25983 =
                                  let uu____25989 =
                                    let uu____25991 =
                                      let uu____25993 =
                                        FStar_Parser_AST.term_to_string head1
                                         in
                                      Prims.op_Hat uu____25993 " not found"
                                       in
                                    Prims.op_Hat "Effect " uu____25991  in
                                  (FStar_Errors.Fatal_EffectNotFound,
                                    uu____25989)
                                   in
                                FStar_Errors.raise_error uu____25983
                                  d.FStar_Parser_AST.drange
                             in
                          let ed =
                            FStar_Syntax_DsEnv.fail_or env2
                              (FStar_Syntax_DsEnv.try_lookup_effect_defn env2)
                              lid
                             in
                          let uu____25999 =
                            match FStar_List.rev args with
                            | (last_arg,uu____26029)::args_rev ->
                                let uu____26041 =
                                  let uu____26042 = unparen last_arg  in
                                  uu____26042.FStar_Parser_AST.tm  in
                                (match uu____26041 with
                                 | FStar_Parser_AST.Attributes ts ->
                                     (ts, (FStar_List.rev args_rev))
                                 | uu____26070 -> ([], args))
                            | uu____26079 -> ([], args)  in
                          (match uu____25999 with
                           | (cattributes,args1) ->
                               let uu____26122 = desugar_args env2 args1  in
                               let uu____26123 =
                                 desugar_attributes env2 cattributes  in
                               (lid, ed, uu____26122, uu____26123))
                       in
                    (match uu____25934 with
                     | (ed_lid,ed,args,cattributes) ->
                         let binders1 =
                           FStar_Syntax_Subst.close_binders binders  in
                         (if
                            (FStar_List.length args) <>
                              (FStar_List.length
                                 ed.FStar_Syntax_Syntax.binders)
                          then
                            FStar_Errors.raise_error
                              (FStar_Errors.Fatal_ArgumentLengthMismatch,
                                "Unexpected number of arguments to effect constructor")
                              defn.FStar_Parser_AST.range
                          else ();
                          (let uu____26163 =
                             FStar_Syntax_Subst.open_term'
                               ed.FStar_Syntax_Syntax.binders
                               FStar_Syntax_Syntax.t_unit
                              in
                           match uu____26163 with
                           | (ed_binders,uu____26177,ed_binders_opening) ->
                               let sub' shift_n uu____26196 =
                                 match uu____26196 with
                                 | (us,x) ->
                                     let x1 =
                                       let uu____26211 =
                                         FStar_Syntax_Subst.shift_subst
                                           (shift_n + (FStar_List.length us))
                                           ed_binders_opening
                                          in
                                       FStar_Syntax_Subst.subst uu____26211 x
                                        in
                                     let s =
                                       FStar_Syntax_Util.subst_of_list
                                         ed_binders args
                                        in
                                     let uu____26215 =
                                       let uu____26216 =
                                         FStar_Syntax_Subst.subst s x1  in
                                       (us, uu____26216)  in
                                     FStar_Syntax_Subst.close_tscheme
                                       binders1 uu____26215
                                  in
                               let sub1 = sub' Prims.int_zero  in
                               let mname =
                                 FStar_Syntax_DsEnv.qualify env0 eff_name  in
                               let ed1 =
                                 let uu____26237 =
                                   sub1 ed.FStar_Syntax_Syntax.signature  in
                                 let uu____26238 =
                                   FStar_Syntax_Util.apply_eff_combinators
                                     sub1 ed.FStar_Syntax_Syntax.combinators
                                    in
                                 let uu____26239 =
                                   FStar_List.map
                                     (fun action  ->
                                        let nparam =
                                          FStar_List.length
                                            action.FStar_Syntax_Syntax.action_params
                                           in
                                        let uu____26255 =
                                          FStar_Syntax_DsEnv.qualify env2
                                            action.FStar_Syntax_Syntax.action_unqualified_name
                                           in
                                        let uu____26256 =
                                          let uu____26257 =
                                            sub' nparam
                                              ([],
                                                (action.FStar_Syntax_Syntax.action_defn))
                                             in
                                          FStar_Pervasives_Native.snd
                                            uu____26257
                                           in
                                        let uu____26272 =
                                          let uu____26273 =
                                            sub' nparam
                                              ([],
                                                (action.FStar_Syntax_Syntax.action_typ))
                                             in
                                          FStar_Pervasives_Native.snd
                                            uu____26273
                                           in
                                        {
                                          FStar_Syntax_Syntax.action_name =
                                            uu____26255;
                                          FStar_Syntax_Syntax.action_unqualified_name
                                            =
                                            (action.FStar_Syntax_Syntax.action_unqualified_name);
                                          FStar_Syntax_Syntax.action_univs =
                                            (action.FStar_Syntax_Syntax.action_univs);
                                          FStar_Syntax_Syntax.action_params =
                                            (action.FStar_Syntax_Syntax.action_params);
                                          FStar_Syntax_Syntax.action_defn =
                                            uu____26256;
                                          FStar_Syntax_Syntax.action_typ =
                                            uu____26272
                                        }) ed.FStar_Syntax_Syntax.actions
                                    in
                                 {
                                   FStar_Syntax_Syntax.mname = mname;
                                   FStar_Syntax_Syntax.cattributes =
                                     cattributes;
                                   FStar_Syntax_Syntax.univs =
                                     (ed.FStar_Syntax_Syntax.univs);
                                   FStar_Syntax_Syntax.binders = binders1;
                                   FStar_Syntax_Syntax.signature =
                                     uu____26237;
                                   FStar_Syntax_Syntax.combinators =
                                     uu____26238;
                                   FStar_Syntax_Syntax.actions = uu____26239;
                                   FStar_Syntax_Syntax.eff_attrs =
                                     (ed.FStar_Syntax_Syntax.eff_attrs)
                                 }  in
                               let se =
                                 let uu____26289 =
                                   let uu____26292 =
                                     trans_qual1
                                       (FStar_Pervasives_Native.Some mname)
                                      in
                                   FStar_List.map uu____26292 quals  in
                                 {
                                   FStar_Syntax_Syntax.sigel =
                                     (FStar_Syntax_Syntax.Sig_new_effect ed1);
                                   FStar_Syntax_Syntax.sigrng =
                                     (d.FStar_Parser_AST.drange);
                                   FStar_Syntax_Syntax.sigquals = uu____26289;
                                   FStar_Syntax_Syntax.sigmeta =
                                     FStar_Syntax_Syntax.default_sigmeta;
                                   FStar_Syntax_Syntax.sigattrs = [];
                                   FStar_Syntax_Syntax.sigopts =
                                     FStar_Pervasives_Native.None
                                 }  in
                               let monad_env = env2  in
                               let env3 =
                                 FStar_Syntax_DsEnv.push_sigelt env0 se  in
                               let env4 =
                                 FStar_All.pipe_right
                                   ed1.FStar_Syntax_Syntax.actions
                                   (FStar_List.fold_left
                                      (fun env4  ->
                                         fun a  ->
                                           let uu____26307 =
                                             FStar_Syntax_Util.action_as_lb
                                               mname a
                                               (a.FStar_Syntax_Syntax.action_defn).FStar_Syntax_Syntax.pos
                                              in
                                           FStar_Syntax_DsEnv.push_sigelt
                                             env4 uu____26307) env3)
                                  in
                               let env5 =
                                 let uu____26309 =
                                   FStar_All.pipe_right quals
                                     (FStar_List.contains
                                        FStar_Parser_AST.Reflectable)
                                    in
                                 if uu____26309
                                 then
                                   let reflect_lid =
                                     let uu____26316 =
                                       FStar_Ident.id_of_text "reflect"  in
                                     FStar_All.pipe_right uu____26316
                                       (FStar_Syntax_DsEnv.qualify monad_env)
                                      in
                                   let quals1 =
                                     [FStar_Syntax_Syntax.Assumption;
                                     FStar_Syntax_Syntax.Reflectable mname]
                                      in
                                   let refl_decl =
                                     {
                                       FStar_Syntax_Syntax.sigel =
                                         (FStar_Syntax_Syntax.Sig_declare_typ
                                            (reflect_lid, [],
                                              FStar_Syntax_Syntax.tun));
                                       FStar_Syntax_Syntax.sigrng =
                                         (d.FStar_Parser_AST.drange);
                                       FStar_Syntax_Syntax.sigquals = quals1;
                                       FStar_Syntax_Syntax.sigmeta =
                                         FStar_Syntax_Syntax.default_sigmeta;
                                       FStar_Syntax_Syntax.sigattrs = [];
                                       FStar_Syntax_Syntax.sigopts =
                                         FStar_Pervasives_Native.None
                                     }  in
                                   FStar_Syntax_DsEnv.push_sigelt env4
                                     refl_decl
                                 else env4  in
                               (env5, [se]))))

and (desugar_decl_aux :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.decl -> (env_t * FStar_Syntax_Syntax.sigelts))
  =
  fun env  ->
    fun d  ->
      let env0 =
        let uu____26333 = FStar_Syntax_DsEnv.snapshot env  in
        FStar_All.pipe_right uu____26333 FStar_Pervasives_Native.snd  in
      let uu____26345 = desugar_decl_noattrs env d  in
      match uu____26345 with
      | (env1,sigelts) ->
          let attrs =
            FStar_List.map (desugar_term env1) d.FStar_Parser_AST.attrs  in
          let val_attrs =
            match sigelts with
            | {
                FStar_Syntax_Syntax.sigel = FStar_Syntax_Syntax.Sig_let
                  uu____26364;
                FStar_Syntax_Syntax.sigrng = uu____26365;
                FStar_Syntax_Syntax.sigquals = uu____26366;
                FStar_Syntax_Syntax.sigmeta = uu____26367;
                FStar_Syntax_Syntax.sigattrs = uu____26368;
                FStar_Syntax_Syntax.sigopts = uu____26369;_}::[] ->
                let uu____26382 =
                  let uu____26385 =
                    let uu____26388 = FStar_List.hd sigelts  in
                    FStar_Syntax_Util.lids_of_sigelt uu____26388  in
                  FStar_All.pipe_right uu____26385
                    (FStar_List.collect
                       (fun nm  ->
                          let uu____26396 =
                            FStar_Syntax_DsEnv.lookup_letbinding_quals_and_attrs
                              env0 nm
                             in
                          FStar_Pervasives_Native.snd uu____26396))
                   in
                FStar_All.pipe_right uu____26382
                  (FStar_List.filter
                     (fun t  ->
                        let uu____26416 = get_fail_attr false t  in
                        FStar_Option.isNone uu____26416))
            | {
                FStar_Syntax_Syntax.sigel =
                  FStar_Syntax_Syntax.Sig_inductive_typ uu____26436;
                FStar_Syntax_Syntax.sigrng = uu____26437;
                FStar_Syntax_Syntax.sigquals = uu____26438;
                FStar_Syntax_Syntax.sigmeta = uu____26439;
                FStar_Syntax_Syntax.sigattrs = uu____26440;
                FStar_Syntax_Syntax.sigopts = uu____26441;_}::uu____26442 ->
                let uu____26467 =
                  let uu____26470 =
                    let uu____26473 = FStar_List.hd sigelts  in
                    FStar_Syntax_Util.lids_of_sigelt uu____26473  in
                  FStar_All.pipe_right uu____26470
                    (FStar_List.collect
                       (fun nm  ->
                          let uu____26481 =
                            FStar_Syntax_DsEnv.lookup_letbinding_quals_and_attrs
                              env0 nm
                             in
                          FStar_Pervasives_Native.snd uu____26481))
                   in
                FStar_All.pipe_right uu____26467
                  (FStar_List.filter
                     (fun t  ->
                        let uu____26501 = get_fail_attr false t  in
                        FStar_Option.isNone uu____26501))
            | uu____26521 -> []  in
          let attrs1 = FStar_List.append attrs val_attrs  in
          let uu____26525 =
            FStar_List.mapi
              (fun i  ->
                 fun sigelt  ->
                   if i = Prims.int_zero
                   then
                     let uu___3411_26535 = sigelt  in
                     {
                       FStar_Syntax_Syntax.sigel =
                         (uu___3411_26535.FStar_Syntax_Syntax.sigel);
                       FStar_Syntax_Syntax.sigrng =
                         (uu___3411_26535.FStar_Syntax_Syntax.sigrng);
                       FStar_Syntax_Syntax.sigquals =
                         (uu___3411_26535.FStar_Syntax_Syntax.sigquals);
                       FStar_Syntax_Syntax.sigmeta =
                         (uu___3411_26535.FStar_Syntax_Syntax.sigmeta);
                       FStar_Syntax_Syntax.sigattrs = attrs1;
                       FStar_Syntax_Syntax.sigopts =
                         (uu___3411_26535.FStar_Syntax_Syntax.sigopts)
                     }
                   else
                     (let uu___3413_26538 = sigelt  in
                      let uu____26539 =
                        FStar_List.filter
                          (fun at  ->
                             let uu____26545 = get_fail_attr false at  in
                             FStar_Option.isNone uu____26545) attrs1
                         in
                      {
                        FStar_Syntax_Syntax.sigel =
                          (uu___3413_26538.FStar_Syntax_Syntax.sigel);
                        FStar_Syntax_Syntax.sigrng =
                          (uu___3413_26538.FStar_Syntax_Syntax.sigrng);
                        FStar_Syntax_Syntax.sigquals =
                          (uu___3413_26538.FStar_Syntax_Syntax.sigquals);
                        FStar_Syntax_Syntax.sigmeta =
                          (uu___3413_26538.FStar_Syntax_Syntax.sigmeta);
                        FStar_Syntax_Syntax.sigattrs = uu____26539;
                        FStar_Syntax_Syntax.sigopts =
                          (uu___3413_26538.FStar_Syntax_Syntax.sigopts)
                      })) sigelts
             in
          (env1, uu____26525)

and (desugar_decl :
  env_t -> FStar_Parser_AST.decl -> (env_t * FStar_Syntax_Syntax.sigelts)) =
  fun env  ->
    fun d  ->
      let uu____26571 = desugar_decl_aux env d  in
      match uu____26571 with
      | (env1,ses) ->
          let uu____26582 =
            FStar_All.pipe_right ses
              (FStar_List.map generalize_annotated_univs)
             in
          (env1, uu____26582)

and (desugar_decl_noattrs :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.decl -> (env_t * FStar_Syntax_Syntax.sigelts))
  =
  fun env  ->
    fun d  ->
      let trans_qual1 = trans_qual d.FStar_Parser_AST.drange  in
      match d.FStar_Parser_AST.d with
      | FStar_Parser_AST.Pragma p ->
          let p1 = trans_pragma p  in
          (FStar_Syntax_Util.process_pragma p1 d.FStar_Parser_AST.drange;
           (let se =
              {
                FStar_Syntax_Syntax.sigel =
                  (FStar_Syntax_Syntax.Sig_pragma p1);
                FStar_Syntax_Syntax.sigrng = (d.FStar_Parser_AST.drange);
                FStar_Syntax_Syntax.sigquals = [];
                FStar_Syntax_Syntax.sigmeta =
                  FStar_Syntax_Syntax.default_sigmeta;
                FStar_Syntax_Syntax.sigattrs = [];
                FStar_Syntax_Syntax.sigopts = FStar_Pervasives_Native.None
              }  in
            (env, [se])))
      | FStar_Parser_AST.TopLevelModule id1 -> (env, [])
      | FStar_Parser_AST.Open lid ->
          let env1 = FStar_Syntax_DsEnv.push_namespace env lid  in (env1, [])
      | FStar_Parser_AST.Friend lid ->
          let uu____26614 = FStar_Syntax_DsEnv.iface env  in
          if uu____26614
          then
            FStar_Errors.raise_error
              (FStar_Errors.Fatal_FriendInterface,
                "'friend' declarations are not allowed in interfaces")
              d.FStar_Parser_AST.drange
          else
            (let uu____26629 =
               let uu____26631 =
                 let uu____26633 = FStar_Syntax_DsEnv.dep_graph env  in
                 let uu____26634 = FStar_Syntax_DsEnv.current_module env  in
                 FStar_Parser_Dep.module_has_interface uu____26633
                   uu____26634
                  in
               Prims.op_Negation uu____26631  in
             if uu____26629
             then
               FStar_Errors.raise_error
                 (FStar_Errors.Fatal_FriendInterface,
                   "'friend' declarations are not allowed in modules that lack interfaces")
                 d.FStar_Parser_AST.drange
             else
               (let uu____26648 =
                  let uu____26650 =
                    let uu____26652 = FStar_Syntax_DsEnv.dep_graph env  in
                    FStar_Parser_Dep.module_has_interface uu____26652 lid  in
                  Prims.op_Negation uu____26650  in
                if uu____26648
                then
                  FStar_Errors.raise_error
                    (FStar_Errors.Fatal_FriendInterface,
                      "'friend' declarations cannot refer to modules that lack interfaces")
                    d.FStar_Parser_AST.drange
                else
                  (let uu____26666 =
                     let uu____26668 =
                       let uu____26670 = FStar_Syntax_DsEnv.dep_graph env  in
                       FStar_Parser_Dep.deps_has_implementation uu____26670
                         lid
                        in
                     Prims.op_Negation uu____26668  in
                   if uu____26666
                   then
                     FStar_Errors.raise_error
                       (FStar_Errors.Fatal_FriendInterface,
                         "'friend' module has not been loaded; recompute dependences (C-c C-r) if in interactive mode")
                       d.FStar_Parser_AST.drange
                   else (env, []))))
      | FStar_Parser_AST.Include lid ->
          let env1 = FStar_Syntax_DsEnv.push_include env lid  in (env1, [])
      | FStar_Parser_AST.ModuleAbbrev (x,l) ->
          let uu____26688 = FStar_Syntax_DsEnv.push_module_abbrev env x l  in
          (uu____26688, [])
      | FStar_Parser_AST.Tycon (is_effect,typeclass,tcs) ->
          let quals = d.FStar_Parser_AST.quals  in
          let quals1 =
            if is_effect
            then FStar_Parser_AST.Effect_qual :: quals
            else quals  in
          let quals2 =
            if typeclass
            then
              match tcs with
              | (FStar_Parser_AST.TyconRecord uu____26717)::[] ->
                  FStar_Parser_AST.Noeq :: quals1
              | uu____26736 ->
                  FStar_Errors.raise_error
                    (FStar_Errors.Error_BadClassDecl,
                      "Ill-formed `class` declaration: definition must be a record type")
                    d.FStar_Parser_AST.drange
            else quals1  in
          let uu____26745 =
            let uu____26750 =
              FStar_List.map (trans_qual1 FStar_Pervasives_Native.None)
                quals2
               in
            desugar_tycon env d uu____26750 tcs  in
          (match uu____26745 with
           | (env1,ses) ->
               let mkclass lid =
                 let uu____26767 =
                   let uu____26768 =
                     let uu____26775 =
                       FStar_Syntax_Syntax.new_bv
                         FStar_Pervasives_Native.None FStar_Syntax_Syntax.tun
                        in
                     FStar_Syntax_Syntax.mk_binder uu____26775  in
                   [uu____26768]  in
                 let uu____26788 =
                   let uu____26791 =
                     FStar_Syntax_Syntax.tabbrev
                       FStar_Parser_Const.mk_class_lid
                      in
                   let uu____26794 =
                     let uu____26805 =
                       let uu____26814 =
                         let uu____26815 = FStar_Ident.string_of_lid lid  in
                         FStar_Syntax_Util.exp_string uu____26815  in
                       FStar_Syntax_Syntax.as_arg uu____26814  in
                     [uu____26805]  in
                   FStar_Syntax_Util.mk_app uu____26791 uu____26794  in
                 FStar_Syntax_Util.abs uu____26767 uu____26788
                   FStar_Pervasives_Native.None
                  in
               let get_meths se =
                 let rec get_fname quals3 =
                   match quals3 with
                   | (FStar_Syntax_Syntax.Projector
                       (uu____26855,id1))::uu____26857 ->
                       FStar_Pervasives_Native.Some id1
                   | uu____26860::quals4 -> get_fname quals4
                   | [] -> FStar_Pervasives_Native.None  in
                 let uu____26864 = get_fname se.FStar_Syntax_Syntax.sigquals
                    in
                 match uu____26864 with
                 | FStar_Pervasives_Native.None  -> []
                 | FStar_Pervasives_Native.Some id1 ->
                     let uu____26870 = FStar_Syntax_DsEnv.qualify env1 id1
                        in
                     [uu____26870]
                  in
               let rec splice_decl meths se =
                 match se.FStar_Syntax_Syntax.sigel with
                 | FStar_Syntax_Syntax.Sig_bundle (ses1,uu____26891) ->
                     FStar_List.concatMap (splice_decl meths) ses1
                 | FStar_Syntax_Syntax.Sig_inductive_typ
                     (lid,uu____26901,uu____26902,uu____26903,uu____26904,uu____26905)
                     ->
                     let uu____26914 =
                       let uu____26915 =
                         let uu____26916 =
                           let uu____26923 = mkclass lid  in
                           (meths, uu____26923)  in
                         FStar_Syntax_Syntax.Sig_splice uu____26916  in
                       {
                         FStar_Syntax_Syntax.sigel = uu____26915;
                         FStar_Syntax_Syntax.sigrng =
                           (d.FStar_Parser_AST.drange);
                         FStar_Syntax_Syntax.sigquals = [];
                         FStar_Syntax_Syntax.sigmeta =
                           FStar_Syntax_Syntax.default_sigmeta;
                         FStar_Syntax_Syntax.sigattrs = [];
                         FStar_Syntax_Syntax.sigopts =
                           FStar_Pervasives_Native.None
                       }  in
                     [uu____26914]
                 | uu____26926 -> []  in
               let extra =
                 if typeclass
                 then
                   let meths = FStar_List.concatMap get_meths ses  in
                   FStar_List.concatMap (splice_decl meths) ses
                 else []  in
               let env2 =
                 FStar_List.fold_left FStar_Syntax_DsEnv.push_sigelt env1
                   extra
                  in
               (env2, (FStar_List.append ses extra)))
      | FStar_Parser_AST.TopLevelLet (isrec,lets) ->
          let quals = d.FStar_Parser_AST.quals  in
          let expand_toplevel_pattern =
            (isrec = FStar_Parser_AST.NoLetQualifier) &&
              (match lets with
               | ({
                    FStar_Parser_AST.pat = FStar_Parser_AST.PatOp uu____26960;
                    FStar_Parser_AST.prange = uu____26961;_},uu____26962)::[]
                   -> false
               | ({
                    FStar_Parser_AST.pat = FStar_Parser_AST.PatVar
                      uu____26972;
                    FStar_Parser_AST.prange = uu____26973;_},uu____26974)::[]
                   -> false
               | ({
                    FStar_Parser_AST.pat = FStar_Parser_AST.PatAscribed
                      ({
                         FStar_Parser_AST.pat = FStar_Parser_AST.PatOp
                           uu____26990;
                         FStar_Parser_AST.prange = uu____26991;_},uu____26992);
                    FStar_Parser_AST.prange = uu____26993;_},uu____26994)::[]
                   -> false
               | ({
                    FStar_Parser_AST.pat = FStar_Parser_AST.PatAscribed
                      ({
                         FStar_Parser_AST.pat = FStar_Parser_AST.PatVar
                           uu____27016;
                         FStar_Parser_AST.prange = uu____27017;_},uu____27018);
                    FStar_Parser_AST.prange = uu____27019;_},uu____27020)::[]
                   -> false
               | (p,uu____27049)::[] ->
                   let uu____27058 = is_app_pattern p  in
                   Prims.op_Negation uu____27058
               | uu____27060 -> false)
             in
          if Prims.op_Negation expand_toplevel_pattern
          then
            let lets1 =
              FStar_List.map (fun x  -> (FStar_Pervasives_Native.None, x))
                lets
               in
            let as_inner_let =
              FStar_Parser_AST.mk_term
                (FStar_Parser_AST.Let
                   (isrec, lets1,
                     (FStar_Parser_AST.mk_term
                        (FStar_Parser_AST.Const FStar_Const.Const_unit)
                        d.FStar_Parser_AST.drange FStar_Parser_AST.Expr)))
                d.FStar_Parser_AST.drange FStar_Parser_AST.Expr
               in
            let uu____27135 = desugar_term_maybe_top true env as_inner_let
               in
            (match uu____27135 with
             | (ds_lets,aq) ->
                 (check_no_aq aq;
                  (let uu____27148 =
                     let uu____27149 =
                       FStar_All.pipe_left FStar_Syntax_Subst.compress
                         ds_lets
                        in
                     uu____27149.FStar_Syntax_Syntax.n  in
                   match uu____27148 with
                   | FStar_Syntax_Syntax.Tm_let (lbs,uu____27159) ->
                       let fvs =
                         FStar_All.pipe_right
                           (FStar_Pervasives_Native.snd lbs)
                           (FStar_List.map
                              (fun lb  ->
                                 FStar_Util.right
                                   lb.FStar_Syntax_Syntax.lbname))
                          in
                       let uu____27190 =
                         FStar_List.fold_right
                           (fun fv  ->
                              fun uu____27215  ->
                                match uu____27215 with
                                | (qs,ats) ->
                                    let uu____27242 =
                                      FStar_Syntax_DsEnv.lookup_letbinding_quals_and_attrs
                                        env
                                        (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v
                                       in
                                    (match uu____27242 with
                                     | (qs',ats') ->
                                         ((FStar_List.append qs' qs),
                                           (FStar_List.append ats' ats))))
                           fvs ([], [])
                          in
                       (match uu____27190 with
                        | (val_quals,val_attrs) ->
                            let quals1 =
                              match quals with
                              | uu____27296::uu____27297 ->
                                  FStar_List.map
                                    (trans_qual1 FStar_Pervasives_Native.None)
                                    quals
                              | uu____27300 -> val_quals  in
                            let quals2 =
                              let uu____27304 =
                                FStar_All.pipe_right lets1
                                  (FStar_Util.for_some
                                     (fun uu____27337  ->
                                        match uu____27337 with
                                        | (uu____27351,(uu____27352,t)) ->
                                            t.FStar_Parser_AST.level =
                                              FStar_Parser_AST.Formula))
                                 in
                              if uu____27304
                              then FStar_Syntax_Syntax.Logic :: quals1
                              else quals1  in
                            let lbs1 =
                              let uu____27372 =
                                FStar_All.pipe_right quals2
                                  (FStar_List.contains
                                     FStar_Syntax_Syntax.Abstract)
                                 in
                              if uu____27372
                              then
                                let uu____27378 =
                                  FStar_All.pipe_right
                                    (FStar_Pervasives_Native.snd lbs)
                                    (FStar_List.map
                                       (fun lb  ->
                                          let fv =
                                            FStar_Util.right
                                              lb.FStar_Syntax_Syntax.lbname
                                             in
                                          let uu___3591_27393 = lb  in
                                          {
                                            FStar_Syntax_Syntax.lbname =
                                              (FStar_Util.Inr
                                                 (let uu___3593_27395 = fv
                                                     in
                                                  {
                                                    FStar_Syntax_Syntax.fv_name
                                                      =
                                                      (uu___3593_27395.FStar_Syntax_Syntax.fv_name);
                                                    FStar_Syntax_Syntax.fv_delta
                                                      =
                                                      (FStar_Syntax_Syntax.Delta_abstract
                                                         (fv.FStar_Syntax_Syntax.fv_delta));
                                                    FStar_Syntax_Syntax.fv_qual
                                                      =
                                                      (uu___3593_27395.FStar_Syntax_Syntax.fv_qual)
                                                  }));
                                            FStar_Syntax_Syntax.lbunivs =
                                              (uu___3591_27393.FStar_Syntax_Syntax.lbunivs);
                                            FStar_Syntax_Syntax.lbtyp =
                                              (uu___3591_27393.FStar_Syntax_Syntax.lbtyp);
                                            FStar_Syntax_Syntax.lbeff =
                                              (uu___3591_27393.FStar_Syntax_Syntax.lbeff);
                                            FStar_Syntax_Syntax.lbdef =
                                              (uu___3591_27393.FStar_Syntax_Syntax.lbdef);
                                            FStar_Syntax_Syntax.lbattrs =
                                              (uu___3591_27393.FStar_Syntax_Syntax.lbattrs);
                                            FStar_Syntax_Syntax.lbpos =
                                              (uu___3591_27393.FStar_Syntax_Syntax.lbpos)
                                          }))
                                   in
                                ((FStar_Pervasives_Native.fst lbs),
                                  uu____27378)
                              else lbs  in
                            let names1 =
                              FStar_All.pipe_right fvs
                                (FStar_List.map
                                   (fun fv  ->
                                      (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v))
                               in
                            let attrs =
                              FStar_List.map (desugar_term env)
                                d.FStar_Parser_AST.attrs
                               in
                            let s =
                              {
                                FStar_Syntax_Syntax.sigel =
                                  (FStar_Syntax_Syntax.Sig_let (lbs1, names1));
                                FStar_Syntax_Syntax.sigrng =
                                  (d.FStar_Parser_AST.drange);
                                FStar_Syntax_Syntax.sigquals = quals2;
                                FStar_Syntax_Syntax.sigmeta =
                                  FStar_Syntax_Syntax.default_sigmeta;
                                FStar_Syntax_Syntax.sigattrs =
                                  (FStar_List.append val_attrs attrs);
                                FStar_Syntax_Syntax.sigopts =
                                  FStar_Pervasives_Native.None
                              }  in
                            let env1 = FStar_Syntax_DsEnv.push_sigelt env s
                               in
                            (env1, [s]))
                   | uu____27420 ->
                       failwith "Desugaring a let did not produce a let")))
          else
            (let uu____27428 =
               match lets with
               | (pat,body)::[] -> (pat, body)
               | uu____27447 ->
                   failwith
                     "expand_toplevel_pattern should only allow single definition lets"
                in
             match uu____27428 with
             | (pat,body) ->
                 let fresh_toplevel_name =
                   FStar_Ident.gen FStar_Range.dummyRange  in
                 let fresh_pat =
                   let var_pat =
                     FStar_Parser_AST.mk_pattern
                       (FStar_Parser_AST.PatVar
                          (fresh_toplevel_name, FStar_Pervasives_Native.None))
                       FStar_Range.dummyRange
                      in
                   match pat.FStar_Parser_AST.pat with
                   | FStar_Parser_AST.PatAscribed (pat1,ty) ->
                       let uu___3616_27484 = pat1  in
                       {
                         FStar_Parser_AST.pat =
                           (FStar_Parser_AST.PatAscribed (var_pat, ty));
                         FStar_Parser_AST.prange =
                           (uu___3616_27484.FStar_Parser_AST.prange)
                       }
                   | uu____27491 -> var_pat  in
                 let main_let =
                   desugar_decl env
                     (let uu___3620_27498 = d  in
                      {
                        FStar_Parser_AST.d =
                          (FStar_Parser_AST.TopLevelLet
                             (isrec, [(fresh_pat, body)]));
                        FStar_Parser_AST.drange =
                          (uu___3620_27498.FStar_Parser_AST.drange);
                        FStar_Parser_AST.quals = (FStar_Parser_AST.Private ::
                          (d.FStar_Parser_AST.quals));
                        FStar_Parser_AST.attrs =
                          (uu___3620_27498.FStar_Parser_AST.attrs)
                      })
                    in
                 let build_projection uu____27534 id1 =
                   match uu____27534 with
                   | (env1,ses) ->
                       let main =
                         let uu____27555 =
                           let uu____27556 =
                             FStar_Ident.lid_of_ids [fresh_toplevel_name]  in
                           FStar_Parser_AST.Var uu____27556  in
                         FStar_Parser_AST.mk_term uu____27555
                           FStar_Range.dummyRange FStar_Parser_AST.Expr
                          in
                       let lid = FStar_Ident.lid_of_ids [id1]  in
                       let projectee =
                         FStar_Parser_AST.mk_term (FStar_Parser_AST.Var lid)
                           FStar_Range.dummyRange FStar_Parser_AST.Expr
                          in
                       let body1 =
                         FStar_Parser_AST.mk_term
                           (FStar_Parser_AST.Match
                              (main,
                                [(pat, FStar_Pervasives_Native.None,
                                   projectee)])) FStar_Range.dummyRange
                           FStar_Parser_AST.Expr
                          in
                       let bv_pat =
                         FStar_Parser_AST.mk_pattern
                           (FStar_Parser_AST.PatVar
                              (id1, FStar_Pervasives_Native.None))
                           FStar_Range.dummyRange
                          in
                       let id_decl =
                         FStar_Parser_AST.mk_decl
                           (FStar_Parser_AST.TopLevelLet
                              (FStar_Parser_AST.NoLetQualifier,
                                [(bv_pat, body1)])) FStar_Range.dummyRange []
                          in
                       let uu____27606 = desugar_decl env1 id_decl  in
                       (match uu____27606 with
                        | (env2,ses') -> (env2, (FStar_List.append ses ses')))
                    in
                 let bvs =
                   let uu____27624 = gather_pattern_bound_vars true pat  in
                   FStar_All.pipe_right uu____27624 FStar_Util.set_elements
                    in
                 FStar_List.fold_left build_projection main_let bvs)
      | FStar_Parser_AST.Main t ->
          let e = desugar_term env t  in
          let se =
            {
              FStar_Syntax_Syntax.sigel = (FStar_Syntax_Syntax.Sig_main e);
              FStar_Syntax_Syntax.sigrng = (d.FStar_Parser_AST.drange);
              FStar_Syntax_Syntax.sigquals = [];
              FStar_Syntax_Syntax.sigmeta =
                FStar_Syntax_Syntax.default_sigmeta;
              FStar_Syntax_Syntax.sigattrs = [];
              FStar_Syntax_Syntax.sigopts = FStar_Pervasives_Native.None
            }  in
          (env, [se])
      | FStar_Parser_AST.Assume (id1,t) ->
          let f = desugar_formula env t  in
          let lid = FStar_Syntax_DsEnv.qualify env id1  in
          (env,
            [{
               FStar_Syntax_Syntax.sigel =
                 (FStar_Syntax_Syntax.Sig_assume (lid, [], f));
               FStar_Syntax_Syntax.sigrng = (d.FStar_Parser_AST.drange);
               FStar_Syntax_Syntax.sigquals =
                 [FStar_Syntax_Syntax.Assumption];
               FStar_Syntax_Syntax.sigmeta =
                 FStar_Syntax_Syntax.default_sigmeta;
               FStar_Syntax_Syntax.sigattrs = [];
               FStar_Syntax_Syntax.sigopts = FStar_Pervasives_Native.None
             }])
      | FStar_Parser_AST.Val (id1,t) ->
          let quals = d.FStar_Parser_AST.quals  in
          let t1 =
            let uu____27647 = close_fun env t  in
            desugar_term env uu____27647  in
          let quals1 =
            let uu____27651 =
              (FStar_Syntax_DsEnv.iface env) &&
                (FStar_Syntax_DsEnv.admitted_iface env)
               in
            if uu____27651
            then FStar_Parser_AST.Assumption :: quals
            else quals  in
          let lid = FStar_Syntax_DsEnv.qualify env id1  in
          let attrs =
            FStar_List.map (desugar_term env) d.FStar_Parser_AST.attrs  in
          let se =
            let uu____27663 =
              FStar_List.map (trans_qual1 FStar_Pervasives_Native.None)
                quals1
               in
            {
              FStar_Syntax_Syntax.sigel =
                (FStar_Syntax_Syntax.Sig_declare_typ (lid, [], t1));
              FStar_Syntax_Syntax.sigrng = (d.FStar_Parser_AST.drange);
              FStar_Syntax_Syntax.sigquals = uu____27663;
              FStar_Syntax_Syntax.sigmeta =
                FStar_Syntax_Syntax.default_sigmeta;
              FStar_Syntax_Syntax.sigattrs = attrs;
              FStar_Syntax_Syntax.sigopts = FStar_Pervasives_Native.None
            }  in
          let env1 = FStar_Syntax_DsEnv.push_sigelt env se  in (env1, [se])
      | FStar_Parser_AST.Exception (id1,t_opt) ->
          let t =
            match t_opt with
            | FStar_Pervasives_Native.None  ->
                FStar_Syntax_DsEnv.fail_or env
                  (FStar_Syntax_DsEnv.try_lookup_lid env)
                  FStar_Parser_Const.exn_lid
            | FStar_Pervasives_Native.Some term ->
                let t = desugar_term env term  in
                let uu____27676 =
                  let uu____27685 = FStar_Syntax_Syntax.null_binder t  in
                  [uu____27685]  in
                let uu____27704 =
                  let uu____27707 =
                    FStar_Syntax_DsEnv.fail_or env
                      (FStar_Syntax_DsEnv.try_lookup_lid env)
                      FStar_Parser_Const.exn_lid
                     in
                  FStar_All.pipe_left FStar_Syntax_Syntax.mk_Total
                    uu____27707
                   in
                FStar_Syntax_Util.arrow uu____27676 uu____27704
             in
          let l = FStar_Syntax_DsEnv.qualify env id1  in
          let qual = [FStar_Syntax_Syntax.ExceptionConstructor]  in
          let se =
            {
              FStar_Syntax_Syntax.sigel =
                (FStar_Syntax_Syntax.Sig_datacon
                   (l, [], t, FStar_Parser_Const.exn_lid, Prims.int_zero,
                     [FStar_Parser_Const.exn_lid]));
              FStar_Syntax_Syntax.sigrng = (d.FStar_Parser_AST.drange);
              FStar_Syntax_Syntax.sigquals = qual;
              FStar_Syntax_Syntax.sigmeta =
                FStar_Syntax_Syntax.default_sigmeta;
              FStar_Syntax_Syntax.sigattrs = [];
              FStar_Syntax_Syntax.sigopts = FStar_Pervasives_Native.None
            }  in
          let se' =
            {
              FStar_Syntax_Syntax.sigel =
                (FStar_Syntax_Syntax.Sig_bundle ([se], [l]));
              FStar_Syntax_Syntax.sigrng = (d.FStar_Parser_AST.drange);
              FStar_Syntax_Syntax.sigquals = qual;
              FStar_Syntax_Syntax.sigmeta =
                FStar_Syntax_Syntax.default_sigmeta;
              FStar_Syntax_Syntax.sigattrs = [];
              FStar_Syntax_Syntax.sigopts = FStar_Pervasives_Native.None
            }  in
          let env1 = FStar_Syntax_DsEnv.push_sigelt env se'  in
          let data_ops = mk_data_projector_names [] env1 se  in
          let discs = mk_data_discriminators [] env1 [l]  in
          let env2 =
            FStar_List.fold_left FStar_Syntax_DsEnv.push_sigelt env1
              (FStar_List.append discs data_ops)
             in
          (env2, (FStar_List.append (se' :: discs) data_ops))
      | FStar_Parser_AST.NewEffect (FStar_Parser_AST.RedefineEffect
          (eff_name,eff_binders,defn)) ->
          let quals = d.FStar_Parser_AST.quals  in
          desugar_redefine_effect env d trans_qual1 quals eff_name
            eff_binders defn
      | FStar_Parser_AST.NewEffect (FStar_Parser_AST.DefineEffect
          (eff_name,eff_binders,eff_typ,eff_decls)) ->
          let quals = d.FStar_Parser_AST.quals  in
          let attrs = d.FStar_Parser_AST.attrs  in
          desugar_effect env d quals false eff_name eff_binders eff_typ
            eff_decls attrs
      | FStar_Parser_AST.LayeredEffect (FStar_Parser_AST.DefineEffect
          (eff_name,eff_binders,eff_typ,eff_decls)) ->
          let quals = d.FStar_Parser_AST.quals  in
          let attrs = d.FStar_Parser_AST.attrs  in
          desugar_effect env d quals true eff_name eff_binders eff_typ
            eff_decls attrs
      | FStar_Parser_AST.SubEffect l ->
          let src_ed =
            lookup_effect_lid env l.FStar_Parser_AST.msource
              d.FStar_Parser_AST.drange
             in
          let dst_ed =
            lookup_effect_lid env l.FStar_Parser_AST.mdest
              d.FStar_Parser_AST.drange
             in
          let uu____27773 =
            let uu____27775 =
              (FStar_Syntax_Util.is_layered src_ed) ||
                (FStar_Syntax_Util.is_layered dst_ed)
               in
            Prims.op_Negation uu____27775  in
          if uu____27773
          then
            let uu____27782 =
              match l.FStar_Parser_AST.lift_op with
              | FStar_Parser_AST.NonReifiableLift t ->
                  let uu____27800 =
                    let uu____27803 =
                      let uu____27804 = desugar_term env t  in
                      ([], uu____27804)  in
                    FStar_Pervasives_Native.Some uu____27803  in
                  (uu____27800, FStar_Pervasives_Native.None)
              | FStar_Parser_AST.ReifiableLift (wp,t) ->
                  let uu____27817 =
                    let uu____27820 =
                      let uu____27821 = desugar_term env wp  in
                      ([], uu____27821)  in
                    FStar_Pervasives_Native.Some uu____27820  in
                  let uu____27828 =
                    let uu____27831 =
                      let uu____27832 = desugar_term env t  in
                      ([], uu____27832)  in
                    FStar_Pervasives_Native.Some uu____27831  in
                  (uu____27817, uu____27828)
              | FStar_Parser_AST.LiftForFree t ->
                  let uu____27844 =
                    let uu____27847 =
                      let uu____27848 = desugar_term env t  in
                      ([], uu____27848)  in
                    FStar_Pervasives_Native.Some uu____27847  in
                  (FStar_Pervasives_Native.None, uu____27844)
               in
            (match uu____27782 with
             | (lift_wp,lift) ->
                 let se =
                   {
                     FStar_Syntax_Syntax.sigel =
                       (FStar_Syntax_Syntax.Sig_sub_effect
                          {
                            FStar_Syntax_Syntax.source =
                              (src_ed.FStar_Syntax_Syntax.mname);
                            FStar_Syntax_Syntax.target =
                              (dst_ed.FStar_Syntax_Syntax.mname);
                            FStar_Syntax_Syntax.lift_wp = lift_wp;
                            FStar_Syntax_Syntax.lift = lift
                          });
                     FStar_Syntax_Syntax.sigrng = (d.FStar_Parser_AST.drange);
                     FStar_Syntax_Syntax.sigquals = [];
                     FStar_Syntax_Syntax.sigmeta =
                       FStar_Syntax_Syntax.default_sigmeta;
                     FStar_Syntax_Syntax.sigattrs = [];
                     FStar_Syntax_Syntax.sigopts =
                       FStar_Pervasives_Native.None
                   }  in
                 (env, [se]))
          else
            (match l.FStar_Parser_AST.lift_op with
             | FStar_Parser_AST.NonReifiableLift t ->
                 let sub_eff =
                   let uu____27882 =
                     let uu____27885 =
                       let uu____27886 = desugar_term env t  in
                       ([], uu____27886)  in
                     FStar_Pervasives_Native.Some uu____27885  in
                   {
                     FStar_Syntax_Syntax.source =
                       (src_ed.FStar_Syntax_Syntax.mname);
                     FStar_Syntax_Syntax.target =
                       (dst_ed.FStar_Syntax_Syntax.mname);
                     FStar_Syntax_Syntax.lift_wp =
                       FStar_Pervasives_Native.None;
                     FStar_Syntax_Syntax.lift = uu____27882
                   }  in
                 (env,
                   [{
                      FStar_Syntax_Syntax.sigel =
                        (FStar_Syntax_Syntax.Sig_sub_effect sub_eff);
                      FStar_Syntax_Syntax.sigrng =
                        (d.FStar_Parser_AST.drange);
                      FStar_Syntax_Syntax.sigquals = [];
                      FStar_Syntax_Syntax.sigmeta =
                        FStar_Syntax_Syntax.default_sigmeta;
                      FStar_Syntax_Syntax.sigattrs = [];
                      FStar_Syntax_Syntax.sigopts =
                        FStar_Pervasives_Native.None
                    }])
             | uu____27893 ->
                 failwith
                   "Impossible! unexpected lift_op for lift to a layered effect")
      | FStar_Parser_AST.Polymonadic_bind (m_eff,n_eff,p_eff,bind1) ->
          let m = lookup_effect_lid env m_eff d.FStar_Parser_AST.drange  in
          let n1 = lookup_effect_lid env n_eff d.FStar_Parser_AST.drange  in
          let p = lookup_effect_lid env p_eff d.FStar_Parser_AST.drange  in
          let uu____27906 =
            let uu____27907 =
              let uu____27908 =
                let uu____27909 =
                  let uu____27920 =
                    let uu____27921 = desugar_term env bind1  in
                    ([], uu____27921)  in
                  ((m.FStar_Syntax_Syntax.mname),
                    (n1.FStar_Syntax_Syntax.mname),
                    (p.FStar_Syntax_Syntax.mname), uu____27920,
                    ([], FStar_Syntax_Syntax.tun))
                   in
                FStar_Syntax_Syntax.Sig_polymonadic_bind uu____27909  in
              {
                FStar_Syntax_Syntax.sigel = uu____27908;
                FStar_Syntax_Syntax.sigrng = (d.FStar_Parser_AST.drange);
                FStar_Syntax_Syntax.sigquals = [];
                FStar_Syntax_Syntax.sigmeta =
                  FStar_Syntax_Syntax.default_sigmeta;
                FStar_Syntax_Syntax.sigattrs = [];
                FStar_Syntax_Syntax.sigopts = FStar_Pervasives_Native.None
              }  in
            [uu____27907]  in
          (env, uu____27906)
      | FStar_Parser_AST.Splice (ids,t) ->
          let t1 = desugar_term env t  in
          let se =
            let uu____27940 =
              let uu____27941 =
                let uu____27948 =
                  FStar_List.map (FStar_Syntax_DsEnv.qualify env) ids  in
                (uu____27948, t1)  in
              FStar_Syntax_Syntax.Sig_splice uu____27941  in
            {
              FStar_Syntax_Syntax.sigel = uu____27940;
              FStar_Syntax_Syntax.sigrng = (d.FStar_Parser_AST.drange);
              FStar_Syntax_Syntax.sigquals = [];
              FStar_Syntax_Syntax.sigmeta =
                FStar_Syntax_Syntax.default_sigmeta;
              FStar_Syntax_Syntax.sigattrs = [];
              FStar_Syntax_Syntax.sigopts = FStar_Pervasives_Native.None
            }  in
          let env1 = FStar_Syntax_DsEnv.push_sigelt env se  in (env1, [se])

let (desugar_decls :
  env_t ->
    FStar_Parser_AST.decl Prims.list ->
      (env_t * FStar_Syntax_Syntax.sigelt Prims.list))
  =
  fun env  ->
    fun decls  ->
      let uu____27975 =
        FStar_List.fold_left
          (fun uu____27995  ->
             fun d  ->
               match uu____27995 with
               | (env1,sigelts) ->
                   let uu____28015 = desugar_decl env1 d  in
                   (match uu____28015 with
                    | (env2,se) -> (env2, (FStar_List.append sigelts se))))
          (env, []) decls
         in
      match uu____27975 with | (env1,sigelts) -> (env1, sigelts)
  
let (open_prims_all :
  (FStar_Parser_AST.decoration Prims.list -> FStar_Parser_AST.decl)
    Prims.list)
  =
  [FStar_Parser_AST.mk_decl
     (FStar_Parser_AST.Open FStar_Parser_Const.prims_lid)
     FStar_Range.dummyRange;
  FStar_Parser_AST.mk_decl (FStar_Parser_AST.Open FStar_Parser_Const.all_lid)
    FStar_Range.dummyRange]
  
let (desugar_modul_common :
  FStar_Syntax_Syntax.modul FStar_Pervasives_Native.option ->
    FStar_Syntax_DsEnv.env ->
      FStar_Parser_AST.modul ->
        (env_t * FStar_Syntax_Syntax.modul * Prims.bool))
  =
  fun curmod  ->
    fun env  ->
      fun m  ->
        let env1 =
          match (curmod, m) with
          | (FStar_Pervasives_Native.None ,uu____28106) -> env
          | (FStar_Pervasives_Native.Some
             { FStar_Syntax_Syntax.name = prev_lid;
               FStar_Syntax_Syntax.declarations = uu____28110;
               FStar_Syntax_Syntax.exports = uu____28111;
               FStar_Syntax_Syntax.is_interface = uu____28112;_},FStar_Parser_AST.Module
             (current_lid,uu____28114)) when
              (FStar_Ident.lid_equals prev_lid current_lid) &&
                (FStar_Options.interactive ())
              -> env
          | (FStar_Pervasives_Native.Some prev_mod,uu____28123) ->
              let uu____28126 =
                FStar_Syntax_DsEnv.finish_module_or_interface env prev_mod
                 in
              FStar_Pervasives_Native.fst uu____28126
           in
        let uu____28131 =
          match m with
          | FStar_Parser_AST.Interface (mname,decls,admitted) ->
              let uu____28173 =
                FStar_Syntax_DsEnv.prepare_module_or_interface true admitted
                  env1 mname FStar_Syntax_DsEnv.default_mii
                 in
              (uu____28173, mname, decls, true)
          | FStar_Parser_AST.Module (mname,decls) ->
              let uu____28195 =
                FStar_Syntax_DsEnv.prepare_module_or_interface false false
                  env1 mname FStar_Syntax_DsEnv.default_mii
                 in
              (uu____28195, mname, decls, false)
           in
        match uu____28131 with
        | ((env2,pop_when_done),mname,decls,intf) ->
            let uu____28237 = desugar_decls env2 decls  in
            (match uu____28237 with
             | (env3,sigelts) ->
                 let modul =
                   {
                     FStar_Syntax_Syntax.name = mname;
                     FStar_Syntax_Syntax.declarations = sigelts;
                     FStar_Syntax_Syntax.exports = [];
                     FStar_Syntax_Syntax.is_interface = intf
                   }  in
                 (env3, modul, pop_when_done))
  
let (as_interface : FStar_Parser_AST.modul -> FStar_Parser_AST.modul) =
  fun m  ->
    match m with
    | FStar_Parser_AST.Module (mname,decls) ->
        FStar_Parser_AST.Interface (mname, decls, true)
    | i -> i
  
let (desugar_partial_modul :
  FStar_Syntax_Syntax.modul FStar_Pervasives_Native.option ->
    env_t -> FStar_Parser_AST.modul -> (env_t * FStar_Syntax_Syntax.modul))
  =
  fun curmod  ->
    fun env  ->
      fun m  ->
        let m1 =
          let uu____28305 =
            (FStar_Options.interactive ()) &&
              (let uu____28308 =
                 let uu____28310 =
                   let uu____28312 = FStar_Options.file_list ()  in
                   FStar_List.hd uu____28312  in
                 FStar_Util.get_file_extension uu____28310  in
               FStar_List.mem uu____28308 ["fsti"; "fsi"])
             in
          if uu____28305 then as_interface m else m  in
        let uu____28326 = desugar_modul_common curmod env m1  in
        match uu____28326 with
        | (env1,modul,pop_when_done) ->
            if pop_when_done
            then
              let uu____28348 = FStar_Syntax_DsEnv.pop ()  in
              (uu____28348, modul)
            else (env1, modul)
  
let (desugar_modul :
  FStar_Syntax_DsEnv.env ->
    FStar_Parser_AST.modul -> (env_t * FStar_Syntax_Syntax.modul))
  =
  fun env  ->
    fun m  ->
      let uu____28370 =
        desugar_modul_common FStar_Pervasives_Native.None env m  in
      match uu____28370 with
      | (env1,modul,pop_when_done) ->
          let uu____28387 =
            FStar_Syntax_DsEnv.finish_module_or_interface env1 modul  in
          (match uu____28387 with
           | (env2,modul1) ->
               ((let uu____28399 =
                   FStar_Options.dump_module
                     (modul1.FStar_Syntax_Syntax.name).FStar_Ident.str
                    in
                 if uu____28399
                 then
                   let uu____28402 =
                     FStar_Syntax_Print.modul_to_string modul1  in
                   FStar_Util.print1 "Module after desugaring:\n%s\n"
                     uu____28402
                 else ());
                (let uu____28407 =
                   if pop_when_done
                   then
                     FStar_Syntax_DsEnv.export_interface
                       modul1.FStar_Syntax_Syntax.name env2
                   else env2  in
                 (uu____28407, modul1))))
  
let with_options : 'a . (unit -> 'a) -> 'a =
  fun f  ->
    FStar_Options.push ();
    (let res = f ()  in
     let light = FStar_Options.ml_ish ()  in
     FStar_Options.pop ();
     if light then FStar_Options.set_ml_ish () else ();
     res)
  
let (ast_modul_to_modul :
  FStar_Parser_AST.modul ->
    FStar_Syntax_Syntax.modul FStar_Syntax_DsEnv.withenv)
  =
  fun modul  ->
    fun env  ->
      with_options
        (fun uu____28457  ->
           let uu____28458 = desugar_modul env modul  in
           match uu____28458 with | (e,m) -> (m, e))
  
let (decls_to_sigelts :
  FStar_Parser_AST.decl Prims.list ->
    FStar_Syntax_Syntax.sigelts FStar_Syntax_DsEnv.withenv)
  =
  fun decls  ->
    fun env  ->
      with_options
        (fun uu____28496  ->
           let uu____28497 = desugar_decls env decls  in
           match uu____28497 with | (env1,sigelts) -> (sigelts, env1))
  
let (partial_ast_modul_to_modul :
  FStar_Syntax_Syntax.modul FStar_Pervasives_Native.option ->
    FStar_Parser_AST.modul ->
      FStar_Syntax_Syntax.modul FStar_Syntax_DsEnv.withenv)
  =
  fun modul  ->
    fun a_modul  ->
      fun env  ->
        with_options
          (fun uu____28548  ->
             let uu____28549 = desugar_partial_modul modul env a_modul  in
             match uu____28549 with | (env1,modul1) -> (modul1, env1))
  
let (add_modul_to_env :
  FStar_Syntax_Syntax.modul ->
    FStar_Syntax_DsEnv.module_inclusion_info ->
      (FStar_Syntax_Syntax.term -> FStar_Syntax_Syntax.term) ->
        unit FStar_Syntax_DsEnv.withenv)
  =
  fun m  ->
    fun mii  ->
      fun erase_univs  ->
        fun en  ->
          let erase_univs_ed ed =
            let erase_binders bs =
              match bs with
              | [] -> []
              | uu____28644 ->
                  let t =
                    let uu____28654 =
                      FStar_Syntax_Syntax.mk
                        (FStar_Syntax_Syntax.Tm_abs
                           (bs, FStar_Syntax_Syntax.t_unit,
                             FStar_Pervasives_Native.None))
                        FStar_Pervasives_Native.None FStar_Range.dummyRange
                       in
                    erase_univs uu____28654  in
                  let uu____28667 =
                    let uu____28668 = FStar_Syntax_Subst.compress t  in
                    uu____28668.FStar_Syntax_Syntax.n  in
                  (match uu____28667 with
                   | FStar_Syntax_Syntax.Tm_abs (bs1,uu____28680,uu____28681)
                       -> bs1
                   | uu____28706 -> failwith "Impossible")
               in
            let uu____28716 =
              let uu____28723 = erase_binders ed.FStar_Syntax_Syntax.binders
                 in
              FStar_Syntax_Subst.open_term' uu____28723
                FStar_Syntax_Syntax.t_unit
               in
            match uu____28716 with
            | (binders,uu____28725,binders_opening) ->
                let erase_term t =
                  let uu____28733 =
                    let uu____28734 =
                      FStar_Syntax_Subst.subst binders_opening t  in
                    erase_univs uu____28734  in
                  FStar_Syntax_Subst.close binders uu____28733  in
                let erase_tscheme uu____28752 =
                  match uu____28752 with
                  | (us,t) ->
                      let t1 =
                        let uu____28772 =
                          FStar_Syntax_Subst.shift_subst
                            (FStar_List.length us) binders_opening
                           in
                        FStar_Syntax_Subst.subst uu____28772 t  in
                      let uu____28775 =
                        let uu____28776 = erase_univs t1  in
                        FStar_Syntax_Subst.close binders uu____28776  in
                      ([], uu____28775)
                   in
                let erase_action action =
                  let opening =
                    FStar_Syntax_Subst.shift_subst
                      (FStar_List.length
                         action.FStar_Syntax_Syntax.action_univs)
                      binders_opening
                     in
                  let erased_action_params =
                    match action.FStar_Syntax_Syntax.action_params with
                    | [] -> []
                    | uu____28799 ->
                        let bs =
                          let uu____28809 =
                            FStar_Syntax_Subst.subst_binders opening
                              action.FStar_Syntax_Syntax.action_params
                             in
                          FStar_All.pipe_left erase_binders uu____28809  in
                        let t =
                          FStar_Syntax_Syntax.mk
                            (FStar_Syntax_Syntax.Tm_abs
                               (bs, FStar_Syntax_Syntax.t_unit,
                                 FStar_Pervasives_Native.None))
                            FStar_Pervasives_Native.None
                            FStar_Range.dummyRange
                           in
                        let uu____28849 =
                          let uu____28850 =
                            let uu____28853 =
                              FStar_Syntax_Subst.close binders t  in
                            FStar_Syntax_Subst.compress uu____28853  in
                          uu____28850.FStar_Syntax_Syntax.n  in
                        (match uu____28849 with
                         | FStar_Syntax_Syntax.Tm_abs
                             (bs1,uu____28855,uu____28856) -> bs1
                         | uu____28881 -> failwith "Impossible")
                     in
                  let erase_term1 t =
                    let uu____28889 =
                      let uu____28890 = FStar_Syntax_Subst.subst opening t
                         in
                      erase_univs uu____28890  in
                    FStar_Syntax_Subst.close binders uu____28889  in
                  let uu___3893_28891 = action  in
                  let uu____28892 =
                    erase_term1 action.FStar_Syntax_Syntax.action_defn  in
                  let uu____28893 =
                    erase_term1 action.FStar_Syntax_Syntax.action_typ  in
                  {
                    FStar_Syntax_Syntax.action_name =
                      (uu___3893_28891.FStar_Syntax_Syntax.action_name);
                    FStar_Syntax_Syntax.action_unqualified_name =
                      (uu___3893_28891.FStar_Syntax_Syntax.action_unqualified_name);
                    FStar_Syntax_Syntax.action_univs = [];
                    FStar_Syntax_Syntax.action_params = erased_action_params;
                    FStar_Syntax_Syntax.action_defn = uu____28892;
                    FStar_Syntax_Syntax.action_typ = uu____28893
                  }  in
                let uu___3895_28894 = ed  in
                let uu____28895 = FStar_Syntax_Subst.close_binders binders
                   in
                let uu____28896 =
                  erase_tscheme ed.FStar_Syntax_Syntax.signature  in
                let uu____28897 =
                  FStar_Syntax_Util.apply_eff_combinators erase_tscheme
                    ed.FStar_Syntax_Syntax.combinators
                   in
                let uu____28898 =
                  FStar_List.map erase_action ed.FStar_Syntax_Syntax.actions
                   in
                {
                  FStar_Syntax_Syntax.mname =
                    (uu___3895_28894.FStar_Syntax_Syntax.mname);
                  FStar_Syntax_Syntax.cattributes =
                    (uu___3895_28894.FStar_Syntax_Syntax.cattributes);
                  FStar_Syntax_Syntax.univs = [];
                  FStar_Syntax_Syntax.binders = uu____28895;
                  FStar_Syntax_Syntax.signature = uu____28896;
                  FStar_Syntax_Syntax.combinators = uu____28897;
                  FStar_Syntax_Syntax.actions = uu____28898;
                  FStar_Syntax_Syntax.eff_attrs =
                    (uu___3895_28894.FStar_Syntax_Syntax.eff_attrs)
                }
             in
          let push_sigelt1 env se =
            match se.FStar_Syntax_Syntax.sigel with
            | FStar_Syntax_Syntax.Sig_new_effect ed ->
                let se' =
                  let uu___3902_28914 = se  in
                  let uu____28915 =
                    let uu____28916 = erase_univs_ed ed  in
                    FStar_Syntax_Syntax.Sig_new_effect uu____28916  in
                  {
                    FStar_Syntax_Syntax.sigel = uu____28915;
                    FStar_Syntax_Syntax.sigrng =
                      (uu___3902_28914.FStar_Syntax_Syntax.sigrng);
                    FStar_Syntax_Syntax.sigquals =
                      (uu___3902_28914.FStar_Syntax_Syntax.sigquals);
                    FStar_Syntax_Syntax.sigmeta =
                      (uu___3902_28914.FStar_Syntax_Syntax.sigmeta);
                    FStar_Syntax_Syntax.sigattrs =
                      (uu___3902_28914.FStar_Syntax_Syntax.sigattrs);
                    FStar_Syntax_Syntax.sigopts =
                      (uu___3902_28914.FStar_Syntax_Syntax.sigopts)
                  }  in
                let env1 = FStar_Syntax_DsEnv.push_sigelt env se'  in
                push_reflect_effect env1 se.FStar_Syntax_Syntax.sigquals
                  ed.FStar_Syntax_Syntax.mname se.FStar_Syntax_Syntax.sigrng
            | uu____28918 -> FStar_Syntax_DsEnv.push_sigelt env se  in
          let uu____28919 =
            FStar_Syntax_DsEnv.prepare_module_or_interface false false en
              m.FStar_Syntax_Syntax.name mii
             in
          match uu____28919 with
          | (en1,pop_when_done) ->
              let en2 =
                let uu____28936 =
                  FStar_Syntax_DsEnv.set_current_module en1
                    m.FStar_Syntax_Syntax.name
                   in
                FStar_List.fold_left push_sigelt1 uu____28936
                  m.FStar_Syntax_Syntax.exports
                 in
              let env = FStar_Syntax_DsEnv.finish en2 m  in
              let uu____28938 =
                if pop_when_done
                then
                  FStar_Syntax_DsEnv.export_interface
                    m.FStar_Syntax_Syntax.name env
                else env  in
              ((), uu____28938)
  