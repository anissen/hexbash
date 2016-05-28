package game;

import core.HexLibrary;
import luxe.Input.MouseEvent;
import luxe.options.VisualOptions;
import luxe.options.SpriteOptions;
import luxe.Scene;
import luxe.Vector;
import luxe.Visual;
import luxe.Sprite;
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
        if (options.color == null) options.color = new Color(26/255, 43/255, 65/255);
        if (options.geometry == null) options.geometry = Luxe.draw.ngon({ sides: 6, r: options.r, angle: 30, solid: true });
        super(options);

        var rand = -0.05 + 0.1 * Math.random();
        foreground = new Visual({
            color: new Color(52/255 + rand, 73/255 + rand, 103/255 + rand),
            geometry: Luxe.draw.ngon({ sides: 6, r: options.r - 5, angle: 30, solid: true }),
            parent: this
        });
    }
}

class HexSpriteTile extends Sprite {
    public function new(options :SpriteOptions) {
        // if (options.texture == null) options.texture = Luxe.resources.texture('assets/images/tiles/tileGrass_tile.png');
        super(options);
    }
}

class HexGrid extends luxe.Entity {
    static public var HEX_CLICKED_EVENT :String = 'hex_clicked';
    static public var HEX_MOUSEMOVED_EVENT :String = 'hex_mousemoved';
    var layout :Layout;

    public var hexSize :Int;
    var margin :Int;

    public function new(hexSize :Int = 60, marginX :Int = 5, marginY :Int = 5) {
        super({ name: 'HexGrid' });
        this.hexSize = hexSize;
        var size = new Point(hexSize + marginX, hexSize + marginY);
        var origin = new Point(Luxe.screen.mid.x, Luxe.screen.mid.y);
        layout = new Layout(Layout.pointy, size, origin);
    }

    override function init() {

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
        return /* get_world_pos( */ new Vector(point.x, point.y);
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
    > SpriteOptions,
    model :MinionModel
};
class MinionEntity extends Sprite {
    var power :Int;
    var powerText :luxe.Text;

    public function new(options :MinionOptions) {
        var _options = options;
        power = _options.model.power;

        if (_options.color == null) _options.color = new Color(0, 0.5, 0.5);
        if (_options.texture == null) _options.texture = Luxe.resources.texture('assets/images/icons/${options.model.icon}');
        if (_options.size == null) _options.size = new Vector(40, 40);
        //if (_options.geometry == null) _options.geometry = Luxe.draw.circle({ r: 24 });
        super(_options);

        var bg_color = _options.color.toColorHSL();
        bg_color.h = (bg_color.h + 160) % 360;
        new Sprite({
            pos: Vector.Divide(size, 2),
            size: new Vector(size.x + 10, size.y + 10),
            parent: this,
            depth: _options.depth - 0.01,
            texture: Luxe.resources.texture('assets/images/icons/background.png'),
            color: bg_color.clone()
        });

        var icon_displacement = 6;
        bg_color.h = (bg_color.h + 40) % 360;

        new Sprite({
            pos: new Vector(size.x / 2, size.y + icon_displacement),
            size: Vector.Multiply(size, 0.65),
            parent: this,
            depth: _options.depth + 0.01,
            texture: Luxe.resources.texture('assets/images/icons/background.png'),
            color: bg_color
        });

        powerText = new luxe.Text({
            pos: new Vector(size.x / 2, size.y + icon_displacement),
            point_size: 24,
            align: luxe.Text.TextAlign.center,
            align_vertical: luxe.Text.TextAlign.center,
            parent: this,
            depth: _options.depth + 0.02
        });

        update_text();

        // var effect = (Math.random() < 0.5);
        // if (effect) {
        //     new Sprite({
        //         pos: new Vector(size.x / 2, -icon_displacement),
        //         size: new Vector(15, 15),
        //         parent: this,
        //         depth: _options.depth + 0.01,
        //         texture: Luxe.resources.texture('assets/images/icons/background.png'),
        //         color: bg_color
        //     });
        //     new Sprite({
        //         pos: new Vector(size.x / 2, -icon_displacement),
        //         size: new Vector(15, 15),
        //         parent: this,
        //         depth: _options.depth + 0.02,
        //         texture: Luxe.resources.texture('assets/images/icons/spider-alt.png'),
        //         color: new Color(1, 1, 0)
        //     });
        // }
    }

    public function damage(amount :Int) {
        power -= amount;
        update_text();
    }

    public function heal(amount :Int) {
        power += amount;
        update_text();
    }

    function update_text() {
        powerText.text = '' + power;
    }
}

class HeroEntity extends MinionEntity {
    var max_power :Int;

    public function new(options :MinionOptions) {
        var _options = options;

        max_power = _options.model.power;

        // if (_options.geometry == null) _options.geometry = Luxe.draw.circle({ r: 28 });
        if (_options.size == null) _options.size = new Vector(45, 45);
        super(_options);
    }

    override public function heal(amount :Int) {
        power += amount;
        if (power > max_power) power = max_power;
        update_text();
    }

    override function update_text() {
        powerText.text = '$power';
    }
}

class TowerEntity extends MinionEntity {
    public function new(options :MinionOptions) {
        var _options = options;

        if (_options.geometry == null) _options.geometry = Luxe.draw.box({ x: -30, y: -30, w: 60, h: 60 });
        super(_options);
    }
}

typedef CardOptions = {
    > luxe.options.SpriteOptions,
    text :String,
    ?cost :Int
}

class CardEntity extends luxe.Sprite {
    var text :luxe.Text;
    static var Count :Int = 0;

    public function new(options :CardOptions) {
        var _options = options;
        if (_options.name == null) _options.name = 'card.' + Luxe.utils.uniqueid();
        if (_options.color == null) _options.color = new Color(0, 0.5, 0.5);
        if (_options.geometry == null) _options.geometry = Luxe.draw.box({
            rect: new luxe.Rectangle(0, 0, 100, 150),
            batcher: _options.batcher
        });
        super(_options);

        text = new luxe.Text({
            text: _options.text + (_options.cost != null ? '\n\n(${_options.cost})' : ''),
            pos: new Vector(50, 15),
            point_size: 18,
            align: luxe.Text.TextAlign.center,
            align_vertical: luxe.Text.TextAlign.top,
            parent: this,
            batcher: _options.batcher,
            scene: _options.scene,
            depth: _options.depth + 0.01
        });
    }
}

class DeckEntity extends luxe.Sprite {
    var text :luxe.Text;

    public function new(options :SpriteOptions) {
        var _options = options;
        if (_options.name == null) _options.name = 'deck';
        if (_options.color == null) _options.color = new Color(0.1, 0.1, 0.1);
        if (_options.geometry == null) _options.geometry = Luxe.draw.box({
            rect: new luxe.Rectangle(0, 0, 100, 150),
            batcher: _options.batcher
        });
        super(_options);

        text = new luxe.Text({
            text: '',
            pos: new Vector(50, 15),
            point_size: 18,
            align: luxe.Text.TextAlign.center,
            align_vertical: luxe.Text.TextAlign.top,
            parent: this,
            batcher: _options.batcher,
            scene: _options.scene,
            depth: _options.depth + 0.01
        });
    }

    public function set_text(t :String) {
        text.text = t;
    }
}
