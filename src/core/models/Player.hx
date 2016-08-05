package core.models;

// @structInit
class Player {
    public var life :Int;
    public var life_max :Int;
    public var library :Library;
    public var deck :Deck;
    public var hand :Hand;
    public var equipment :Array<Equipment>;

    public function new() {
        life = 5;
        life_max = 5;
        library = new Library();
        deck = new Deck();
        hand = new Hand();
        equipment = [new Equipment.Fists() /* new Equipment.Spellbook() */];

        deck.add(new Card('Wolf Cub', 1, 2, 'wolf-head.png', Minion('Wolf', 1)));
        deck.add(new Card('Wolf', 1, 2, 'wolf-head.png', Minion('Wolf', 2)));
        deck.add(new Card('Alpha Wolf', 1, 2, 'wolf-head.png', Minion('Wolf', 3)));
        deck.add(new Card('Direwolf', 1, 2, 'wolf-head.png', Minion('Wolf', 4)));
        deck.add(new Card('Archer', 1, 2, 'crowned-skull.png', Minion('Archer', 3)));
    }

    public function get_cards_from_equipment() :Array<Card> {
        var cards = [];
        for (e in equipment) {
            if (!Std.is(e, Equipment.CardProvider)) continue;
            var cardProvider :Equipment.CardProvider = cast e;
            if (cardProvider == null) continue;
            cards = cards.concat(cardProvider.get_cards());
        }
        return cards;
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
