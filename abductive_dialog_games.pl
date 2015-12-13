
%%
%% This is the implementation of the dialog games (a particular kind of proof 
%% procedure) described in the paper “Abduction in Argumentation: Dialogical Proof
%% Procedures and Instantiation” (Booth, Gabbay, Kaci, Rienstra, van der Torre. NMR2014).
%% More precisely, it is procedure that generates skeptical explanation dialogues as
%% described in definition 9. 
%%
%% The procedure assumes that the abductive argumentation framework is modelled using 
%% the following predicates:
%%
%% afstate(S) (where S identifies an abducible AF)
%% arg_in_state(X, S) (asserting that the abducible AF S contains argument X)
%% att_in_state(X, Y, S) (asserting that the abducible AF S contains the attack X->Y)
%% expansionof(S1,S2) (asserting that all args/attacks contained in Y are also contained in X)
%%
%% An example (the one shown in figure 1) is included below.
%% 
%% Usage: Given an argument a, the goal “abduct(a, X, Y, [])” yields pairs of X,Y, where X is 
%% an abducible AF that explains skeptical support for the observation {a}, Y is a skeptical
%% explanation dialogue for {a}.
%%

%%
%% The example abductive AF (see figure 1 in the paper).
%%
%% afstate(f).	afstate(g1).	afstate(g2).	afstate(g3).
%% expansionof(f,g2).	expansionof(g1,f).	expansionof(g3,g2).
%% arg_in_state(a, f).	arg_in_state(d, f).	arg_in_state(e, g1).
%% arg_in_state(b, g2).	arg_in_state(c, g2).	arg_in_state(e, g3).
%% arg_in_state(A,X)	:-	afstate(Y), expansionof(X,Y), arg_in_state(A,Y).
%% att_in_state(a,b,f).	att_in_state(e,a,g1).	att_in_state(e,c,g1).
%% att_in_state(b,c,g2).	att_in_state(c,b,g2).	att_in_state(e,c,g3).
%% att_in_state(A,B,X)	:-	afstate(Y), expansionof(X,Y), att_in_state(A,B,Y).
%%
%% The goal “abduct(b, X, Y, []).” yields, as one of its answers:
%%
%% X = [g1],
%% Y = [[opp, c, b], [f, g1, g2, g3], [pro_pos, e, c], [g1, g3], [opp, ok], 
%%     [g1, g3], [opp, a, b], [g1, g3], [pro_pos, e, a], [g1], [opp, ok], 
%%     [g1], [opp, ok], [g1], [pro, win], [g1]] 
%% 
%% This answer corresponds to the dialog described in Example 2 in the paper.  
%%

%%
%% att(A,B) succeeds for every pair A,B where A attacks B in one of the abducible AFs.
%% arg(A) succeeds for every argument A contained in one of the abducible AFs.
%%
att(A,B)	:-	setof([C, D], S^att_in_state(C,D,S), Attacks), member([A,B], Attacks).
arg(A)		:-	setof(B, S^arg_in_state(B, S), Args), member(A, Args).

%%
%% The goal “abduct(a, X, Y, [])” yields pairs of X,Y, where X is an abducible AF that explains 
%% skeptical support for the observation {a}, Y is a skeptical explanation dialogue for {a}.
%%
abduct(X, AC2)					-->		
	{	arg(X),
		findall(S, afstate(S), AC)
	},
	opp_reply(X, [], [], AC, AC2),
	[[pro, win], AC2].

%%
%% Generate reply of opponent to the argument X put forward by proponent.
%% Here, the opponent puts forward an attacker Y pointing to X (resulting
%% in a move "[opp, Y, X]”). This is followed up by a response of the
%% proponent to Y. Opponent then continues to put forward other available
%% attacks pointing to X, but will not repeat the same attack twice (this
%% is taken care of by the MO argument). The MP argument contains attacks
%% that have been put forward by the proponent. The AC1/AC2 arguments are
%% used to pass through active abducible AFs.
%%
opp_reply(X, MO, MP, AC1, AC2)	-->
	{	
		arg(Y),
		att(Y, X),  
		not(member([Y,X],MO)),
		append(MO,[[Y,X]],MO2)
	},
	[[opp, Y, X], AC1],
	pro_reply(Y, X, MP, AC1, AC1B),
	opp_reply(X, MO2, MP, AC1B, AC2).

%%
%% Generate reply of opponent to the argument X put forward by proponent.
%% This rule succeeds if no more attacks pointing to X are available. It
%% leads to a move "[opp, ok]", which indicates that the opponent concedes.
%%
opp_reply(X, MO, _, AC, AC)		-->	
	{
		findall(Y, (att(Y, X), not(member([Y, X], MO))), L),
		length(L, 0)
	},
	[[opp, ok], AC].

%%
%% Generate reply of proponent to the argument Y put forward by opponent.
%% Proponent puts forward attack Z pointing to Y. Proponent cannot repeat
%% the same attack in a single dispute (kept track of via the set MP).
%% Leads to a move "[pro_pos, Z, Y]" (called hypothetical PRO defence in
%% the paper). Followed op by reply of opponent to the argument Z. Update
%% AC1/AC2 by retaining only abducible AFs that contain the attack Z->Y.
%%
pro_reply(Y, _, MP, AC1, AC2)	-->	
	{	
		arg(Z),
		att(Z, Y), 
		not(member([Z,Y], MP)), 					
		append(MP,[[Z,Y]],MP2),
		findall(S, (afstate(S), member(S, AC1), att_in_state(Z,Y,S)), AC1B),
		not(length(AC1B, 0))
	},
	[[pro_pos, Z, Y], AC1B], 
	opp_reply(Z, [], MP2, AC1B, AC2). 

%%
%% Generate reply of proponent to the attack Y->X put forward by opponent.
%% This rule leads to a move "[pro_neg, Z, Y]" (called hypothetical PRO negation
%% in the paper). Update AC1/AC2 by retaining only abducible AFs that *do not* 
%% contain the attack Z->Y.
%%
pro_reply(Y, X, _, AC1, AC2)	-->	
	{	
		att(Y, X), 
		findall(S, (afstate(S), member(S, AC1), not(att_in_state(Y,X,S))), AC2),
		not(length(AC2, 0))
	},
	[[pro_neg, Y, X], AC2]. 

