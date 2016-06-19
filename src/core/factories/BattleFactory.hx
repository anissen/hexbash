
package core.factories;

import core.HexLibrary;
import core.models.Minion;
import core.models.Battle;
import core.models.Card;
import core.Models.CardType;

using core.HexLibrary.HexTools;
using core.tools.ArrayTools;

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
        // if (Math.random() < 0.5) {
        //     var mapHexes = MapFactory.create_hexagon_map(3);
        //     return mapHexes.filter(function(hex) {
        //         return (hex.key != '0,0' && hex.key != '-2,0' && hex.key != '2,0');
        //     });
        // }
        return MapFactory.create_custom_map();
    }

    static function get_minions(random :luxe.utils.Random) {
        // TODO: Load from file
        var playerId = 0;
        var enemyId = 1;
        var enemyHero = new HeroModel('Enemy', enemyId, 8, new Hex(1, -2), 'crowned-skull.png');
        var minions :Array<MinionModel> = [
            new HeroModel('Hero', playerId, 10, new Hex(-1, 2), 'pointy-hat.png'),
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
            minions.push(new MinionModel('Enemy Minion ${i + 1}', enemyId, random.int(1, 6), reachableHexes[i], 'spider-alt.png'));
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
            var hero = battleModel.get_hero(battleModel.get_current_player());
            var enemies = hero.hex.ring(1).map(function(h) {
                var m = battleModel.get_minion(h);
                if (m == null || m.playerId == battleModel.get_current_player()) return null;
                return m;
            }).filter(function(m) { return m != null; });
            if (enemies.empty()) return [];
            var randomEnemy = enemies.random(function(v) { return battleModel.get_random().int(v); });
            return [core.Models.Command.DamageMinion(randomEnemy.id, 3)];
        }

        function spell_boost(battleModel :core.Models.BattleModel) {
            var hero = battleModel.get_hero(battleModel.get_current_player());
            var allies = hero.hex.ring(1).map(function(h) {
                var m = battleModel.get_minion(h);
                if (m == null || m.playerId != battleModel.get_current_player()) return null;
                return m;
            }).filter(function(m) { return m != null; });
            if (allies.empty()) return [];
            return [ for (a in allies) core.Models.Command.HealMinion(a.id, 2) ];
        }

        function spell_swap(battleModel :core.Models.BattleModel) {
            var hero = battleModel.get_hero(battleModel.get_current_player());
            var nearby = hero.hex.ring(1).map(function(h) {
                return battleModel.get_minion(h);
            }).filter(function(m) { return m != null; });
            var randomMinion = nearby.random(function(v) { return battleModel.get_random().int(v); });

            var diff = Math.floor(Math.abs(randomMinion.power - hero.power));
            if (randomMinion.power > hero.power) {
                return [
                    core.Models.Command.HealMinion(hero.id, diff),
                    core.Models.Command.DamageMinion(randomMinion.id, diff)
                ];
            }

            if (randomMinion.power < hero.power) {
                return [
                    core.Models.Command.DamageMinion(hero.id, diff),
                    core.Models.Command.HealMinion(randomMinion.id, diff)
                ];
            }

            return [];
        }

        function spell_trade_places(battleModel :core.Models.BattleModel) {
            var hero = battleModel.get_hero(battleModel.get_current_player());
            var nearby = hero.hex.ring(1).map(battleModel.get_minion).filter(function(m) { return m != null; });
            if (nearby.empty()) return [];
            var randomMinion = nearby.random(function(v) { return battleModel.get_random().int(v); });
            return [
                core.Models.Command.MoveMinion(hero.id, randomMinion.hex),
                core.Models.Command.MoveMinion(randomMinion.id, hero.hex)
            ];
        }

        function spell_push(battleModel :core.Models.BattleModel) {
            var hero = battleModel.get_hero(battleModel.get_current_player());
            var nearby = hero.hex.ring(1).map(battleModel.get_minion).filter(function(m) { return m != null; });
            if (nearby.empty()) return [];
            // var randomMinion = nearby.random(function(v) { return battleModel.get_random().int(v); });
            nearby = nearby.shuffle(function(v) { return battleModel.get_random().int(v); });
            var commands = [];
            for (m in nearby) {
                var dir = m.hex.subtract(hero.hex);
                var newPos = m.hex.add(dir);
                if (battleModel.get_minion(newPos) == null) {
                    commands.push(core.Models.Command.MoveMinion(m.id, newPos));
                }
            }
            return commands;
            // return [core.Models.Command.MoveMinion(randomMinion.id, hero.hex)];
        }

        function spell_attack(damage :Int, battleModel :core.Models.BattleModel) {
            var hero = battleModel.get_hero(battleModel.get_current_player());
            var enemies = hero.hex.ring(1).map(function(h) {
                var m = battleModel.get_minion(h);
                if (m == null || m.playerId == battleModel.get_current_player()) return null;
                return m;
            }).filter(function(m) { return m != null; });
            if (enemies.empty()) return [];
            var randomEnemy = enemies.random(function(v) { return battleModel.get_random().int(v); });
            return [core.Models.Command.DamageMinion(randomEnemy.id, damage)];
        }

        function effect_heal(battleModel :core.Models.BattleModel) {
            // var tower = how_to_get_tower_minion;
            // var allies = hero.hex.ring(1).map(function(h) {
            //     var m = battleModel.get_minion(h);
            //     if (m == null || m.playerId != battleModel.get_current_player()) return null;
            //     return m;
            // }).filter(function(m) { return m != null; });
            // if (allies.empty()) return [];
            // return [ for (a in allies) core.Models.Command.HealMinion(a.id, 2) ];
        }

        function healing_tower_trigger(battleModel :core.Models.BattleModel, event :core.Models.Event) {
            return switch (event) {
                case TurnStarted(playerId): return (playerId == 0); // HACK
                case _: return false;
            };
        }

        // TODO: Remove the requirement of a separate card text
        var cards = [
            { text: 'Imp', card_type: CardType.Minion('Imp', 3) },
            { text: 'Imp', card_type: CardType.Minion('Imp', 4) },
            { text: 'Rat', card_type: CardType.Minion('Rat', 1) },
            { text: 'Rat', card_type: CardType.Minion('Rat', 2) },
            // { text: 'Potion', card_type: CardType.Potion(1) },
            // { text: 'Potion', card_type: CardType.Potion(2) },
            // { text: 'Potion', card_type: CardType.Potion(3) },
            // { text: 'Knock Knock', card_type: CardType.Spell(spell_bam, 2) },
            // { text: 'Boost Morale', card_type: CardType.Spell(spell_boost, 2) },
            // { text: 'Power Swap', card_type: CardType.Spell(spell_swap, 2) },
            { text: 'Trade Places', card_type: CardType.Spell(spell_trade_places, 2) },
            { text: 'Force Push', card_type: CardType.Spell(spell_push, 1) },
            { text: 'Attack 1', card_type: CardType.Attack(1) },
            { text: 'Attack 2', card_type: CardType.Attack(2) },
            { text: 'Attack 3', card_type: CardType.Attack(3) }
            // { text: 'Healing Tower', card_type: CardType.Tower('Healing Tower', 1, healing_tower_trigger, spell_boost) },
            // { text: 'Healing Tower', card_type: CardType.Tower('Healing Tower', 1, healing_tower_trigger, spell_boost) },
            // { text: 'Healing Tower', card_type: CardType.Tower('Healing Tower', 1, healing_tower_trigger, spell_boost) }
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
