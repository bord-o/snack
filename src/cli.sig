signature CLI =
sig
  type config = {path: string}
  datatype snackOp = Init | Watch
  val show: snackOp -> string
  (* where to watch for file changes. Later this will include the template type *)
  (* get the usage message when a user messes up *)
  val getUsage: unit -> unit
  (* get our options, arguments, and error messages, respectively *)
  val getCliOpt: string list -> snackOp list * string list * string list
  (* print the results of the above *)
  val debug: string list -> unit
  (* checks the cli options, prints usage if 
    they are invalid, and returns the valid operation and config *)
  val validate: string list -> (snackOp * config) option
end
