
package game.entities;

import luxe.Vector;
import luxe.Sprite;
import luxe.Color;
import game.components.MoveTo;

typedef EnemyOptions = {
    > luxe.options.SpriteOptions,
    icon :String,
    ?speed :Float,
    ?idle :Float,
    ?chase_tiles :Int
}

class Enemy extends Sprite {
    var speed :Float;
    var idle :Float;
    var chase_tiles :Int;

    public function new(options :EnemyOptions) {
        super({
            pos: options.pos,
            texture: Luxe.resources.texture('assets/images/icons/${options.icon}'),
            color: new Color(0, 0, 0), // new ColorHSL(360 * Math.random(), 0.8, 0.8),
            scale: new Vector(0.08, 0.08),
            depth: 99
        });
        new Sprite({
            pos: new Vector(256, 256),
            centered: true,
            texture: Luxe.resources.texture('assets/images/icons/shadow.png'),
            color: new Color(1, 1, 1, 0.2),
            scale: new Vector(1.4, 1.4),
            depth: 98,
            parent: this
        });
        speed = (options.speed != null ? options.speed : 1);
        idle = (options.idle != null ? options.idle : 0.5);
        chase_tiles = (options.chase_tiles != null ? options.chase_tiles : 1);
    }

    function get_speed() {
        return speed;
    }

    public function get_idleness() {
        return idle;
    }

    public function get_chase_tiles() {
        return chase_tiles;
    }

    public function is_idle() {
        return (get_idleness() > Math.random());
    }

    public function is_moving() {
        return has('MoveTo');
    }

    public function move_to(pos :Vector) :Null<MoveTo> {
        var move_to = new MoveTo(pos, get_speed());
        add(move_to);
        return move_to;
    }
}
