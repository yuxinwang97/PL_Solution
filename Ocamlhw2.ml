type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal

let rec compact_helper ret rule =
  match ret with
  | hd::tl -> ( match hd with (a,b) -> 
                match rule with (c,d) -> 
                if (a = c) then (a,List.append b [d])::tl else hd::(compact_helper tl rule))
  | [] -> match rule with (a,b) -> (a,[b])::[]

let rec compact ret rules =
  match rules with 
  | [] -> ret
  | hd::tl -> compact (compact_helper ret hd) tl

let rec convert_grammar_helper insym rules =
  match rules with
  | [] -> []
  | head::rest -> ( match head with (nonter, ls) -> 
                    if (nonter = insym) then ls else convert_grammar_helper insym rest)

let convert_grammar_mid rules = (fun insym -> convert_grammar_helper insym rules )

let convert_grammar grammar = 
  match grammar with
  | (star, rules) -> (star, convert_grammar_mid (compact [] rules))

let rec parse_tree_leaves_ls rets leaves = 
    match leaves with 
    | [] -> rets 
    | hd::tl -> (parse_tree_leaves_nd [] hd)@(parse_tree_leaves_ls [] tl)@rets
and parse_tree_leaves_nd ret node = 
  match node with
  | Leaf a -> [a]
  | Node (a,b) -> (parse_tree_leaves_ls ret b)

let parse_tree_leaves tree = parse_tree_leaves_nd [] tree

let rec expand_add rhs tail gram nex=
  match rhs with
  | [] -> nex
  | hed::tel -> expand_add tel tail gram (nex@[( hed@tail ,gram)])
let rec match_list accp rul rng = 
  match rng with 
  | [] -> None;
  | frs::nex -> (match frs with | (nodes, gram) -> expand_helper accp rul nodes gram nex)
and expand_helper accp rul nodes gram nex= 
  match nodes with 
  | [] -> (match accp gram with | Some a -> Some a | None -> match_list accp rul nex)
  | hds::tls -> match gram with 
                | [] -> match_list accp rul nex
                | _::_ ->expand_head accp rul hds tls gram nex
and expand_head accp rul nod nodetl gram nex=
  match nod with 
  | N nonter -> let rhs = rul nonter in match_list accp rul ((expand_add rhs nodetl gram [])@nex)
  | T ter -> if ter = (List.hd gram) then expand_helper accp rul nodetl (List.tl gram) nex
              else match_list accp rul nex

let make_matcher gram=
  match gram with
  | (start,rul) -> (fun accp frag -> match_list accp rul [([N start],frag)])
 
let rec tree_add rhs tail gram nex ctree =
  match rhs with
  | [] -> nex
  | hed::tel -> tree_add tel tail gram (nex@[( (hed@tail) ,gram, (ctree@[hed]) )]) ctree 
let rec match_tree rng rul= 
  match rng with 
  | [] -> []; 
  | frs::nex -> (match frs with | (nodes, gram, ctree) -> expand_tree nodes gram nex ctree rul)
and expand_tree nodes gram nex ctree rul =
  match nodes with 
  | [] -> if gram = [] then ctree else match_tree nex rul
  | hds::tls -> (match gram with 
                | [] -> match_tree nex rul
                | _::_ -> head_tree hds tls gram nex ctree rul)
and head_tree nod nodetl gram nex ctree rul=
  match nod with 
  | N nonter -> let rhs = rul nonter in match_tree ((tree_add rhs nodetl gram [] ctree  )@nex) rul 
  | T ter -> if ter = (List.hd gram) then expand_tree nodetl (List.tl gram) nex ctree rul
              else match_tree nex rul

let rec toTree frs res =
  match frs with
  | [T leaf] -> ([Leaf leaf],res)
  | [N node] -> let lefnres = toTree (List.hd res) (List.tl res) in 
                (match lefnres with | (a,b) -> ([Node (node, a)], b))
  | mix -> dealmix mix res []
and dealmix mix rest leaves =
  match mix with 
  | [] -> (leaves, rest)
  | head::tail -> let lfs = toTree [head] rest in
                  (match lfs with | (a,b) -> dealmix tail b (leaves@a) )
            
let make_parser grammar frag=
  match grammar with
  | (star,rules) -> let tree = match_tree [([N star],frag,[])] rules in
                    (match tree with 
                    | [] -> None
                    | _ -> (match (toTree [N star] tree) with | ([a],b) -> Some a | _ -> None))
        