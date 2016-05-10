
package core;

import core.Models.BattleModel;
import core.Models.MinionModel;
import core.Models.Action;
import core.Models.MinionAction;

import core.HexLibrary;
using core.HexLibrary.HexTools;
using core.ArrayTools;

class AI {
    static public function do_actions(battleModel :BattleModel) {
        do_ai_actions(battleModel);
        create_ai_minion(battleModel); // TODO: replace this with card play
        battleModel.do_action(EndTurn);
    }

    static function get_ai_minion_action(battleModel :BattleModel, model :MinionModel) :MinionAction {
        // simple AI:
        // 1. Attacks enemy if possible
        // 2. Moves towards enemy hero if possible
        // 3. Performs random available action

        function random_int(v :Int) {
            return battleModel.get_random().int(v);
        }

        var attackActions = battleModel.get_minion_attacks(model.id);
        if (attackActions.length > 0) {
            // Attack hero if available
            for (attack in attackActions) {
                switch (attack) {
                    case Attack(defenderId): if (battleModel.get_minion_from_id(defenderId).hero) return attack;
                    case _:
                }
            }
            return attackActions.random(random_int);
        }

        var playerMinions = battleModel.get_minions().filter(function(m) { return m.playerId != model.playerId; });
        if (playerMinions.length > 0) {
            var playerMinion = playerMinions[0];

            var playerHero = playerMinions.filter(function(m) { return m.hero; });
            if (playerHero.length > 0) {
                playerMinion = playerHero[0];
            }

            // hex i walkable if it exists and a) is unoccupied or b) is occupied by an enemy (to be killed)
            function walkable(hex :Hex) :Bool {
                if (!battleModel.has_hex(hex)) return false;
                var minion = battleModel.get_minion(hex);
                return (minion == null || minion.playerId != model.playerId);
            }

            var path = model.hex.find_path(playerMinion.hex, 100, 6, walkable, true);
            if (path.length > 0) return Move(path[0]);
        }

        var actions = battleModel.get_minion_actions(model.id);
        if (actions.length > 0) {
            return actions.random(random_int);
        }

        return Nothing;
    }

    static function create_ai_minion(battleModel :BattleModel) {
        var currentPlayer = battleModel.get_current_player();
        var ai_heroes = battleModel.get_minions().filter(function(m) { return m.playerId == currentPlayer && m.hero; });
        if (ai_heroes.length == 0) return;

        function random_int(v :Int) {
            return battleModel.get_random().int(v);
        }

        var ai_hero = ai_heroes[0];
        var reachableHexes = ai_hero.hex.reachable(battleModel.is_walkable);
        var randomHex = reachableHexes.random(random_int);
        battleModel.add_minion(new MinionModel('Enemy Minion', currentPlayer, battleModel.get_random().int(1, 7), randomHex, 'spider-alt.png'));
    }

    static function do_ai_actions(battleModel :BattleModel) {
        var newBattleModel = battleModel;
        var chosenActions = [];
        while (true) {
            var model = null;
            var actions = [];
            for (m in newBattleModel.get_minions()) {
                if (m.playerId != battleModel.get_current_player()) continue;
                if (m.actions <= 0) continue;
                model = m;
                actions = newBattleModel.get_minion_actions(m.id);
                if (actions.length > 0) break;
            }
            if (model == null || actions.empty()) break;

            // has minion with available actions
            var minion_action = get_ai_minion_action(newBattleModel, model);
            var ai_action = MinionAction(model.id, minion_action);
            chosenActions.push(ai_action);

            newBattleModel = newBattleModel.clone();
            newBattleModel.do_action(ai_action);
        }

        for (action in chosenActions) {
            battleModel.do_action(action);
        }
    }
}
