open Ast
open Ast.TypedStandard
open Polyfill

exception Illegal_variable_reference of string
exception Incorrect_step of string
exception Not_a_LetExpression

(* *)
let rec expose (expr : typed_expression) : typed_expression =
  match expr with
  | (t, Vector exprs) ->
    let exprs_with_vars = List.fold_left (fun acc expr ->
        let local_uid = Dangerous_guid.get () in
        let vector_expression_name = Printf.sprintf "vector_expression_%d" local_uid in
        let binding = expr in
        let body = (T_VOID, Void) in
        (T_VOID, LetExpression (vector_expression_name, binding, body)) :: acc) [] exprs
    in
    (* Length of vector * 8 plus 8 for the size of the tag. *)
    let size_in_bytes = (List.length exprs_with_vars * 8 + 8) in
    let size_plus_free_ptr =
      (T_BOOL, BinaryExpression
         ((Plus),
          (T_INT, Global "free_ptr"),
          (T_INT, Int size_in_bytes)))
    in
    let greater_than_fromspace_end =
      (T_BOOL, BinaryExpression
         ((Compare GreaterThan),
          size_plus_free_ptr,
          (T_INT, Global "fromspace_end")))
    in
    let uid = Dangerous_guid.get () in
    let collect_variable_name = Printf.sprintf "maybe_collect_%d" uid in
    let allocate_variable_name = Printf.sprintf "allocate_%d" uid in
    let vector_set_expressions = List.mapi (fun i expr ->
        match expr with
        | (t_let, LetExpression (name, binding, body)) ->
          let local_uid = Dangerous_guid.get () in
          let vector_set_name = Printf.sprintf "_vectorset_%d" local_uid in
          (T_VOID, LetExpression
             ((vector_set_name),
              (t_let, VectorSet
                 ((t, Variable allocate_variable_name),
                  (i),
                  (t_let, Variable name))),
              (T_VOID, Void)))
        | _ -> raise Not_a_LetExpression) exprs_with_vars
    in
    let exposed_expr =
      (T_VOID, Begin
         (exprs_with_vars  (* create a list of the vector expressions, like to remove them from the vector *)
          @
          [ T_VOID, LetExpression  (* check for garbage collection *)
              ((collect_variable_name),
               (T_VOID, IfExpression
                  ((greater_than_fromspace_end),
                   (T_VOID, Collect),
                   (T_VOID, Void))),
               (T_VOID, Void))
          ; T_VOID, LetExpression  (* assign the allocate call *)
              ((allocate_variable_name),
               (t, Allocate (t, size_in_bytes)),
               (T_VOID, Void))
          ]
          @
          vector_set_expressions))  (* set all the elements of allocate to the vector expressions *)
    in
    (* The type being returned here is same as `t` *)
    let (_, exposed_expr') = Macros.desugar_typed exposed_expr in
    (t, exposed_expr')
  | (t, _) -> (t, Collect)  (* need to actually go though each one individually *)

(* *)
let transform (prog : program) : program =
  let (t, expr) = match prog with
    | ProgramTyped typed_expr -> expose typed_expr
    | _ -> raise (Incorrect_step "expected type ProgramTyped")
  in
  ProgramTyped (t, expr)
