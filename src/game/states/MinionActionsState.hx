
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

import core.Enums;
import core.models.Battle;
import core.models.Minion;
import core.PromiseQueue;
import game.Entities.CardEntity;
import game.Entities.MinionEntity;
import game.Entities.HexTile;
import game.Entities.HexGrid;
import game.components.PopIn;

using Lambda;
using core.HexLibrary.HexTools;
using core.tools.ArrayTools;

class MinionActionsState extends State {
    static public var StateId :String = 'MinionActionsState';
    var battle :Battle;
    var hexGrid :HexGrid;
    var model :Minion;
    var has_data :Bool;

    public function new() {
        super({ name: StateId });
        has_data = false;
    }

    override function onenabled<T>(value :T) {
        var data :{ model :Minion, battle :Battle, hexGrid :HexGrid } = cast value;
        model = data.model;
        battle = data.battle;
        hexGrid = data.hexGrid;
        has_data = true;
        if (model.actions <= 0) {
            Main.states.disable(StateId);
            Main.states.enable(HandState.StateId);
        }
    }

    override public function onrender() {
        if (!has_data) return;
        var pos = Luxe.camera.screen_point_to_world(Luxe.screen.cursor.pos);
        var mouse_hex = hexGrid.pos_to_hex(pos);
        for (action in battle.get_minion_actions(model.id)) {
            switch (action) {
                case Nothing:
                case Move(hex):
                    var pos = hexGrid.hex_to_pos(hex);
                    var radius = (mouse_hex.key == hex.key ? 30 : 25);
                    Luxe.draw.circle({ x: pos.x, y: pos.y, color: new Color(1, 1, 1, 0.3), r: radius, immediate: true, depth: 15 });
                case Attack(defenderId):
                    var defender = battle.get_minion_from_id(defenderId);
                    var pos = hexGrid.hex_to_pos(defender.hex);
                    var radius = (mouse_hex.key == defender.hex.key ? 30 : 25);
                    Luxe.draw.circle({ x: pos.x, y: pos.y, color: new Color(1, 0, 0, 0.3), r: radius, immediate: true, depth: 15 });
            }
        }
    }

    function select_action(action :core.Enums.MinionAction) {
        battle.do_action(MinionAction(model.id, action));
        // if (model.actions <= 0) {
            Main.states.disable(StateId);
            Main.states.enable(HandState.StateId);
        // }
    }

    override public function onmouseup(event :luxe.Input.MouseEvent) {
        if (!has_data) return;
        var pos = Luxe.camera.screen_point_to_world(event.pos);
        var mouse_hex = hexGrid.pos_to_hex(pos);
        for (action in battle.get_minion_actions(model.id)) {
            switch (action) {
                case Nothing:
                case Move(hex):
                    if (mouse_hex.key == hex.key) {
                        select_action(Move(hex));
                        return;
                    }
                case Attack(defenderId):
                    var defender = battle.get_minion_from_id(defenderId);
                    if (mouse_hex.key == defender.hex.key) {
                        select_action(Attack(defenderId));
                        return;
                    }
            }
        }
        Main.states.disable(StateId);
        Main.states.enable(HandState.StateId);
    }
}
