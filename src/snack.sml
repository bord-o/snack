structure Snack =
struct
  open Cli
  structure FS = OS.FileSys

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
    case t of
      Cli => 
        let
          
          val () = FS.mkDir "./_build";
          val () = FS.mkDir "./src";
          val mainFile = TextIO.openOut "./src/main.sml"
          val mlbFile = TextIO.openOut "./src/main.mlb"
          val makeFile = TextIO.openOut "./makefile"
        in
          (  print "Creating CLI template...\n\n"
          ; TextIO.output (mainFile, Templates.Cli.mainFile)
          ; TextIO.output (mlbFile, Templates.Cli.mlbFile)
          ; TextIO.output ( makeFile, Templates.Cli.makeFile)

          ; TextIO.closeOut mainFile
          ; TextIO.closeOut mlbFile
          ; TextIO.closeOut makeFile
          ; ()
          )
        end
       | Compiler => 
        let
          
          val () = FS.mkDir "./_build";
          val () = FS.mkDir "./src";
          val mainFile = TextIO.openOut "./src/main.sml"
          val mlbFile = TextIO.openOut "./src/main.mlb"
          val makeFile = TextIO.openOut "./makefile"
          val grmFile = TextIO.openOut "./src/main.grm"
          val lexFile = TextIO.openOut "./src/main.lex"
        in
          (  print "Creating Compiler template...\n\n"
          ; TextIO.output (mainFile, Templates.Compiler.mainFile)
          ; TextIO.output (mlbFile, Templates.Compiler.mlbFile)
          ; TextIO.output ( makeFile, Templates.Compiler.makeFile)
          ; TextIO.output ( grmFile, Templates.Compiler.grmFile)
          ; TextIO.output ( lexFile, Templates.Compiler.lexFile)

          ; TextIO.closeOut mainFile
          ; TextIO.closeOut mlbFile
          ; TextIO.closeOut makeFile
          ; TextIO.closeOut grmFile
          ; TextIO.closeOut lexFile
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

  val c = Compiler
  fun run Init cfg = createTemplate (#template_type cfg)
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
  (Snack.main ())
  handle 
    Snack.ValidationError => ()  
    | Cli.UnknownTemplate => print "Unknown template...\n\nTemplates:\n  cli\n  compiler\n\n"
    | e => (print "Unknown error occurred...\n\t"; raise e)
