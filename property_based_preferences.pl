%%
%% This is the implementation of the dialog games (a particular kind of proof 
%% procedure) described in the paper “Property-based Preferences in Abstract Argumentation“
%% (Booth, Kaci, Rienstra. Algorithmic Decision Theory 2013). More precisely, it is procedure 
%% that generates dialogs for weak acceptance as described in definition 12. 
%%
%% The procedure assumes that the property-based argumentation framework is modelled using 
%% the following predicates:
%%
%% arg(X) (asserting that X is an argument)
%% att(X, Y) (asserting that X attacks Y)
%% prp(P) (asserting that P is a property)
%% prp(X, PS) (asserting that the argument X has the set PS of properties)
%% ms(PS) (asserting that the set PS is a motivational state)
%% weight(P, n) (asserting that property P has weight n)
%%
%% An example (example 4 in the paper) is included below.
%% 
%% Usage: Given an argument a, the goal “wgdialog(a, X, [])” acceptance dialogs for weak
%% acceptance of {a} as described in definition 12.
%%

%%
%% The example abductive AF (see figure 1 in the paper).
%% 
%% arg(a). arg(b). arg(c).
%% arg(d). arg(e). arg(f).
%% att(b, c). att(c, b). att(b, a).
%% att(d, a). att(e, d). att(f, e).
%% prp(rr). prp(gg). prp(bb).
%% prp(b, [bb]) :- !. prp(c, [rr]) :- !. prp(d, [rr]) :- !.
%% prp(e, [bb, gg]) :- !. prp(X, []) :- arg(X).
%% ms([rr]). ms([gg]). ms([bb]). ms([rr, gg]). ms([rr, bb]). 
%% ms([gg, bb]). ms([rr, gg, bb]). ms([]).
%% weight(rr, 1). weight(gg, 1). weight(bb, -2).
%%
%% The goal “abduct(b, X, Y, []).” yields, as one two of its answers:
%% X = [[opp, b, a], [pro, c, b], [opp, b, c], [prop_def, [rr]], [opp, ok], [opp, d, a], 
%%     [prop_en, [gg]], [pro, e, d], [opp, f, e], [prop_def, []], [opp, ok], [opp, ok], win] 
%% X = [[opp, b, a], [pro, c, b], [opp, b, c], [prop_def, [rr, gg]], [opp, ok], [opp, d, a], 
%%     [pro, e, d], [opp, f, e], [prop_def, []], [opp, ok], [opp, ok], win] 
%% 
%% These answers correspond to the dialogs described in Example 6 in the paper.  
%%

%%
%% Weight of set of properties in motivational state
%%
weight([], _, 0).

weight([H|T], M, N) :-
	member(H, M),
	!,
	weight(H, HW),
	weight(T, M, TW),
	N is HW + TW.

weight([_|T], M, N) :- weight(T, M, N).

%%
%% Is an attack (or set of attacks) enabled in a motivational state?
%%
enabled(X, Y, M) :-
	ms(M),
	att(X, Y),
	prp(X, XP),
	prp(Y, YP),
	weight(XP, M, XW),
	weight(YP, M, YW),
	YW =< XW.
	
enabled([[X, Y]|T], M) :-
	ms(M),
	enabled(X, Y, M),
	enabled(T, M).	

enabled([], _).

%%
%% Is an attack (or set of attacks) disabled in a motivational state?
%%
disabled([[X, Y]|T], M) :-
	ms(M),
	att(X, Y),
	not(enabled(X, Y, M)),
	disabled(T, M).	

disabled([], _).

%%
%% Is motivating state
%% 
is_ms(M) :- permutation(M, M2), ms(M2).


%%
%% P rules
%%
wgdialog(X)		-->	
	{	arg(X)		},
	
	wgoppmove(X, [], [], [], _, [], _, [], _), [win].

%%
%% Attack end (only if OA contains all available attacks)
%% 
wgoppmove(X, OA, _, DA, DA, EA, EA, M, M)	-->	
	{
		findall(Y, (att(Y, X), not(member([Y, X], OA))), L),
		length(L, 0)
	},
[[opp, ok]].

%%
%% Attack (and then defend)
%%
wgoppmove(X, OA, PA, DA1, DA3, EA1, EA3, M1, M3)			-->	[[opp, Y, X]], 
	{	arg(Y),
		att(Y, X),  
		not(member([Y,X],OA)),
		append(OA,[[Y,X]],OA2)
	},

	wgpromove([Y, X], PA, DA1, DA2, EA1, EA2, M1, M2), 
	wgoppmove(X, OA2, PA, DA2, DA3, EA2, EA3, M2, M3).

%%
%% Defend with attacker
%%
wgpromove([Y,_], PA, DA1, DA2, EA1, EA3, M1, M3)		-->	
	{	arg(Z),
		att(Z, Y), 
		not(member([Z,Y], PA)), 
		append(PA,[[Z,Y]],PA2),
		append(EA1, [[Z,Y]], EA2)
	},
	wgpenable(EA2, M1, M2),
	[[pro, Z, Y]], 
	wgoppmove(Z, [], PA2, DA1, DA2, EA2, EA3, M2, M3). 


%%
%% Defend with property
%%
wgpromove([Y,X], _, DA1, DA2, EA1, EA1, M1, M2)		-->	[[prop_def, P]], 
	{	ms(M2),			% Create new motivational state M2 with new properties P
		append(M1, P, M2),		
		append(DA1, [[Y, X]], DA2),	% attacks must be disabled/enabled in M2			
		disabled(DA2, M2),		
		enabled(EA1, M2)			
	}.

%%
%% Enabling property move
%%
wgpenable(EA, M, M) 								--> %[[prop_en, none]],
	{	enabled(EA, M)	}.

wgpenable(EA, M1, M2)								--> [[prop_en, P]],
	{	not(enabled(EA, M1)),
		ms(M2),
		append(M1, P, M2),
		enabled(EA, M2)
	}.


