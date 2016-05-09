package game.components;

import luxe.Component;
import luxe.Vector;

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
        var diff_length = diff.length;
        if (diff_length > 2) {
            diff.normalize();
            pos = Vector.Add(pos, Vector.Multiply(diff, Math.min(dt * 200 * speed, diff_length)));
        } else {
            entity.remove('MoveTo');
            if (onCompleted != null) onCompleted();
        }
    }
}
