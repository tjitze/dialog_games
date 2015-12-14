![Paradox](https://upload.wikimedia.org/wikipedia/en/e/e8/Escher_Waterfall.jpg)

This repository contains implementations of dialog games for argumentation frameworks (AFs) and 
for two extensions of AFs that I developed during my PhD (abductive argumentation frameworks and property-based argumentation frameworks).

Dialog games are proof theories in which a proof is represented by a dialogue between a 
proponent (trying to prove a claim) and opponent (challenging the proponent's claims). A dialog 
    won by the proponent represents a proof of the initial claim.
The implementations I offer here are done in Prolog and rely heavily on DCGs (definite clause grammars).
In short, the procedures are implemented by defining 
    the structure of a dialog that is won by the proponent as if it is a grammar.
This turned out to be a very clean way to implement this type of procedure.

The file [dialog_games.pl](https://github.com/tjitze/dialog_games/blob/master/dialog_games.pl) 
contains an implementation of the so called skeptical and credulous games (also called grounded and preferred games).
References to the theoretical background can be found inside.

The file [abductive_dialog_games.pl](https://github.com/tjitze/dialog_games/blob/master/abductive_dialog_games.pl) 
contains a procedure described in the paper ["Abduction in Argumentation: Dialogical Proof Procedures and Instantiation"](https://github.com/tjitze/dialog_games/blob/master/abductive_dialog_games.pdf) (Booth, Gabbay, Kaci, Rienstra, van der Torre. NMR2014).

The file [property_based_preferences.pl](https://github.com/tjitze/dialog_games/blob/master/property_based_preferences.pl) 
contains a procedure described in the paper [“Property-based Preferences in Abstract Argumentation“](https://github.com/tjitze/dialog_games/blob/master/property_based_preferences.pdf) (Booth, Kaci, Rienstra, ADT2013).


