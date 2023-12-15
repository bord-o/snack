
signature CLI = sig
	type smlackerOp
	val show : smlackerOp -> string
	(* get the usage message when a user messes up *)
	val getUsage : unit -> unit

	(* get our options, arguments, and error messages *)
	val getCliOpt : string list -> smlackerOp list * string list * string list 

	(* print the results of the above *)
	val debug : string list -> unit
	val validate : string list -> smlackerOp option
end

structure Cli :> CLI = struct
	open GetOpt
	datatype smlackerOp = 
		Init
		| Watch


	val order = REQUIRE_ORDER
	val init_flag = NO_ARG (fn () => Init)
	val watch_flag = NO_ARG (fn () => Watch)

	val (opt_descs: smlackerOp opt_descr list)  = [
		{short = [#"i"], long=["init"], arg=init_flag, desc="Initialize a project."},
		{short = [#"w"], long=["watch"], arg=watch_flag, desc="Recompile the project on save."}
	]

	fun show opt = case opt of
		Init => "Init"
		| Watch => "Watch"
		

	fun getUsage () = 
	(
		print "Smlacker\n\nUsage:\n\n";
		print (GetOpt.usage (opt_descs));
	)
	fun getCliOpt args = 
		getopt order opt_descs args 

	fun debug args =
		let 
			val (res, non, err) = getCliOpt args
		in
			(
			print "Options Given:\n";
			List.app (fn r => print (show r)) res;
			print "\n\nNon-Options Given\n";
			List.app print non;
			print "\n\nError Messages\n";
			List.app print err
			)
		end

	datatype validity = 
		Valid 
		| Invalid

	fun validate args =
		let
			val (res, non, err) = getCliOpt args
			val valid = 
				if List.length args = 0 then Invalid else
				if List.length err <> 0 then Invalid else
				if List.length non <> 0 then Invalid else
				Valid
		in
			if valid <> Valid then (getUsage (); List.app print err; NONE) else (print "Happy!"; SOME (List.hd res))
		end
end

structure Smlacker = struct
	val args = CommandLine.arguments ()

		
end

val args = CommandLine.arguments ()
val res = Cli.validate args
val _ = Option.app (fn r => print ("\n" ^ (Cli.show r) ^ "\n")) res

(* val _ = Cli.getUsage ()
val _ = Cli.getCliOpt args
val _ = Cli.debug args *)

	
