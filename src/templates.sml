structure Templates = struct

  structure Cli = struct
    val mainFile ="fun main args = print \"Hello World!\""
    val mlbFile = "local \nin\nmain.sml\nend"
    val buildFile = "app use [\"src/main.sml\"]"
    val makeFile = "run: build\n\tchmod +x ./_build/main && cd ./_build &&./main\nbuild:\n\tpolyc ./src/build.sml -o ./_build/main"

  end

  structure Compiler = struct

      val mainFile = "(* calc.sml *)\n\
      \\n\
      \(* This file provides glue code for building the calculator using the\n\
      \ * parser and lexer specified in calc.lex and calc.grm.\n\
      \*)\n\
      \\n\
      \structure Main : sig\n\
      \                   val parse : unit -> unit\n\
      \                 end =\n\
      \struct\n\
      \\n\
      \(*\n\
      \ * We apply the functors generated from calc.lex and calc.grm to produce\n\
      \ * the MainParser structure.\n\
      \ *)\n\
      \\n\
      \  structure MainLrVals =\n\
      \    MainLrValsFun(structure Token = LrParser.Token)\n\
      \\n\
      \  structure MainLex =\n\
      \    MainLexFun(structure Tokens = MainLrVals.Tokens)\n\
      \\n\
      \  structure MainParser =\n\
      \    Join(structure LrParser = LrParser\n\
      \         structure ParserData = MainLrVals.ParserData\n\
      \         structure Lex = MainLex)\n\
      \\n\
      \(*\n\
      \ * We need a function which given a lexer invokes the parser. The\n\
      \ * function invoke does this.\n\
      \ *)\n\
      \\n\
      \  fun invoke lexstream =\n\
      \      let fun print_error (s,i:int,_) =\n\
      \              TextIO.output(TextIO.stdOut,\n\
      \                            \"Error, line \" ^ (Int.toString i) ^ \", \" ^ s ^ \"\\n\")\n\
      \       in MainParser.parse(0,lexstream,print_error,())\n\
      \      end\n\
      \\n\
      \(*\n\
      \ * Finally, we need a driver function that reads one or more expressions\n\
      \ * from the standard input. The function parse, shown below, does\n\
      \ * this. It runs the calculator on the standard input and terminates when\n\
      \ * an end-of-file is encountered.\n\
      \ *)\n\
      \\n\
      \  fun parse () =\n\
      \      let val lexer = MainParser.makeLexer (fn _ =>\n\
      \                                               (case TextIO.inputLine TextIO.stdIn\n\
      \                                                of SOME s => s\n\
      \                                                 | _ => \"\"))\n\
      \          val dummyEOF = MainLrVals.Tokens.EOF(0,0)\n\
      \          val dummySEMI = MainLrVals.Tokens.SEMI(0,0)\n\
      \          fun loop lexer =\n\
      \              let val (result,lexer) = invoke lexer\n\
      \                  val (nextToken,lexer) = MainParser.Stream.get lexer\n\
      \                  val _ = case result\n\
      \                            of SOME r =>\n\
      \                                TextIO.output(TextIO.stdOut,\n\
      \                                       \"result = \" ^ (Int.toString r) ^ \"\\n\")\n\
      \                             | NONE => ()\n\
      \               in if MainParser.sameToken(nextToken,dummyEOF) then ()\n\
      \                  else loop lexer\n\
      \              end\n\
      \       in loop lexer\n\
      \      end\n\
      \\n\
      \end (* structure Main *)\n\
      \\n\
      \val _ = print \"hello!\"\n\
      \\n\
      \val _ = Main.parse ()"

    val mlbFile = "local \n\
    \       $(SML_LIB)/basis/basis.mlb\n\
    \       $(SML_LIB)/mlyacc-lib/mlyacc-lib.mlb\n\
    \in\n\
    \       main.grm.sig\n\
    \       main.grm.sml\n\
    \       main.lex.sml\n\
    \       main.sml\n\
    \end"

    val makeFile = "run: build\n\
    \\tchmod +x ./_build/main && cd ./_build && ./main\n\
    \build:\n\
    \\tmlton -output ./_build/main ./src/main.mlb\n\
    \lexparse:\n\
    \\tmllex ./src/main.lex\n\
    \\tmlyacc ./src/main.grm"
      
    val grmFile = "(* Sample interactive calculator for ML-Yacc *)\n\
    \\n\
    \fun lookup \"bogus\" = 10000\n\
    \  | lookup s = 0\n\
    \\n\
    \%%\n\
    \\n\
    \%eop EOF SEMI\n\
    \\n\
    \(* %pos declares the type of positions for terminals.\n\
    \   Each symbol has an associated left and right position. *)\n\
    \\n\
    \%pos int\n\
    \\n\
    \%left SUB PLUS\n\
    \%left TIMES DIV\n\
    \%right CARAT\n\
    \\n\
    \%term ID of string | NUM of int | PLUS | TIMES | PRINT |\n\
    \      SEMI | EOF | CARAT | DIV | SUB\n\
    \%nonterm EXP of int | START of int option\n\
    \\n\
    \%name Main \n\
    \\n\
    \%subst PRINT for ID\n\
    \%prefer PLUS TIMES DIV SUB\n\
    \%keyword PRINT SEMI\n\
    \\n\
    \%noshift EOF\n\
    \%value ID (\"bogus\")\n\
    \%verbose\n\
    \%%\n\
    \\n\
    \(* the parser returns the value associated with the expression *)\n\
    \\n\
    \  START : PRINT EXP (print (Int.toString EXP);\n\
    \                     print \"\\n\";\n\
    \                     SOME EXP)\n\
    \        | EXP (SOME EXP)\n\
    \        | (NONE)\n\
    \  EXP : NUM             (NUM)\n\
    \      | ID              (lookup ID)\n\
    \      | EXP PLUS EXP    (EXP1+EXP2)\n\
    \      | EXP TIMES EXP   (EXP1*EXP2)\n\
    \      | EXP DIV EXP     (EXP1 div EXP2)\n\
    \      | EXP SUB EXP     (EXP1-EXP2)\n\
    \      | EXP CARAT EXP   (let fun e (m,0) = 1\n\
    \                                | e (m,l) = m*e(m,l-1)\n\
    \                         in e (EXP1,EXP2)\n\
    \                         end)"

    val lexFile = "structure Tokens = Tokens\n\
    \\n\
    \type pos = int\n\
    \type svalue = Tokens.svalue\n\
    \type ('a,'b) token = ('a,'b) Tokens.token\n\
    \type lexresult= (svalue,pos) token\n\
    \\n\
    \val pos = ref 0\n\
    \fun eof () = Tokens.EOF(!pos,!pos)\n\
    \fun error (e,l : int,_) = TextIO.output (TextIO.stdOut, String.concat[\n\
    \        \"line \", (Int.toString l), \": \", e, \"\\n\"\n\
    \      ])\n\
    \\n\
    \%%\n\
    \%header (functor MainLexFun(structure Tokens: Main_TOKENS));\n\
    \alpha=[A-Za-z];\n\
    \digit=[0-9];\n\
    \ws = [\ \t];\n\
    \%%\n\
    \\\n       => (pos := (!pos) + 1; lex());\n\
    \{ws}+    => (lex());\n\
    \{digit}+ => (Tokens.NUM (valOf (Int.fromString yytext), !pos, !pos));\n\
    \\n\
    \\"+\"      => (Tokens.PLUS(!pos,!pos));\n\
    \\"*\"      => (Tokens.TIMES(!pos,!pos));\n\
    \\";\"      => (Tokens.SEMI(!pos,!pos));\n\
    \{alpha}+ => (if yytext=\"print\"\n\
    \                 then Tokens.PRINT(!pos,!pos)\n\
    \                 else Tokens.ID(yytext,!pos,!pos)\n\
    \            );\n\
    \\"-\"      => (Tokens.SUB(!pos,!pos));\n\
    \\"^\"      => (Tokens.CARAT(!pos,!pos));\n\
    \\"/\"      => (Tokens.DIV(!pos,!pos));\n\
    \\".\"      => (error (\"ignoring bad character \"^yytext,!pos,!pos); lex());"

  end
end
