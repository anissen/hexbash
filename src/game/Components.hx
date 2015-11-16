package game;

import luxe.Component;
import luxe.Input.MouseEvent;
import luxe.Vector;
import luxe.Color;
import luxe.Rectangle;

import game.Entities.Card;
import game.Entities.Minion;

class PopIn extends Component {
    override function onadded() {
        luxe.tween.Actuate.tween(entity.scale, 0.3, { x: 0.0, y: 0.0 }).reverse();
    }
}

class Selectable extends Component {
    var func :Minion->Void;
    var minion :Minion;
    var is_mouse_over :Bool = false;

    public function new(f :Minion->Void) {
        super({ name: 'Selectable' });
        func = f;
    }

    override function init() {
        minion = cast entity;
    }

    function is_mouse_over_minion(pos) {
        var r = Luxe.camera.view.screen_point_to_ray(pos);
        var result = Luxe.utils.geometry.intersect_ray_plane(r.origin, r.dir, new Vector(0, 0, 1), new Vector());
        return (Luxe.utils.geometry.point_in_geometry(result, minion.geometry));
    }

    override function onmousemove(event :MouseEvent) {
        is_mouse_over = is_mouse_over_minion(event.pos);
    }

    override function onmousedown(event :MouseEvent) {
        if (is_mouse_over_minion(event.pos)) func(minion);
    }

    override function update(dt :Float) {
        if (is_mouse_over) Luxe.draw.circle({ x: entity.pos.x, y: entity.pos.y, r: 42, color: new Color(1, 0.8, 0.8), depth: 1, immediate: true });
    }
}

class Selected extends Component {
    override function update(dt :Float) {
        Luxe.draw.circle({ x: entity.pos.x, y: entity.pos.y, r: 45, depth: 1, immediate: true });
    }
}

class SelectableCard extends Component {
    var func :Card->Void;
    var card :Card;
    var is_mouse_over :Bool = false;

    public function new(f :Card->Void) {
        super({ name: 'SelectableCard' });
        func = f;
    }

    override function init() {
        card = cast entity;
    }

    function is_mouse_over_card(pos) {
        var r = Luxe.camera.view.screen_point_to_ray(pos);
        var result = Luxe.utils.geometry.intersect_ray_plane(r.origin, r.dir, new Vector(0, 0, 1), new Vector());
        return (Luxe.utils.geometry.point_in_geometry(result, card.geometry));
    }

    override function onmousemove(event :MouseEvent) {
        is_mouse_over = is_mouse_over_card(event.pos);
    }

    override function onmouseup(event :MouseEvent) {
        if (is_mouse_over_card(event.pos)) func(card);
    }

    override function update(dt :Float) {
        if (is_mouse_over) Luxe.draw.box({ rect: new Rectangle(entity.pos.x - 5, entity.pos.y - 5, 110, 160), color: new Color(1, 0.8, 0.8), depth: 1, immediate: true });
    }
}

class SelectedCard extends Component {
    override function update(dt :Float) {
        Luxe.draw.box({ rect: new Rectangle(entity.pos.x - 10, entity.pos.y - 10, 120, 170), depth: 1, immediate: true });
    }
}
