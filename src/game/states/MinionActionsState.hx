
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
import game.Entities.CardEntity;
import game.Entities.MinionEntity;
import game.Entities.HexTile;
import game.Entities.BattleMap;
import game.Components;

using Lambda;
using core.HexLibrary.HexTools;
using core.ArrayTools;

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
        if (model.actions <= 0) {
            Main.states.disable(StateId);
            Main.states.enable(HandState.StateId);
        }
    }

    override public function onrender() {
        if (!has_data) return;
        var pos = Luxe.camera.screen_point_to_world(Luxe.screen.cursor.pos);
        var mouse_hex = battleMap.pos_to_hex(pos);
        for (action in battleModel.get_minion_actions(model.id)) {
            switch (action) {
                case Nothing:
                case Move(hex):
                    var pos = battleMap.hex_to_pos(hex);
                    var radius = (mouse_hex.key == hex.key ? 20 : 10);
                    Luxe.draw.circle({ x: pos.x, y: pos.y, r: radius, immediate: true, depth: 15 });
                case Attack(defenderId):
                    var defender = battleModel.get_minion_from_id(defenderId);
                    var pos = battleMap.hex_to_pos(defender.hex);
                    var radius = (mouse_hex.key == defender.hex.key ? 20 : 10);
                    Luxe.draw.circle({ x: pos.x, y: pos.y, r: radius, immediate: true, depth: 15, color: new Color(1, 0, 0) });
            }
        }
    }

    function select_action(action :core.Models.MinionAction) {
        battleModel.do_action(MinionAction(model.id, action));
        if (model.actions <= 0) {
            Main.states.disable(StateId);
            Main.states.enable(HandState.StateId);
        }
    }

    override public function onmouseup(event :luxe.Input.MouseEvent) {
        if (!has_data) return;
        var pos = Luxe.camera.screen_point_to_world(event.pos);
        var mouse_hex = battleMap.pos_to_hex(pos);
        for (action in battleModel.get_minion_actions(model.id)) {
            switch (action) {
                case Nothing:
                case Move(hex):
                    if (mouse_hex.key == hex.key) {
                        select_action(Move(hex));
                        return;
                    }
                case Attack(defenderId):
                    var defender = battleModel.get_minion_from_id(defenderId);
                    if (mouse_hex.key == defender.hex.key) {
                        select_action(Attack(defenderId));
                        return;
                    }
            }
        }
    }

    override public function onkeyup(event :luxe.Input.KeyEvent) {
        function random_int(v :Int) {
            return battleModel.get_random().int(v);
        }
        if (event.keycode == luxe.Input.Key.key_m) {
            var moves = battleModel.get_minion_moves(model.id);
            if (moves.length == 0) return;
            var randomMove = moves.random(random_int);
            select_action(randomMove);
        } else if (event.keycode == luxe.Input.Key.key_a) {
            var attacks = battleModel.get_minion_attacks(model.id);
            if (attacks.length == 0) return;
            var randomAttack = attacks.random(random_int);
            select_action(randomAttack);
        } else if (event.keycode == luxe.Input.Key.key_p) {
            var enemyMinions = battleModel.get_minions().filter(function(m) { return m.playerId != model.playerId; });
            if (enemyMinions.length == 0) return;
            var randomEnemy = enemyMinions.random(random_int);
            var path = model.hex.find_path(randomEnemy.hex, 100, 6, battleModel.is_walkable, true);
            for (p in path) select_action(Move(p));
        }
    }
}
