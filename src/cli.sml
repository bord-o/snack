structure Cli :> CLI =
struct
  open GetOpt
  datatype snackOp = Init | Watch
  datatype template = Cli | Compiler

  type config = {path: string, template_type : template}

  val current_path = ref ""
  val template_type = ref Cli


  exception UnknownTemplate

  val order = REQUIRE_ORDER
  (*(if s="cli" then Cli else if s = "compiler" then Compiler else raise
  * UnknownTemplate)*)
  val init_flag = REQ_ARG ((fn s => (template_type := (if s="cli" then Cli else if s = "compiler" then Compiler else 
     raise UnknownTemplate
    ); Init)), "TEMPLATE")
  val watch_flag = REQ_ARG ((fn s => (current_path := s; Watch)), "PATH")

  val (opt_descs: snackOp opt_descr list) =
    [ { short = [#"i"]
      , long = ["init"]
      , arg = init_flag
      , desc = "Initialize a project (cli, compiler)"
      }
    , { short = [#"w"]
      , long = ["watch"]
      , arg = watch_flag
      , desc = "Recompile the project after file changes in PATH."
      }
    ]

  fun show opt =
    case opt of
      Init => "Init"
    | Watch => "Watch"


  fun getUsage () =
    (print "Snack\n\nUsage:\n\n"; print (GetOpt.usage (opt_descs)); print "\n")
  fun getCliOpt args =
    getopt order opt_descs args

  fun debug args =
    let
      val (res, non, err) = getCliOpt args
    in
      ( print "Options Given:\n"
      ; List.app (fn r => print (show r)) res
      ; print "\n\nNon-Options Given\n"
      ; List.app print non
      ; print "\n\nError Messages\n"
      ; List.app print err
      )
    end

  datatype validity = Valid of config | Invalid

  fun validate args =
    let
      val (res, non, err) = getCliOpt args
      val valid =
        if List.length args = 0 then Invalid
        else if List.length err <> 0 then Invalid
        else if List.length non <> 0 then Invalid
        else Valid {path = !current_path, template_type = !template_type}
    in
      case valid of
        Valid cfg => (SOME (List.hd res, cfg))
      | Invalid => (getUsage (); List.app print err; NONE)
    end
end
