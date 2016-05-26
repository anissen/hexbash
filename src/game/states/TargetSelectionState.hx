
package game.states;

import luxe.Input.MouseEvent;
import luxe.States.State;
import luxe.Color;
import snow.api.Promise;
import game.Entities.HexGrid;
import core.HexLibrary.Hex;

class TargetSelectionState extends State {
    static public var StateId :String = 'TargetSelectionState';
    var hexes :Array<Hex>;
    static public var hexGrid :HexGrid;
    // var has_data :Bool;
    static var promise_func :Hex->Void;

    public function new() {
        super({ name: StateId });
        // has_data = false;
    }

    static public function Target(hexes :Array<Hex>) :Promise {
        Main.states.enable(StateId, hexes);
        return new Promise(function(resolve, reject) {
            promise_func = resolve;
        });
    }

    override function onenabled<T>(value :T) {
        hexes = cast value;
        // has_data = true;
    }

    override public function onrender() {
        // if (!has_data) return;
        var pos = Luxe.camera.screen_point_to_world(Luxe.screen.cursor.pos);
        var mouse_hex = hexGrid.pos_to_hex(pos);

        for (hex in hexes) {
            var pos = hexGrid.hex_to_pos(hex);
            var radius = (mouse_hex.key == hex.key ? 20 : 10);
            Luxe.draw.circle({ x: pos.x, y: pos.y, color: new Color(1, 0, 1, 0.8), r: radius, immediate: true, depth: 15 });
        }
    }

    function select_target(hex :Hex) {
        promise_func(hex);
        // has_data = false;
        Main.states.disable(StateId);
    }

    override public function onmouseup(event :luxe.Input.MouseEvent) {
        // if (!has_data) return;
        var pos = Luxe.camera.screen_point_to_world(event.pos);
        var mouse_hex = hexGrid.pos_to_hex(pos);
        for (hex in hexes) {
            if (hex.key == mouse_hex.key) {
                select_target(hex);
                return;
            }
        }
    }
}
