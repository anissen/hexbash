package game;

import luxe.Component;
import luxe.Input.MouseEvent;
import luxe.tween.Actuate;
import luxe.Vector;
import luxe.Color;
import luxe.Rectangle;

import game.Entities.CardEntity;
import game.Entities.MinionEntity;

class PopIn extends Component {
    public var promise :snow.api.Promise;
    var animation_done :Void->Void;
    var duration :Float;

    public function new(duration :Float = 0.3) {
        super({ name: 'PopIn' });
        this.duration = duration;
        promise = new snow.api.Promise(function(resolve, reject) {
            animation_done = resolve;
        });
    }

    function done() {
        animation_done();
    }

    override function onadded() {
        var scale = entity.scale.clone();
        entity.scale.set_xy(0.0, 0.0);
        Actuate.tween(entity.scale, duration, { x: scale.x, y: scale.y }).onComplete(done);
    }
}

class FastPopIn extends PopIn {
    public function new() {
        super(0.02);
    }
}

class MoveTo extends Component {
    var move_to :luxe.Vector;
    var speed :Float;
    public var onCompleted :Void->Void;

    public function new(move_to :Vector, speed :Float = 1) {
        super({ name: 'MoveTo' });
        this.move_to = move_to;
        this.speed = speed;
    }

    override function update(dt :Float) {
        var diff = Vector.Subtract(move_to, pos);
        if (diff.length > 2) {
            diff.normalize();
            pos = Vector.Add(pos, Vector.Multiply(diff, dt * 200 * speed));
        } else {
            entity.remove('MoveTo');
            if (onCompleted != null) onCompleted();
        }
    }
}
