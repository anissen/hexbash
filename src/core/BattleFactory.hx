
package core;

import core.HexLibrary;
import core.Models.MinionModel;
import core.Models.BattleGameState;
import core.Models.CardModel;
import core.Models.CardType;

typedef BattleInstanceModel = {
    hexes :Array<Hex>,
    gameState :BattleGameState
};

class BattleFactory {
    static public function Generate(seed :Int) :BattleInstanceModel {
        return {
            hexes: get_map(),
            gameState: get_game_state()
        };
    }

    static function get_map() {
        var map_radius :Int = 3;
        var mapHexes = MapFactory.create_hexagon_map(map_radius);
        return mapHexes.filter(function(hex) {
            return (hex.key != '0,0' && hex.key != '-2,0' && hex.key != '2,0');
        });
    }

    static function get_minions() {
        // TODO: Load from file
        var playerId = 0;
        var enemyId = 1;
        var minions = [
            new MinionModel('Hero', playerId, 10, new Hex(-1, 2), null, true),
            new MinionModel('Hero Minion 1', playerId, 2, new Hex(-2, 2)),
            new MinionModel('Enemy', enemyId, 8, new Hex(1, -2), null, true),
            new MinionModel('Enemy Minion 2', enemyId, 3, new Hex(2, -2)),
            new MinionModel('Enemy Minion 1', enemyId, 3, new Hex(0, -2))
        ];
        return minions;
    }

    static function get_game_state() {
        var gameState = new BattleGameState();
        gameState.minions = get_minions();
        gameState.playerDeck = get_deck();
        return gameState;
    }

    static function get_deck() {
        // TODO: Remove the requirement of a separate card text
        var cards = [
            { text: 'Imp', card_type: CardType.Minion('Imp', 3) },
            { text: 'Rat', card_type: CardType.Minion('Rat', 2) },
            { text: 'Rat', card_type: CardType.Minion('Rat', 2) },
            { text: 'Potion', card_type: CardType.Potion(1) },
            { text: 'Potion', card_type: CardType.Potion(3) }
        ];

        var deck = [];
        for (card in cards) {
            deck.push(new CardModel(card.text, 0, card.card_type));
        }
        return deck;
    }
}
