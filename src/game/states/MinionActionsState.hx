
package game.states;

import core.HexLibrary;
import luxe.Input.MouseEvent;
import luxe.options.VisualOptions;
import luxe.Scene;
import luxe.States.State;
import luxe.tween.Actuate;
import luxe.Vector;
import luxe.Visual;
import luxe.Color;
import snow.api.Promise;

import core.Models;
import core.PromiseQueue;
import game.Entities.Card;
import game.Entities.Minion;
import game.Entities.HexTile;
import game.Entities.BattleMap;
import game.Components;

using core.HexLibrary.HexTools;

class MinionActionsState extends State {
    static public var StateId :String = 'MinionActionsState';
    var battleModel :BattleModel;
    var battleMap :BattleMap;
    var model :MinionModel;
    var has_data :Bool;

    public function new() {
        super({ name: StateId });
        has_data = false;
    }

    override function onenabled<T>(value :T) {
        var data :{ model :MinionModel, battleModel :BattleModel, battleMap :BattleMap } = cast value;
        model = data.model;
        battleModel = data.battleModel;
        battleMap = data.battleMap;
        has_data = true;
    }

    override public function onrender() {
        if (!has_data) return;
        var pos = Luxe.camera.screen_point_to_world(Luxe.screen.cursor.pos);
        var mouse_hex = battleMap.pos_to_hex(pos);
        for (action in battleModel.get_minion_actions(model)) {
            switch (action) {
                case Move(hex):
                    var pos = battleMap.hex_to_pos(hex);
                    var radius = (mouse_hex.key == hex.key ? 20 : 10);
                    Luxe.draw.circle({ x: pos.x, y: pos.y, r: radius, immediate: true, depth: 15 });
                case Attack(other):
                    var pos = battleMap.hex_to_pos(other.hex);
                    var radius = (mouse_hex.key == other.hex.key ? 20 : 10);
                    Luxe.draw.circle({ x: pos.x, y: pos.y, r: radius, immediate: true, depth: 15, color: new Color(1, 0, 0) });
            }
        }
    }

    override public function onmousedown(event :luxe.Input.MouseEvent) {
        if (!has_data) return;
        var pos = Luxe.camera.screen_point_to_world(event.pos);
        var mouse_hex = battleMap.pos_to_hex(pos);
        for (action in battleModel.get_minion_actions(model)) {
            switch (action) {
                case Move(hex):
                    if (mouse_hex.key == hex.key) {
                        battleModel.do_action(MinionAction(model, Move(hex)));
                        return;
                    }
                case Attack(other):
                    if (mouse_hex.key == other.hex.key) {
                        battleModel.do_action(MinionAction(model, Attack(other)));
                        return;
                    }
            }
        }
    }

    override public function onkeydown(event :luxe.Input.KeyEvent) {
        if (event.keycode == luxe.Input.Key.key_m) {
            var moves = battleModel.get_minion_moves(model);
            if (moves.length == 0) return;
            var randomMove = moves[Math.floor(moves.length * Math.random())];
            battleModel.do_action(MinionAction(model, randomMove));
        } else if (event.keycode == luxe.Input.Key.key_a) {
            var attacks = battleModel.get_minion_attacks(model);
            if (attacks.length == 0) return;
            var randomAttack = attacks[Math.floor(attacks.length * Math.random())];
            battleModel.do_action(MinionAction(model, randomAttack));
        } /* else if (event.keycode == luxe.Input.Key.key_p) {
            var minion2 = minionMap[0];
            if (minion == null || minion2 == null) return;
            var model = minion.model;
            var randomEnemy = battleModel.get_minions().asdf
            var minionModel2 = minion2.model;
            var path = minionModel.hex.find_path(minionModel2.hex, 100, 6, battleModel.is_walkable, true);
            for (p in path) {
                battleModel.do_action(MinionAction(minionModel, core.Models.MinionAction.Move(p)));
            }
        } */
    }
}
