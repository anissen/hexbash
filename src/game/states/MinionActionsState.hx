
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
                case Move(_, hex):
                    var pos = battleMap.hex_to_pos(hex);
                    var radius = (mouse_hex.key == hex.key ? 20 : 10);
                    Luxe.draw.circle({ x: pos.x, y: pos.y, r: radius, immediate: true, depth: 15 });
                case Attack(_, other):
                    var pos = battleMap.hex_to_pos(other.hex);
                    var radius = (mouse_hex.key == other.hex.key ? 20 : 10);
                    Luxe.draw.circle({ x: pos.x, y: pos.y, r: radius, immediate: true, depth: 15, color: new Color(1, 0, 0) });
                case _: // Nothing
            }
        }
    }

    override public function onmousedown(event :luxe.Input.MouseEvent) {
        if (!has_data) return;
        var pos = Luxe.camera.screen_point_to_world(event.pos);
        var mouse_hex = battleMap.pos_to_hex(pos);
        for (action in battleModel.get_minion_actions(model)) {
            switch (action) {
                case Move(model, hex):
                    if (mouse_hex.key == hex.key) {
                        battleModel.do_action(Move(model, hex));
                        return;
                    }
                case Attack(model, other):
                    if (mouse_hex.key == other.hex.key) {
                        battleModel.do_action(Attack(model, other));
                        return;
                    }
                case _: // nothing
            }
        }
    }

    /*
    override public function onkeydown(event :luxe.Input.KeyEvent) {
        if (event.keycode == luxe.Input.Key.key_m) {
            var minion = minionMap[0];
            if (minion == null) return;
            var minionModel = minion.model;
            var moves = battleModel.get_minion_moves(minionModel);
            if (moves.length == 0) return;
            var randomMove = moves[Math.floor(moves.length * Math.random())];
            battleModel.do_action(randomMove);
        } else if (event.keycode == luxe.Input.Key.key_a) {
            var minion = minionMap[0];
            if (minion == null) return;
            var minionModel = minion.model;
            var attacks = battleModel.get_minion_attacks(minionModel);
            if (attacks.length == 0) return;
            var randomAttack = attacks[Math.floor(attacks.length * Math.random())];
            battleModel.do_action(randomAttack);
        } else if (event.keycode == luxe.Input.Key.key_p) {
            var minion = minionMap[1];
            var minion2 = minionMap[0];
            if (minion == null || minion2 == null) return;
            var minionModel = minion.model;
            var minionModel2 = minion2.model;
            // var nearbyHexes = minionModel2.hex.reachable(battleModel.is_walkable, 1); // HACK because endpoint is not reachable
            // var randomNearbyHex = nearbyHexes[Math.floor(nearbyHexes.length * Math.random())];

            function walkable(hex :Hex) {
                if (!battleModel.has_hex(hex)) return false;
                if (hex.key == minionModel2.hex.key) return true; // Ignore that goal is occupied by a minion
                if (battleModel.get_minion(hex) != null) return false;
                return true;
            }

            var path = minionModel.hex.find_path(minionModel2.hex, 100, 6, walkable);
            for (i in 0 ... path.length - 1) {
                battleModel.do_action(core.Models.Action.Move(minionModel, path[i]));
            }
        }
    }
    */
}
