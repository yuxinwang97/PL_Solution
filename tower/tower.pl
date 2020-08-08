% transpose matrix from stack overflow.
% https://stackoverflow.com/questions/4280986/how-to-transpose-a-matrix-in-prolog
transpose([], []).
transpose([F|Fs], Ts) :-
    transpose(F, [F|Fs], Ts).

transpose([], _, []).
transpose([_|Rs], Ms, [Ts|Tss]) :-
        lists_firsts_rests(Ms, Ts, Ms1),
        transpose(Rs, Ms1, Tss).

lists_firsts_rests([], [], []).
lists_firsts_rests([[F|Os]|Rest], [F|Fs], [Os|Oss]) :-
        lists_firsts_rests(Rest, Fs, Oss).

flipside([],[]).
flipside([R|Tres],[CopR|Copres]) :- reverse(R,CopR), flipside(Tres,Copres).

countrow([], C) :- C is 0.
countrow([R|Rres], C) :- crhelper(Rres, 1, R, Retur), C is Retur.
crhelper([], C, _, Retur) :- Retur is C.
crhelper([R|Rres], C, M, Retur) :- R>M, Cplus is C+1, crhelper(Rres, Cplus, R, Retur).
crhelper([R|Rres], C, M, Retur) :- R<M, crhelper(Rres, C, M, Retur).
crhelper([R|Rres], C, M, Retur) :- R=M, crhelper(Rres, C, M, Retur).

countside([], []).
countside([R|Tres], [C|Cres]) :- countrow(R, C), countside(Tres, Cres).

issquare([], N) :- N = 0.
issquare(List, N) :- length(List,N), sqhelper(List, N).
sqhelper([], _).
sqhelper([Fst|Rst], N) :- length(Fst,N),  sqhelper(Rst, N).

% nonmember function from the reference manual of the library(lists)
% https://www.cs.nmsu.edu/~ipivkina/ECLIPSE/doc/bips/lib/lists/nonmember-2.html

nonmember(_,[]).
nonmember(Arg,[Arg|_]) :- !,fail.
nonmember(Arg,[_|Tail]) :- !,nonmember(Arg,Tail).
checkbad([]).
checkbad([Head|Tail]) :- 
  nonmember(Head, Tail),
  checkbad(Tail).

% within_domain from TA hint code
% https://github.com/CS131-TA-team/UCLA_CS131_CodeHelp/blob/master/Prolog/plain_domain.pl

within_domain(N, Domain) :- findall(X, between(1, N, X), Domain).

checkonerow([],[],_).
checkonerow(Row,Cnt,N) :-
    within_domain(N, Domain),
    permutation(Domain, Row),
    countrow(Row, Cnt).

checkbyrow([],[],_).
checkbyrow([Row|Res],[Cnt|Cres],N) :-
  checkonerow(Row,Cnt,N),
  checkbyrow(Res,Cres,N).
    
plain_tower(N,T,C) :- 
    issquare(T,N),
    C=counts(W,S,A,D),
    checkbyrow(T,A,N),
    transpose(T, Up),
    checkbyrow(Up,W,N),
    flipside(T, Rt),
    checkbyrow(Rt,D,N),
    flipside(Up, Dn),
    checkbyrow(Dn,S,N),
    maplist(checkbad,T),
    maplist(checkbad,Up).

setrange([] , _).
setrange([Head|Tail] , N) :- 
    fd_domain(Head,1,N), 
    setrange(Tail,N).

tower(N,T,C) :-
    issquare(T,N),
    setrange(T,N),
    C = counts(Top,Bottom,Left,Right),
    length(Top,N),
    length(Bottom,N),
    length(Left,N),
    length(Right,N),
    transpose(T, Up),
    flipside(T, Rt),
    flipside(Up, Dn),
    maplist(fd_all_different , T),
    maplist(fd_all_different , Up),
    maplist(fd_labeling,T),
    countside(T,Left),
    countside(Up,Top),
    countside(Rt,Right),
    countside(Dn,Bottom).


%--------------------------------
stats_tower(A) :-
  statistics(cpu_time, [Sa|_]),
  tower(5, _, counts([2,3,2,1,4],[2,1,3,3,2],[4,1,2,5,2],[2,4,2,1,2])),
  statistics(cpu_time, [Ea|_]),
  A is Ea - Sa.

stats_plain_tower(B) :-
  statistics(cpu_time, [Sb|_]),
  plain_tower(5, _, counts([2,3,2,1,4],[2,1,3,3,2],[4,1,2,5,2],[2,4,2,1,2])),
  statistics(cpu_time, [Eb|_]),
  B is Eb - Sb.

speedup(Ratio) :-
  stats_tower(A),
  stats_plain_tower(B),
  Ratio is B/A.

%--------------------------------
ambiguous(N, C, T1, T2) :-
  tower(N, T1, C),
  tower(N, T2, C),
  T1 \= T2.