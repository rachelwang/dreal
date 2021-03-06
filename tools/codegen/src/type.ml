(* Wei Chen    (weichen1@andrew.cmu.edu) *)
(* Soonho Kong (soonhok@cs.cmu.edu)      *)

(*
 * A typical program consists of 3 components:
 * 1. Macro declaration(s).

 * 2. Mode(ODE) definition(s).
 * 3. Main function.
 *)
type t =
    {
        macros: macro list;
        modes: mode list;
        main: main_entry;
    }

and macro =
    (* define g 9.8 *)
    | Macro of string * float

and anno =
    (* [unroll, 0/t, var_index], used in BMC  *)
    | VarAnno of int * string * int
    | OdeAnno of string (* the name of define-ode command *)

and var_decl =
    | RealVar  of string
    | BRealVar of string * float * float
    | IntVar   of string

and exp =
    | Var      of string * anno option
    | Num      of float
    | Neg      of exp
    | Add      of exp list
    | Sub      of exp list
    | Mul      of exp list
    | Div      of exp * exp
    | Pow      of exp * exp
    | Ite      of formula * exp * exp
    | Sqrt     of exp
    | Safesqrt of exp
    | Abs      of exp
    | Log      of exp
    | Exp      of exp
    | Sin      of exp
    | Cos      of exp
    | Tan      of exp
    | Asin     of exp
    | Acos     of exp
    | Atan     of exp
    | Atan2    of exp * exp
    | Matan    of exp
    | Sinh     of exp
    | Cosh     of exp
    | Tanh     of exp
    | Asinh    of exp
    | Acosh    of exp
    | Atanh    of exp

    (* (integral 0 time_1 [x_1_0 ... x_i_0] flow1) *)
    | Integral of float * string * string list * string
    | Invoke of string * exp list

(* math formular *)
and formula =
    | True
    | False
    | FVar of string
    | Not of formula
    | And of formula list
    | Or  of formula list
    | Imply of formula * formula
    | Gt  of exp * exp
    | Lt  of exp * exp
    | Ge  of exp * exp
    | Le  of exp * exp
    | Eq  of exp * exp
    | LetF of ((string * formula) list * formula)
    | LetE of ((string * exp) list * formula)
    | ForallT of exp * exp * exp * formula

(* boolean expression *)
and bexp =
    | B_var of string * anno option
    | B_gt  of exp * exp
    | B_lt  of exp * exp
    | B_ge  of exp * exp
    | B_le  of exp * exp
    | B_eq  of exp * exp
    | B_and of bexp * bexp
    | B_or of bexp * bexp
    | B_true
    | B_false

(* switch case *)
and choice =
    | Case of float * stmt list
and stmt =
    | Ode of string * exp * anno option
    | Assert of bexp

    (* assignment *)
    | Assign of string * exp * anno option

    (* if no else statement, the latter one is empty *)
    | If of bexp * stmt list * stmt list
    | Proceed of stmt list
    | Vardecl of var_decl
    | Switch of string * choice list
    | Expr of exp

and main_entry =
    | Main of (stmt list)

and mode = {
    id : string;
    args: var_decl list;
    stmts: stmt list;
}
