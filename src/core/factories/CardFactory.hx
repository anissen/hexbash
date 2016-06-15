package core.factories;

import core.models.Card;

class CardFactory {
    var cardData :Map<String, Json>;

    public function new(cardDatabase :Array<Card>) {
        cardData = new Map();
        // var database :Array<CardData> = Luxe.resources.json('assets/data/minions.json').asset.json;
        for (d in cardDatabase) {
            cardData[d.identifier] = d;
        }
    }

    public function create(id :String) :Card {
        return cardData[id];
    }
}
