let subset a b = 
  let check_one one = List.mem one b in
  List.for_all check_one a;;

let equal_sets a b =
  subset a b && subset b a;;

let rec set_union a b = 
  let add_one one = one::b in
  match a with
  | [] -> b
  | s::e -> let c = add_one s in set_union e c;;

let set_intersection a b =
  let check_one one = List.mem one b in
  List.filter check_one a;;
  
let  set_diff a b =
  let check_one one = not (List.mem one b) in
  List.filter check_one a;;

let rec computed_fixed_point eq f x = 
  if eq (f x) x 
  then x 
  else computed_fixed_point eq f (f x);;

type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal;;

let is_terminal a =
  match a with | T _ -> true | N _ -> false;;

let is_nonterminal a =
  match a with | T _ -> false | N _ -> true;;

let rec get_rule_from_rules ret rules nonter = 
  match rules with 
  | [] -> List.append ret []
  | s::e ->
  if (match s with (lhs, rhs) -> lhs) = nonter then get_rule_from_rules (List.append [s] ret) e nonter 
  else get_rule_from_rules ret e nonter;;

let get_rule_from_grammar grammar nonter = 
  match grammar with
  (_,rules) -> get_rule_from_rules [] rules nonter;;

let get_next_from_rule rule = 
  let rhsd = match rule with (_,rhs) -> rhs in
  List.filter is_nonterminal rhsd;;

let rec get_next_from_rules ret rules = 
  match rules with 
  | [] -> List.append ret []
  | s::e -> get_next_from_rules (List.append ret (get_next_from_rule s)) e;;

let get_rhs nonter grammar = 
  let rules = get_rule_from_grammar grammar nonter in
  get_next_from_rules [] rules;;

let add_to_list current expr grammar = 
  List.append (set_diff current [expr]) (List.map (fun x -> match x with N r -> r) (get_rhs expr grammar));;

let add_current_helper expr active current grammar=
  if (List.mem expr active) then (active, (set_diff current [expr])) else 
  (expr::active, (add_to_list current expr grammar));;

let rec add_current comb grammar =
  match comb with
  | ( _ , []) -> comb
  | (active, current) -> let head = List.hd current in
  add_current (add_current_helper head active current grammar) grammar;;

let filter_reachable grammar =
  let start = match grammar with (s,_) -> s in
  let rules = match grammar with (_,r) -> r in
  let active = match (add_current ([],[start]) grammar) with (act,current) -> act in
  (start, List.filter (fun rule ->  List.mem (match rule with (lhs,rhs) -> lhs) active) rules);;