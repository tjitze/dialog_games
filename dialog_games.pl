%%
%% This file contains implementations of so called dialog games (proof procedures) for 
%% skeptical and credulous acceptance of an argument in an argumentation framework. Here, 
%% skeptical acceptance means that an argument is a member of the grounded extension 
%% (or, equivalently, of all complete extensions). Credulous acceptance means that an 
%% argument is a member of at least one complete extension (or, equivalently, of at least 
%% one preferred extension).
%%
%% The procedures assume that the argumentation framework is encoded using predicates of
%% the form "arg(X)" (to assert existence of argument X) and "att(X, Y)" (to assert that
%% the argument X attacks the argument Y). An example is included below.
%%
%% The idea is based on the grounded and preferred games studied by Martin Caminada and
%% others. See the papers "Grounded Semantics as Persuasion Dialogue." (Camiada and
%% Podlaszewski, COMMA 2012) and "Preferred semantics as socratic discussion" (Caminada,
%% Dvorak, Vesic, Journal of Logic and Computation 2014). These works were, in turn, based
%% on earlier work by others (see papers for details).
%%
%% This implementation is based on the idea of encoding the rules of a winning dialogue
%% using Prolog DCGs (Definite Clause Grammars). The structure of a dialog in which the
%% proponent wins (i.e. a dialog which proves skeptical/credulous acceptance of an   
%% argument) is encoded using DCG syntax.
%%
%% Usage;
%% gdialog(a, X, []) yields a dialog between PRO and OPP that proves that the argument
%%                   "a" is skeptically accepted (i.e., member of the grounded extension).
%%
%% pdialog(a, X, []) yields a dialog between PRO and OPP that proves that the argument
%%                   "a" is credulously accepted (i.e., member of at least one complete
%%                   or preferred extension).
%%
%% In both cases, failure of the respective rule implies that there is no winning dialog
%% and that the argument not, respectively, a member of the grounded extension, or of one
%% of the complete/preferred extensions.
%%
%% Author: Tjitze Rienstra
%%

%%
%% Example
%%
%% arg(a). arg(b). arg(c). arg(d). arg(e). arg(f). arg(g).
%% att(a, b). att(b, a). att(a, c). att(b, c).
%% att(c, d). att(e, f). att(f, g).
%%
%% gdialog(d, X, []) yields no results (the argument d is not skeptically accepted).
%% gdialog(f, X, []) yields the following result, proving that f is skeptically accepted:
%% X = [[opp, f, g], [pro, e, f], [opp, ok], [opp, ok], [pro, win]] .
%% pdialog(d, X, []) yields the following result, proving that f is credulously accepted:
%% X = [[opp, c, d], [pro, a, c], [opp, b, a], [pro, a, b, aldready_accepted], [opp, ok],
%% [opp, ok], [pro, win]] .
%%

%%
%% Generate a dialog in which the proponent wins that proves skeptical acceptance of
%% the argument X.
%%
gdialog(X)			-->		
	{	arg(X)		},
	gopp(X, [], []),
	[[pro, win]].

%%
%% Generate reply of opponent to the argument X put forward by proponent.
%% Here, the opponent puts forward an attacker Y pointing to X (resulting
%% in a move "[opp, Y, X]") This is followed up by a response of the
%% proponent to Y. Opponent then continues to put forward other available
%% attacks pointing to X, but will not repeat the same attack twice (this
%% is taken care of by the MO argument). The MP argument contains attacks
%% that have been put forward by the proponent.
%%
gopp(X, MO, MP)		-->
	[[opp, Y, X]],
	{	arg(Y),
		att(Y, X),  
		not(member([Y,X],MO)),
		append(MO,[[Y,X]],MO2)
	},
	gpro(Y, MP),
	gopp(X, MO2, MP).

%%
%% Generate reply of opponent to the argument X put forward by proponent.
%% This rule succeeds if no more attacks pointing to X are available. It
%% leads to a move "[opp, ok]", which indicates that the opponent concedes.
%%
gopp(X, MO, _)		-->	
	{
		findall(Y, (att(Y, X), not(member([Y, X], MO))), L),
		length(L, 0)
	},
	[[opp, ok]].

%%
%% Generate reply of proponent to the argument Y put forward by opponent.
%% Proponent puts forward attack Z pointing to Y. Proponent cannot repeat
%% the same attack in a single dispute (kept track of via the set MP).
%% Leads to a move "[pro, Z, Y]". Followed op by reply of opponent to the
%% argument Z.
%%
gpro(Y, MP)			-->	
	[[pro, Z, Y]], 
	{	arg(Z),
		att(Z, Y), 
		not(member([Z,Y], MP)), 
		append(MP,[[Z,Y]],MP2)
	},
	gopp(Z, [], MP2). 

%%
%% Generate a dialog in which the proponent wins that proves credulous acceptance of
%% the argument X.
%%
pdialog(X)			-->
	{	arg(X)		},
	popp(X, [], [X], []),
	[[pro, win]].

%%
%% Generate reply of opponent to the argument X put forward by proponent.
%% Here, the opponent puts forward an attacker Y pointing to X (resulting
%% in a move "[opp, Y, X]") This is followed up by a response of the
%% proponent to Y. Opponent then continues to put forward other available
%% attacks pointing to X, but will not repeat the same attack twice (this
%% is taken care of by the not(member([Y,X],MO)) and append(MO,[[Y,X]],MO2)
%% part). The ACC and REJ arguments contain arguments that are claimed by 
%% the proponent to be accepted/rejected (see ppro rules).
%%
popp(X, MO, ACC, REJ) -->
    [[opp, Y, X]],
    {	arg(Y),
        att(Y, X),
        not(member([Y,X],MO)),
        append(MO,[[Y,X]],MO2)
    },
	ppro(Y, ACC, REJ),
	popp(X, MO2, ACC, REJ).

%%
%% Generate reply of opponent to the argument X put forward by proponent.
%% This rule succeeds if no more attacks pointing to X are available. It
%% leads to a move "[opp, ok]", which indicates that the opponent concedes.
%%
popp(X, MO, _, _) -->
    { findall(Y, (att(Y, X), not(member([Y, X], MO))), L), length(L, 0) },
    [[opp, ok]].

%%
%% Generate reply of proponent to the argument Y put forward by opponent.
%% This rule succeeds if Y is attacked by an argument Z that is already
%% claimed to be accepted. In this case, the opponent may not respond with
%% another attack pointing to Z. (This is what distinguishes the skeptical
%% game from the credulous game). Leads to a move "[pro, Z, Y, already_accepted]".
%%
ppro(Y, ACC, _)		-->
	[[pro, Z, Y, aldready_accepted]],
	{	arg(Z),
		att(Z, Y), 
		member(Z, ACC)
	}. 

%%
%% Generate reply of proponent to the argument Y put forward by opponent.
%% Proponent puts forward attack Z pointing to Y. It is then established
%% that Z is accepted and Y is rejected. However, the set of accepted and
%% rejected arguments may not have a nonempty intersection. Leads to a
%% move "[pro, Z, Y]". Followed op by reply of opponent to the argument Z.
%%
ppro(Y, ACC, REJ)		-->
	[[pro, Z, Y]], 
	{	arg(Z),
		att(Z, Y), 
		append(REJ,[Y], REJ2),
		append(ACC,[Z], ACC2),
		empty_intersection(REJ2, ACC2)
	},
	popp(Z, [], ACC2, REJ2). 

%%
%% Succeeds if List1 and List2 have an empty intersection.pr
%%
empty_intersection(List1, List2) :- \+ (member(Element, List1), member(Element, List2)).