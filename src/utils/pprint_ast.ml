open Ast

let padding_offset = 2

let build_offset padding : string =
  String.make padding ' '

let rec string_of_program ?(padding=0) node : string =
  match node with
  | Program expr ->
      let str = string_of_expression expr ~padding:(padding + padding_offset) in
      Printf.sprintf "%sProgram\n%s" (build_offset padding) str
  | FlatProgram (vars, stmts, arg) ->
      let vars_string = string_of_variables vars ~padding:(padding + padding_offset) in
      let stmts_string = string_of_statements stmts ~padding:(padding + padding_offset) in
      Printf.sprintf "%sFlatProgram\n%s\n%s"
        (build_offset padding)
        vars_string
        stmts_string

and string_of_expression ?(padding=0) node : string = Ast.Standard.(
  match node with
  | Read -> Printf.sprintf "%sRead" (build_offset padding)
  | Int n -> Printf.sprintf "%sInt: %d" (build_offset padding) n
  | Variable name -> Printf.sprintf "%sVariable: %s" (build_offset padding) name
  | BinaryExpression (op, lhs, rhs) ->
      Printf.sprintf "%sBinaryExpression\n%s\n%s\n%s"
        (build_offset padding)
        (string_of_binop op ~padding:(padding + padding_offset))
        (string_of_expression lhs ~padding:(padding + padding_offset))
        (string_of_expression rhs ~padding:(padding + padding_offset))
  | UnaryExpression (op, operand) ->
      Printf.sprintf "%sUnaryExpression\n%s\n%s"
        (build_offset padding)
        (string_of_unop op ~padding:(padding + padding_offset))
        (string_of_expression operand ~padding:(padding + padding_offset))
  | LetExpression (v, binding, expr) ->
      Printf.sprintf "%sLetExpression\n%s\n%s\n%s"
        (build_offset padding)
        (build_offset (padding + padding_offset) ^ v)
        (string_of_expression binding ~padding:(padding + padding_offset))
        (string_of_expression expr ~padding:(padding + padding_offset)))

and string_of_binop ?(padding=0) node : string = Ast.Standard.(
  match node with
  | Plus -> Printf.sprintf "%sPlus" (build_offset padding))

and string_of_unop ?(padding=0) node : string = Ast.Standard.(
  match node with
  | Minus -> Printf.sprintf "%sMinus" (build_offset padding))

and string_of_statements ?(padding=0) stmts : string = Ast.Flat.(
  let start = (build_offset padding) ^ "Statements:" in
  let statements = List.fold_left (fun acc stmt ->
    let str = string_of_statement stmt ~padding:(padding + padding_offset) in
    acc ^ "\n" ^ str) "" stmts in
  start ^ statements
)

and string_of_variables ?(padding=0) vars : string = Ast.Flat.(
  let start = (build_offset padding) ^ "Variables:" in
  let variables = List.fold_left (fun acc var ->
    let str = build_offset(padding + padding_offset) ^ var in
    acc ^ "\n" ^ str) "" vars in
  start ^ variables
)

and string_of_statement ?(padding=0) node : string = Ast.Flat.(
  match node with
  | Assignment (name, expr) ->
      Printf.sprintf "%s%s := %s"
        (build_offset padding)
        (name)
        (string_of_flat_expression expr)
)

and string_of_argument ?(padding=0) node : string = Ast.Flat.(
  match node with
  | Int n -> Printf.sprintf "%d" n
  | Variable name -> Printf.sprintf "%s" name
)

and string_of_flat_expression ?(padding=0) node : string = Ast.Flat.(
  match node with
    | Read -> "Read"
    | Argument arg -> string_of_argument arg
    | UnaryExpression (op, arg) ->
        Printf.sprintf "%s%s"
          (string_of_flat_unop op)
          (string_of_argument arg)
    | BinaryExpression (op, lhs, rhs) ->
        Printf.sprintf "%s %s %s"
          (string_of_argument lhs)
          (string_of_flat_binop op)
          (string_of_argument rhs)
)

and string_of_flat_binop ?(padding=0) node : string = Ast.Flat.(
  match node with
  | Plus -> Printf.sprintf "%s+" (build_offset padding))

and string_of_flat_unop ?(padding=0) node : string = Ast.Flat.(
  match node with
  | Minus -> Printf.sprintf "%s-" (build_offset padding))

let display_input (prog : program) : program =
  print_endline "\n──< \x1b[1mInput\x1b[0m >────────────────────\n";
  print_endline (string_of_program prog ~padding:1);
  prog

let display_output (title : string) (prog : program) : program =
  print_endline ("\n──< \x1b[1m" ^ title ^ "\x1b[0m >────────────────────\n");
  print_endline (string_of_program prog ~padding:1);
  prog

let display_error title msg : string =
  Printf.sprintf "\n\x1b[31m✗\x1b[39m \x1b[4m%s\x1b[0m\n\
    \n  \x1b[31m●\x1b[39m %s\n"
    title msg
