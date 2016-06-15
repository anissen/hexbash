package core;

// @structInit
class Player {
    @:isVar life(default, default) :Int;
    @:isVar life_max(default, default) :Int;
    @:isVar library(default, default) :Library;
    @:isVar deck(default, default) :Deck;
    @:isVar hand(default, default) :Array<Card>;

    // var life :Int;
    // var life_max :Int;
    // var library :Library;
    // var deck :Array<Card>;
    // var hand :Array<Card>;

    // var weapon :Weapon;
    // var amor :Amor;
}

// class Card {
//     var name :String;
//     var cost :Int;
//     var power :Int;
//     var identifier :String;
//     var icon :String;
//
//     public function new(json :Json) {
//         this = json;
//     }
// }

/*
The game state has:
- Player life
- Player library
- Player deck

The world state has:
- Player position

The battle state has:
- Player hand
- Player minions

The player has a library of cards.
Cards are instantiated from the library.
The deck is made up of instantiated cards.
*/
