type ('a, 'b) with_opt = ?a:'a -> unit -> 'b
type ('a, 'b) app_with_opt = ('a, 'b) with_opt -> ?b:'a -> unit -> 'b
type ('a, 'b) app_app_with_opt = ('a, 'b) app_with_opt -> ('a, 'b) with_opt -> ?c:'a -> unit -> 'b

let f_never : ('a, 'a option) with_opt = fun ?a () -> a
let f_always : ('a, 'a option) with_opt = fun ?a () -> a

(* 2 FP optn : ?a in f and ?b.
 * Both are used when passing g_skip as argument to h_* *)
let g_skip : ('a, 'b) app_with_opt = fun f ?(b:_) () -> f ()
(* 1 FP optn : ?b. Used when passing g_propagate as argument to h_* *)
let g_propagate : ('a, 'b) app_with_opt = fun f ?b () -> f ?a:b ()

let h_skip : ('a, 'b) app_app_with_opt = fun g f ?(c:_) () -> g f ()
let h_propagate : ('a, 'b) app_app_with_opt = fun g f ?c () -> g f ?b:c ()

let _ = f_never ()
let _ = f_always ?a:(Some 0) ()
let _ = g_skip f_always ()
let _ = g_propagate f_always ()
let _ = h_skip g_skip f_always ?c:(Some 0) ()
let _ = h_skip g_propagate f_always ()
let _ = h_propagate g_skip f_always ()
let _ = h_propagate g_propagate f_always ?c:(Some 0) ()
