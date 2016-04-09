
package game.states;

import luxe.Input.MouseEvent;
import luxe.States.State;
import luxe.Vector;
import luxe.tween.Actuate;
import game.Entities.CardEntity;
import game.Components.PopIn;
import core.Models.BattleModel;
import phoenix.Batcher;
import luxe.Scene;
import luxe.Color;
import snow.api.Promise;
import core.MapFactory;
import game.Entities.HexTile;
import game.Entities.HexGrid;
import game.Components;
import core.HexLibrary.Hex;
import core.HexLibrary.Layout;

using Lambda;

class WorldState extends State {
    static public var StateId :String = 'WorldState';
    var hexGrid :HexGrid;
    var pos :Vector;
    var move_to :Vector;

    public function new() {
        super({ name: StateId });

        pos = Luxe.screen.mid.clone();
        move_to = pos.clone();
    }

    override function onenter(_) {
        Luxe.camera.zoom = 10;
        luxe.tween.Actuate.tween(Luxe.camera, 1.0, { zoom: 1 });

        hexGrid = new HexGrid(25, 0);
        var hexes = MapFactory.create_rectangular_map(20, 20);
        hexes.map(add_hex);
        pos = Luxe.screen.mid.clone();
        move_to = pos.clone();
    }

    override function onleave(_) {
        Luxe.scene.empty();
    }

    function add_hex(hex :Hex) :Promise {
        var pos = Layout.hexToPixel(hexGrid.layout, hex);
        var tile = new HexTile({
            pos: new Vector(pos.x, pos.y),
            r: hexGrid.hexSize
        });
        var popIn = new FastPopIn();
        tile.add(popIn);
        // hexGrid[hex.key] = tile;
        return popIn.promise;
    }

    override function onmouseup(event :MouseEvent) {
        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);
        move_to = world_pos;
        trace('move_to: $move_to');
    }

    override function update(dt :Float) {
        if (pos == null || move_to == null) return;

        var diff = Vector.Subtract(move_to, pos);
        if (diff.length > 10) {
            diff.normalize();
            pos = Vector.Add(pos, Vector.Multiply(diff, dt * 200));
            // Luxe.camera.focus(pos, 0);
            // transform.pos.set_xy(view.pos.x, view.pos.y)
            Luxe.camera.center = pos;
        }

        Luxe.draw.circle({ // TODO: Replace pos with Sprite/Visual
            x: pos.x,
            y: pos.y,
            r: 30,
            immediate: true,
            depth: 5
        });
    }
}
