open Prims
let (find_deps_if_needed :
  Prims.string Prims.list ->
    (Prims.string ->
       FStar_Parser_Dep.parsing_data FStar_Pervasives_Native.option)
      -> (Prims.string Prims.list * FStar_Parser_Dep.deps))
  =
  fun files ->
    fun get_parsing_data_from_cache ->
      let uu___ = FStar_Parser_Dep.collect files get_parsing_data_from_cache in
      match uu___ with
      | (all_files, deps) ->
          (match all_files with
           | [] ->
               (FStar_Errors.log_issue FStar_Compiler_Range.dummyRange
                  (FStar_Errors.Error_DependencyAnalysisFailed,
                    "Dependency analysis failed; reverting to using only the files provided\n");
                (files, deps))
           | uu___1 -> ((FStar_Compiler_List.rev all_files), deps))