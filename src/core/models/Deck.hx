package core.models;

// import core.models.Card;

class Deck {
    var cards :Array<Card>;
    var discarded :Array<Card>;

    public function new() {
        cards = [];
        discarded = [];
    }

    function shuffle_discarded_into_deck() {
        // TODO: shuffle discarded
        cards = discarded.copy();
        discarded = [];
    }

    public function add(card :Card) { // TODO: Remove this function
        cards.push(card);
    }

    public function pop() :Null<Card> {
        if (cards.length == 0) shuffle_discarded_into_deck();
        return cards.pop();
    }

    public function discard(card :Card) {
        discarded.push(card);
    }

    public function count() :Int {
        return cards.length + discarded.length;
    }
}
