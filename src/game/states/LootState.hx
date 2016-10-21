
package game.states;

import luxe.Input.MouseEvent;
import luxe.States.State;
import luxe.Scene;
import luxe.Color;
import luxe.tween.Actuate;
import phoenix.Batcher;

class LootState extends State {
    static public var StateId :String = 'LootState';
    var scene :luxe.Scene;
    var batcher :Batcher;

    public function new() {
        super({ name: StateId });
        scene = new luxe.Scene();
        batcher = Luxe.renderer.create_batcher({ name: 'gui', layer: 5 });
    }

    override function onenabled<T>(value :T) {
        var data :{ cards :Array<core.models.Card>, callback :Int->Void } = cast value;
        var cards = data.cards;
        var callback = data.callback;

        var cardWidth = 130;
        var startX = (Luxe.screen.width / 2) - ((cards.length + 1 /* deck */) / 2) * cardWidth;
        var i = cards.length;
        for (card in cards) {
            var cardEntity = new game.Entities.CardEntity({
                centered: true,
                card: card,
                // pos: new luxe.Vector(Luxe.screen.mid.x, Luxe.screen.mid.y - cardEntity.size.y / 2),
                // color: color,
                batcher: batcher,
                depth: 1000,
                scene: scene
            });
            cardEntity.pos = new luxe.Vector(Luxe.screen.mid.x, Luxe.screen.mid.y - cardEntity.size.y / 2);

            Actuate.tween(cardEntity.pos, 1.5, {
                x: startX + (i--) * cardWidth,
                y: Luxe.screen.mid.y - cardEntity.size.y / 2
            });
            Actuate.tween(cardEntity, 1.5, {
                rotation_z: Math.random()
            });
        }
    }

    override function ondisabled<T>(value :T) {
        scene.empty();
    }
}
