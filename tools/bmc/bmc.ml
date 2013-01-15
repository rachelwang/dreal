(*
 * Soonho Kong (soonhok@cs.cmu.edu)
 *)

open BatPervasives

type varDecl = Dr.vardecl
type formula = Dr.formula
type hybrid = Hybrid.t
type dr = Dr.t
type id = Mode.id
type mode = Mode.t
type jump = Mode.jump
type ode = Mode.ode
type flow = ode list

let add_index (k : int) (q : id) (suffix : string) (s : string) : string =
  let str_step = string_of_int k in
  let str_mode_id = string_of_int q in
  (BatString.join "_" [s;
                      str_step;
                      str_mode_id;]) ^ suffix

let process_init (q : id) (i : formula) : formula =
  Dr.subst_formula (add_index 0 q "_0") i

let process_flow (k : int) (q : id) (m : mode) : (flow * formula) =
  let (id, inv, flow, jump) = m in
  let flow' = List.map (fun ode -> Dr.subst_ode (add_index k q "") ode) flow in
  (flow', Dr.True)

let process_jump (jump) (q : id) (next_q : id) (k : int) (next_k : int)
    : formula =
  let (cond, _, change) = jump in
  let cond' = Dr.subst_formula (add_index k q "_t") cond in
  (* TODO: Need to add equality relations for the unmodified variables *)
  let change' =
    Dr.subst_formula
      (fun v -> match BatString.ends_with v "'" with
        true -> add_index (k+1) next_q "_0" v
      | false -> add_index k q "_t" v
      )
      change in
  (* TODO: Need to check the following *)
  Dr.make_and [cond'; change']

let rec reach_kq (k : int) (q : id) (hm : hybrid) : (flow * formula)
    = let (vardecls, env, modemap, (init_id, init_formula), goal) = hm in
      match (k, q) with
      | (0, q) when q = init_id ->
        begin
          (* Base Case where q = init mode *)
          let init_q0 : formula = process_init init_id init_formula in
          let (odes, f) = process_flow k q (Modemap.find q modemap) in
          (odes, Dr.make_and [init_q0; f])
        end
      | (0, _) ->
        begin
          (* If q is non-init mode,
             then the whole thing should be false *)
          ([], Dr.False)
        end
      | _ ->
        begin
          (* Inductive Case: *)
          let rjumptbl = Jumptable.extract_rjumptable modemap in
          let prev_modes : id list = Jumptable.find q rjumptbl in
          let process (prev_q : id) : (flow * formula) =
            let (id, inv, flow, jm) = Modemap.find prev_q modemap in
            let (r_flow, r_formula) = reach_kq (k-1) prev_q hm in
            let j_formula = process_jump (Jumpmap.find q jm) prev_q q (k-1) k in
            (r_flow, Dr.make_and [r_formula; j_formula])
          in
          let (flow, formulas) = BatList.split (List.map process prev_modes) in
          let (flow_1, formula_1) = (BatList.concat flow, Dr.make_or formulas) in
          let (flow_2, formula_2) = process_flow k q (Modemap.find q modemap) in
          (flow_1 @ flow_2, Dr.make_and [formula_1; formula_2])
        end

let reach_k (k : int) (hm : hybrid) : (flow * formula) =
  let (vardeclmap, env, modemap, init, goal) = hm in
  let mode_ids = BatMap.keys modemap in
  begin
    let results = BatList.of_enum (BatEnum.map (fun q -> reach_kq k q hm) mode_ids) in
    let (flow, formulas) = BatList.split results in
    let flow' = BatList.concat flow in
    let formula = Dr.make_or formulas in
    (flow', formula)
  end

let transform (k : int) (hm : hybrid) : Dr.t =
  let (vardeclmap, env, modemap, init, goals) = hm in
  let num_of_modes = BatEnum.count (BatMap.keys modemap) in
  (* 1. Translate Variable Declarations *)
  let new_vardecls =
    BatMap.foldi
      (fun var value vardecls -> (var, value)::vardecls)
      vardeclmap
      [] in
  let new_vardecls' =
    List.concat
      (List.map
         (fun (var, value) ->
           let t1 =
             BatList.cartesian_product
               (BatList.of_enum ( 1 -- k ))
               (BatList.of_enum ( 0 --^ num_of_modes ))
           in
           List.concat
             (List.map
                (fun (k, q) -> [(add_index k q "_t" var, value);
                             (add_index k q "_0" var, value)])
                t1
             )
         )
         new_vardecls)
  in
  (* 2. Collect odes(flow) and formulae of reach_k for (1 -- k) *)
  let (flows, formulas) =
    BatList.split
      (BatList.of_enum
         (BatEnum.map (fun k -> reach_k k hm) (1 -- k))) in
  let (flow, formula) = (List.concat flows, Dr.make_or formulas) in

  (* 3. Unsafe *)
  let safe_conditions =
    BatList.concat
      (BatList.of_enum
         (BatEnum.map
            (fun k ->
              List.map
                (fun (id, goal_formula) -> Dr.subst_formula (add_index k id "_t") goal_formula)
                goals
            )
            (1 -- k)
         )
      ) in
  let unsafe_condition = Dr.Not (Dr.make_and safe_conditions) in
  (new_vardecls',
   flow,
   Dr.make_and [formula; unsafe_condition]
  )