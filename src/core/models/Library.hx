package core.models;

class Library {
    var cardIds :Array<String>();

    public function new() {
        cardIds = [];
    }

    public function add_card(id :String) {
        cardIds.push(id);
    }

    public function create_card(id :String) :Card {
        return new Card()
    }
}
