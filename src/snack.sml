structure Snack =
struct
  open Cli
  structure FS = OS.FileSys
  datatype template = Cli | Compiler

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
      ( TextIO.output (mainFile, "val _ = print \"Hello World!\"")
      ; TextIO.output
          (mlbFile, "local $(SML_LIB)/basis/basis.mlb\nin\nmain.sml\nend")
      ; TextIO.output
          ( makeFile
          , "run: build\n\tchmod +x ./_build/main && cd ./_build && ./main\nbuild:\n\tmlton -output ./_build/main ./src/main.mlb"
          )
      ; TextIO.closeOut mainFile
      ; TextIO.closeOut mlbFile
      ; TextIO.closeOut makeFile
      ; ()
      )
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
      if filesChanged old fileMods then
        (OS.Process.system compileCommand; wait (); watchLoop dir fileMods)
      else
        (wait (); watchLoop dir fileMods)
    end

  fun run Init cfg =
        (print "Creating CLI template...\n\n"; createTemplate Cli)
    | run Watch cfg =
        (print "Starting recompile loop...\n\n"; watchLoop (#path cfg) [])

  exception ValidationError
  fun main () =
    let
      val args = CommandLine.arguments ()
      val (command, config) =
        case Cli.validate args of
           SOME cmd => cmd
         | NONE => raise ValidationError
    in
      run command config
    end

end
val () =
  Snack.main ()
  handle _ => 
    ()
