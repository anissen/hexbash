package core.models;

// import core.models.Card;

class Deck {
    var cards :Array<Card>;
    var discarded :Array<Card>;

    public function new() {

    }

    function shuffle_discarded_into_deck() {
        // TODO: shuffle discarded
        cards = discarded.copy();
        discarded = [];
    }

    public function pop() :Null<Card> {
        if (cards.length == 0) shuffle_discarded_into_deck();
        return cards.pop();
    }

    public function discard(card :Card) {
        discarded.push(card);
    }
}
