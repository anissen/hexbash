package game;

import core.HexLibrary;
import luxe.Input.MouseEvent;
import luxe.options.VisualOptions;
import luxe.Scene;
import luxe.Vector;
import luxe.Visual;
import luxe.Color;

import core.Models.MinionModel;

using core.HexLibrary.HexTools;

typedef HexTileOptions = {
    > VisualOptions,
    r :Float
}

class HexTile extends Visual {
    public var foreground :Visual;

    public function new(options :HexTileOptions) {
        super({
            pos: options.pos,
            color: new Color(26/255, 43/255, 65/255),
            geometry: Luxe.draw.ngon({ sides: 6, r: options.r, angle: 30, solid: true })
        });

        foreground = new Visual({
            color: new Color(52/255, 73/255, 103/255),
            geometry: Luxe.draw.ngon({ sides: 6, r: options.r - 5, angle: 30, solid: true }),
            parent: this
        });
    }
}

class BattleMap extends luxe.Entity {
    static public var HEX_CLICKED_EVENT :String = 'hex_clicked';
    static public var HEX_MOUSEMOVED_EVENT :String = 'hex_mousemoved';
    public var layout :Layout;

    public var hexSize :Int = 60;
    var margin  :Int = 5;

    public function new() {
        super({ name: 'BattleMap' });
    }

    override function init() {
        var size = new Point(hexSize + margin, hexSize + margin);
        var origin = new Point(Luxe.screen.mid.x, Luxe.screen.mid.y);
        layout = new Layout(Layout.pointy, size, origin);
    }

    public function get_world_pos(pos :Vector) :Vector {
        var r = Luxe.camera.view.screen_point_to_ray(pos);
        var result = Luxe.utils.geometry.intersect_ray_plane(r.origin, r.dir, new Vector(0, 0, 1), new Vector());
        result.z = 0;
        return result;
    }

    public function pos_to_hex(world_pos :Vector) :Hex {
        var fractionalHex = Layout.pixelToHex(layout, new Point(world_pos.x, world_pos.y));
        return FractionalHex.hexRound(fractionalHex);
    }

    public function hex_to_pos(hex :Hex) :Vector {
        var point = Layout.hexToPixel(layout, hex);
        return get_world_pos(new Vector(point.x, point.y));
    }

    override function onmousemove(event :MouseEvent) {
        var world_pos = get_world_pos(event.pos);
        var hex = pos_to_hex(world_pos);
        events.fire(HEX_MOUSEMOVED_EVENT, hex);
    }

    override function onmouseup(event :MouseEvent) {
        var world_pos = get_world_pos(event.pos);
        var hex = pos_to_hex(world_pos);
        events.fire(HEX_CLICKED_EVENT, hex);
    }
}

typedef MinionOptions = {
    > VisualOptions,
    model :MinionModel
};
class Minion extends Visual {
    //public var model :MinionModel;
    var power :Int;
    var powerText :luxe.Text;

    public function new(options :MinionOptions) {
        var _options = options;
        if (_options.color == null) _options.color = new Color(0, 0.5, 0.5);
        if (_options.geometry == null) _options.geometry = Luxe.draw.circle({ r: 30 });
        super(_options);

        //model = _options.model;
        power = _options.model.power;

        powerText = new luxe.Text({
            text: '' + power,
            align: luxe.Text.TextAlign.center,
            align_vertical: luxe.Text.TextAlign.center,
            parent: this,
            depth: _options.depth + 0.01
        });
    }

    public function damage(damage :Int) {
        power -= damage;
        powerText.text = '' + power;
    }
}

class Hero extends Minion {
    public function new(options :MinionOptions) {
        var _options = options;
        if (_options.geometry == null) _options.geometry = Luxe.draw.circle({ r: 45 });
        super(_options);
    }
}

typedef CardOptions = {
    > luxe.options.SpriteOptions,
    effect: Hex->Void
}

class Card extends luxe.Sprite {
    var _options :CardOptions;

    public function new(options :CardOptions) {
        _options = options;
        if (_options.color == null) _options.color = new Color(0, 0.5, 0.5);
        if (_options.geometry == null) _options.geometry = Luxe.draw.box({
            rect: new luxe.Rectangle(0, 0, 100, 150)
        });
        super(_options);
    }

    public function trigger(hex :Hex) {
        _options.effect(hex);
    }
}
