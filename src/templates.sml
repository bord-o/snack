structure Templates = struct

  structure Cli = struct
    val mainFile ="val _ = print \"Hello World!\""
    val mlbFile = "local $(SML_LIB)/basis/basis.mlb\nin\nmain.sml\nend"
    val makeFile = "run: build\n\tchmod +x ./_build/main && cd ./_build && ./main\nbuild:\n\tmlton -output ./_build/main ./src/main.mlb"

  end

  structure Compiler = struct
    val mainFile ="val _ = print \"Hello World!\""
    val mlbFile = "local $(SML_LIB)/basis/basis.mlb\nin\nmain.sml\nend"
    val makeFile = "run: build\n\tchmod +x ./_build/main && cd ./_build && ./main\nbuild:\n\tmlton -output ./_build/main ./src/main.mlb"
    val grmFile ="unimplemented"
    val lexFile ="unimplemented"
  end

end
