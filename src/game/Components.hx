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
