signature CLI =
sig
  datatype smlackerOp = Init | Watch
  type config = {path:string}
  val show: smlackerOp -> string
  (* get the usage message when a user messes up *)
  val getUsage: unit -> unit

  (* get our options, arguments, and error messages *)
  val getCliOpt: string list -> smlackerOp list * string list * string list

  (* print the results of the above *)
  val debug: string list -> unit
  val validate: string list -> (smlackerOp * config )option 
end

structure Cli :> CLI =
struct
  open GetOpt
  datatype smlackerOp = Init | Watch

  type config = {path: string}

  val current_path = ref ""

  val order = REQUIRE_ORDER
  val init_flag = NO_ARG (fn () => Init)
  val watch_flag = REQ_ARG ((fn s => (current_path := s; Watch)), "PATH")

  val (opt_descs: smlackerOp opt_descr list) =
    [ { short = [#"i"]
      , long = ["init"]
      , arg = init_flag
      , desc = "Initialize a project."
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
    (print "Smlacker\n\nUsage:\n\n"; print (GetOpt.usage (opt_descs));print "\n")
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
        else Valid {path = !current_path}
    in
      case valid of
        Valid cfg => 
          (SOME (List.hd res, cfg))
      | Invalid => (getUsage (); List.app print err; NONE)
    end
end

structure Smlacker =
struct
  open Cli
  structure FS = OS.FileSys
  datatype template = Cli | Compiler

  (*
  	create directories
  		./_build/
  		./src/
  			main.sml
  			main.mlb (*link with mlbasis*)
  		makefile
  *)
  fun allFiles dir =
    let
      val dirstream = FS.openDir dir
      fun allFiles' dirstream acc =

        case FS.readDir dirstream of
          SOME file => allFiles' dirstream (file :: acc)
        | NONE => (FS.closeDir dirstream; acc)
    in
      allFiles' dirstream []
    end

  (* returns true if any files have been modified since last check *)
  fun filesChanged (old: (string * Time.time) list)
    (new: (string * Time.time) list) : bool =
    let
      open Time
      val combined = ListPair.zip (old, new)
      val compare =
        List.exists (fn ((_, oldt), (_, newt)) => newt > oldt) combined

    in
      compare
    end


  fun createTemplate t = 
    let
      val () = FS.mkDir "./_build";
      val () = FS.mkDir "./src";
      val mainFile = TextIO.openOut "./src/main.sml"
      val mlbFile = TextIO.openOut "./src/main.mlb"
      val makeFile = TextIO.openOut "./makefile"
    in

      (
      TextIO.output(mainFile, "val _ = print \"hello!\"");
      TextIO.output(mlbFile, "local $(SML_LIB)/basis/basis.mlb\nin\nmain.sml\nend");
      TextIO.output(makeFile, "run: build\n\tchmod +x ./_build/main && cd ./_build && ./main\nbuild:\n\tmlton -output ./_build/main ./src/main.mlb");
      
      TextIO.closeOut mainFile;
      TextIO.closeOut mlbFile;
      TextIO.closeOut makeFile;
      ())
    end

  (*
  	run mlton on main.mlb whenever a file in ./src/ is modified
  *)
  fun watchLoop dir old =
    let
      val checkInterval = 0.5
      val files: string list = allFiles dir
      val fileMods: (string * Time.time) list =
        List.map
          (fn file => ((dir ^ "/" ^ file), ((FS.modTime (dir ^ "/" ^ file)))))
          files
      val compileCommand = "clear && make"
      fun wait () =
        OS.Process.sleep (Time.fromReal checkInterval)
    in
      (*List.app
        (fn (file, timestring) =>
           ( print file
           ; print ": "
           ; print (Time.toString timestring)
           ; print "\n"
           )) fileMods;
      print "\n";

      List.app
        (fn (file, timestring) =>
           ( print file
           ; print ": "
           ; print (Time.toString timestring)
           ; print "\n"
           )) old;

      print "\n\n";
      *)
      if filesChanged old fileMods then
        (OS.Process.system compileCommand; wait (); watchLoop dir fileMods)
      else
        (wait (); watchLoop dir fileMods)

    end

  fun run Init cfg = (print "Creating CLI template...\n\n";createTemplate Cli)
    | run Watch cfg = (print "Starting recompile loop...\n\n";watchLoop (#path cfg) [])

  exception ValidationError
  fun main () =
    let
      val args = CommandLine.arguments ()
      val (command,config)= 
        (case Cli.validate args of
        SOME cmd => cmd
        | NONE => raise ValidationError)
        
    in
      run command config
    end


end 
val _ = 
  Smlacker.main ()
  handle _ => print "Unrecognized option..."



(*
    val args = CommandLine.arguments ()
    val res = Cli.validate args
    val _ = Option.app (fn r => print ("\n" ^ (Cli.show r) ^ "\n")) res
    
    val _ = Smlacker.run (Cli.Init)
    val _ = Smlacker.watchLoop "./src" []
    *) (* val _ = Cli.getUsage ()
       val _ = Cli.getCliOpt args
       val _ = Cli.debug args *)
