
package core;

import core.HexLibrary;
import core.Models.HeroModel;
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
        // var mapHexes = MapFactory.create_hexagon_map(3);
        // return mapHexes.filter(function(hex) {
        //     return (hex.key != '0,0' && hex.key != '-2,0' && hex.key != '2,0');
        // });
        return MapFactory.create_custom_map();
    }

    static function get_minions(random :luxe.utils.Random) {
        // TODO: Load from file
        var playerId = 0;
        var enemyId = 1;
        var enemyHero = new HeroModel('Enemy', enemyId, 8, new Hex(1, -2));
        var minions :Array<MinionModel> = [
            new HeroModel('Hero', playerId, 10, new Hex(-1, 2)),
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
        function spell_bam(battleModel :core.Models.BattleModel) {
            var heroes = battleModel.get_minions().filter(function(m) {
                return m.playerId == battleModel.get_current_player() && m.hero;
            });
            var hero = heroes[0];
            var enemies = hero.hex.ring(1).map(function(h) {
                var m = battleModel.get_minion(h);
                if (m == null || m.playerId == battleModel.get_current_player()) return null;
                return m;
            }).filter(function(m) { return m != null; });
            var randomEnemy = enemies.random(function(v) { return battleModel.get_random().int(v); });
            return [core.Models.Event.MinionDamaged(randomEnemy.id, 3)];
        }

        function spell_boost(battleModel :core.Models.BattleModel) {
            var heroes = battleModel.get_minions().filter(function(m) {
                return m.playerId == battleModel.get_current_player() && m.hero;
            });
            var hero = heroes[0];
            var allies = hero.hex.ring(1).map(function(h) {
                var m = battleModel.get_minion(h);
                if (m == null || m.playerId != battleModel.get_current_player()) return null;
                return m;
            }).filter(function(m) { return m != null; });
            return [ for (a in allies) core.Models.Event.MinionHealed(a.id, 1) ];
        }

        // TODO: Remove the requirement of a separate card text
        var cards = [
            { text: 'Imp', card_type: CardType.Minion('Imp', 3) },
            { text: 'Imp', card_type: CardType.Minion('Imp', 4) },
            { text: 'Rat', card_type: CardType.Minion('Rat', 1) },
            { text: 'Rat', card_type: CardType.Minion('Rat', 2) },
            { text: 'Potion', card_type: CardType.Potion(1) },
            { text: 'Potion', card_type: CardType.Potion(2) },
            { text: 'Potion', card_type: CardType.Potion(3) },
            { text: 'Bam!', card_type: CardType.Spell(spell_bam) },
            { text: 'Boost!', card_type: CardType.Spell(spell_boost) }
        ];

        function random_int(v :Int) {
            return random.int(v);
        }
        var deck = [];
        for (card in cards.shuffle(random_int)) {
            deck.push(new CardModel(card.text, 0, card.card_type));
            // deck.push(new CardModel(card.text, 0, card.card_type)); // take two of each card
        }
        return deck;
    }
}
