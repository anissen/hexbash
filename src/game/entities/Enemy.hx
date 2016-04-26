
package game.entities;

import luxe.Vector;
import luxe.Sprite;
import luxe.Color;
import game.components.MoveTo;

enum EnemyType {
    Spider;
    Orc;
}

typedef EnemyOptions = {
    > luxe.options.SpriteOptions,
    type: EnemyType
}

class Enemy extends Sprite {
    var type :EnemyType;

    public function new(options :EnemyOptions) {
        type = options.type;
        super({
            pos: options.pos,
            texture: get_texture(),
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
    }

    function get_texture() {
        var icon = switch (type) {
            case Spider: 'spider-alt';
            case Orc: 'orc-head';
        };
        return Luxe.resources.texture('assets/images/icons/$icon.png');
    }

    function get_speed() {
        return switch (type) {
            case Spider: 1;
            case Orc: 0.25;
        };
    }

    public function get_idleness() {
        return switch (type) {
            case Spider: 0.25;
            case Orc: 0.75;
        };
    }

    public function get_chase_tiles() {
        return switch (type) {
            case Spider: 3;
            case Orc: 0;
        };
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
