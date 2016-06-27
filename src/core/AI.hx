
package core;

import core.models.Battle;
import core.models.Minion;
import core.Enums.Action;
import core.Enums.MinionAction;

import core.HexLibrary;
using core.HexLibrary.HexTools;
using core.tools.ArrayTools;

class AI {
    static public function do_actions(battle :Battle) {
        do_ai_actions(battle);
        create_ai_minion(battle); // TODO: replace this with card play
        battle.do_action(EndTurn);
    }

    static function get_ai_minion_action(battle :Battle, model :Minion) :MinionAction {
        // simple AI:
        // 1. Attacks enemy if possible
        // 2. Moves towards enemy hero if possible
        // 3. Performs random available action

        function random_int(v :Int) {
            return battle.get_random().int(v);
        }

        var attackActions = battle.get_minion_attacks(model.id);
        if (attackActions.length > 0) {
            // Attack hero if available
            for (attack in attackActions) {
                switch (attack) {
                    case Attack(defenderId): if (battle.get_minion_from_id(defenderId).hero) return attack;
                    case _:
                }
            }
            return attackActions.random(random_int);
        }

        var playerMinions = battle.get_minions().filter(function(m) { return m.playerId != model.playerId; });
        if (playerMinions.length > 0) {
            var playerMinion = playerMinions[0];

            var playerHero = playerMinions.filter(function(m) { return m.hero; });
            if (playerHero.length > 0) {
                playerMinion = playerHero[0];
            }

            // hex i walkable if it exists and a) is unoccupied or b) is occupied by an enemy (to be killed)
            function walkable(hex :Hex) :Bool {
                if (!battle.has_hex(hex)) return false;
                var minion = battle.get_minion(hex);
                return (minion == null || minion.playerId != model.playerId);
            }

            var path = model.hex.find_path(playerMinion.hex, 100, 6, walkable, true);
            if (path.length > 0) return Move(path[0]);
        }

        var actions = battle.get_minion_actions(model.id);
        if (actions.length > 0) {
            return actions.random(random_int);
        }

        return Nothing;
    }

    static function create_ai_minion(battle :Battle) {
        var currentPlayer = battle.get_current_player();
        var ai_heroes = battle.get_minions().filter(function(m) { return m.playerId == currentPlayer && m.hero; });
        if (ai_heroes.length == 0) return;

        function random_int(v :Int) {
            return battle.get_random().int(v);
        }

        var ai_hero = ai_heroes[0];
        var reachableHexes = ai_hero.hex.reachable(battle.is_walkable);
        var randomHex = reachableHexes.random(random_int);
        battle.add_minion(new Minion('Enemy Minion', currentPlayer, battle.get_random().int(1, 7), randomHex, 'spider-alt.png', false));
    }

    static function do_ai_actions(battle :Battle) {
        // var newBattle = battle;
        // var chosenActions = [];
        // while (true) {
        //     var model = null;
        //     var actions = [];
        //     for (m in newBattle.get_minions()) {
        //         if (m.playerId != battle.get_current_player()) continue;
        //         if (m.actions <= 0) continue;
        //         model = m;
        //         actions = newBattle.get_minion_actions(m.id);
        //         if (actions.length > 0) break;
        //     }
        //     if (model == null || actions.empty()) break;
        //
        //     // has minion with available actions
        //     var minion_action = get_ai_minion_action(newBattle, model);
        //     var ai_action = MinionAction(model.id, minion_action);
        //     chosenActions.push(ai_action);
        //
        //     newBattle = newBattle.clone();
        //     newBattle.do_action(ai_action);
        // }
        //
        // for (action in chosenActions) {
        //     battle.do_action(action);
        // }

        while (true) {
            var model = null;
            var actions = [];
            for (m in battle.get_minions()) {
                if (m.playerId != battle.get_current_player()) continue;
                if (m.actions <= 0) continue;
                model = m;
                actions = battle.get_minion_actions(m.id);
                if (actions.length > 0) break;
            }
            if (model == null || actions.empty()) break;

            // has minion with available actions
            var minion_action = get_ai_minion_action(battle, model);
            var ai_action = MinionAction(model.id, minion_action);
            battle.do_action(ai_action);
        }
    }
}
