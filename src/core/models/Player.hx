package core.models;

// @structInit
class Player {
    public var life :Int;
    public var life_max :Int;
    public var library :Library;
    public var deck :Deck;
    public var hand :Hand;

    public function new() {
        life = 5;
        life_max = 5;
        library = new Library();
        deck = new Deck();
        hand = new Hand();
    }

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
