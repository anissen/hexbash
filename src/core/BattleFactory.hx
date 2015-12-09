
package core;

import core.HexLibrary;
import core.Models.MinionModel;
import core.Models.BattleGameState;
import core.Models.CardModel;
import core.Models.CardType;

using core.HexLibrary.HexTools;
using core.ArrayTools;

typedef BattleInstanceModel = {
    hexes :Array<Hex>,
    gameState :BattleGameState
};

class BattleFactory {
    static public function Generate(seed :Float) :BattleInstanceModel {
        return {
            hexes: get_map(),
            gameState: get_game_state(seed)
        };
    }

    static function get_map() {
        var map_radius :Int = 3;
        var mapHexes = MapFactory.create_hexagon_map(map_radius);
        return mapHexes.filter(function(hex) {
            return (hex.key != '0,0' && hex.key != '-2,0' && hex.key != '2,0');
        });
    }

    static function get_minions(random :luxe.utils.Random) {
        // TODO: Load from file
        var playerId = 0;
        var enemyId = 1;
        var enemyHero = new MinionModel('Enemy', enemyId, 8, new Hex(1, -2), null, true);
        var minions = [
            new MinionModel('Hero', playerId, 10, new Hex(-1, 2), null, true),
            enemyHero
        ];

        var hexes = get_map();
        function walkable(hex :Hex) {
            for (h in hexes) {
                if (h.key == hex.key) return true;
            }
            return false;
        }
        var reachableHexes = enemyHero.hex.reachable(walkable);
        for (i in 0 ... random.int(0, reachableHexes.length)) {
        // for (i in 0 ... reachableHexes.length) {
            minions.push(new MinionModel('Enemy Minion ${i + 1}', enemyId, random.int(1, 6), reachableHexes[i]));
        }

        return minions;
    }

    static function get_game_state(seed :Float) {
        var random = new luxe.utils.Random(seed);
        var gameState = new BattleGameState();
        gameState.random = random;
        gameState.minions = get_minions(random);
        gameState.playerDeck = get_deck(random);
        return gameState;
    }

    static function get_deck(random :luxe.utils.Random) {
        // TODO: Remove the requirement of a separate card text
        var cards = [
            { text: 'Imp', card_type: CardType.Minion('Imp', 3) },
            { text: 'Rat', card_type: CardType.Minion('Rat', 2) },
            { text: 'Rat', card_type: CardType.Minion('Rat', 2) },
            { text: 'Potion', card_type: CardType.Potion(1) },
            { text: 'Potion', card_type: CardType.Potion(3) }
        ];

        function random_int(v :Int) {
            return random.int(v);
        }
        var deck = [];
        for (card in cards.shuffle(random_int)) {
            deck.push(new CardModel(card.text, 0, card.card_type));
        }
        return deck;
    }
}
