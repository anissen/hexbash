
package game.states;

import luxe.Input.MouseEvent;
import luxe.States.State;
import luxe.Vector;
import luxe.tween.Actuate;
import game.Entities.CardEntity;
import game.components.PopIn;
import core.Models.BattleModel;
import phoenix.Batcher;
import luxe.Scene;
import luxe.Color;

import snow.api.Promise;

class HandState extends State {
    static public var StateId :String = 'HandState';
    var cardMap :Map<Int, CardEntity>;
    var battleModel :BattleModel;
    var batcher :Batcher;
    var scene :Scene;
    var grabbedCardEntity :CardEntity;
    var card_y :Float;

    public function new(battleModel :BattleModel, batcher :Batcher, scene :Scene) {
        super({ name: StateId });
        this.battleModel = battleModel;
        this.batcher = batcher;
        this.scene = scene;
        card_y = Luxe.screen.height - 100;
        reset();
    }

    override function onenabled<T>(value :T) {
        card_y = Luxe.screen.height - 100;
        for (cardId in cardMap.keys()) {
            var cardEntity = cardMap[cardId];
            luxe.tween.Actuate.tween(cardEntity.pos, 0.4, { y: card_y });
        }
    }

    override function ondisabled<T>(value :T) {
        card_y = Luxe.screen.height;
        for (cardId in cardMap.keys()) {
            var cardEntity = cardMap[cardId];
            luxe.tween.Actuate.tween(cardEntity.pos, 0.4, { y: card_y });
        }
    }

    function card_from_model(cardId :Int) {
        return cardMap.get(cardId);
    }

    public function draw_card(cardId :Int) :Promise {
        var card = battleModel.get_card_from_id(cardId);
        var cost = battleModel.get_card_cost(cardId);
        var color = switch (card.cardType) {
            case Minion(_, _): new Color(0.2, 0.5, 0.5);
            case Tower(_, _): new Color(0.2, 0.3, 0.8);
            case Potion(_): new Color(0.2, 0.8, 0.3);
            case Spell(_): new Color(0.8, 0.2, 0.3);
            case Attack(_): new Color(1.0, 0.1, 0.2);
        };
        var cardEntity = new CardEntity({
            centered: true,
            text: card.title,
            cost: cost,
            pos: new Vector(Luxe.screen.width - 100, Luxe.screen.height - 100),
            color: color,
            batcher: batcher,
            depth: 3,
            scene: scene
        });
        cardMap.set(card.id, cardEntity);

        position_cards();

        var popIn = new PopIn();
        cardEntity.add(popIn);
        return popIn.promise;
    }

    function position_cards() {
        var i = 0;
        for (c in cardMap) {
            luxe.tween.Actuate.tween(c.pos, 0.3, {
                x: Luxe.screen.width / 2 + 120 - 120 * (i++),
                y: card_y
            });
            luxe.tween.Actuate.tween(c, 0.3, {
                rotation_z: 0
            });
        }
    }

    public function play_card(cardId :Int) :Promise {
        var cardEntity = card_from_model(cardId);
        cardMap.remove(cardId);
        cardEntity.destroy();
        return Promise.resolve();
    }

    public function discard_card(cardId :Int) :Promise {
        var cardEntity = card_from_model(cardId);
        cardMap.remove(cardId);
        cardEntity.destroy();
        return Promise.resolve();
    }

    public function reset() {
        cardMap = new Map();
    }

    override public function onmousemove(event :luxe.Input.MouseEvent) {
        if (!enabled) return;

        if (grabbedCardEntity != null) {
            grabbedCardEntity.rotation_z = luxe.utils.Maths.clamp(grabbedCardEntity.rotation_z + event.x_rel / 50, -5, 5);
            grabbedCardEntity.color.a = 0.25; // Remove everything but the icon instead
            grabbedCardEntity.pos = Vector.Subtract(Luxe.screen.cursor.pos, grabbedCardEntity.size);
            return;
        }

        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);

        /* HACK */
        for (cardId in cardMap.keys()) {
            var cardEntity = cardMap[cardId];
            cardEntity.color.r = 0.2;
            if (Luxe.utils.geometry.point_in_geometry(screen_pos, cardEntity.geometry)) {
                var can_play = battleModel.can_play_card(cardId);
                cardEntity.color.r = (can_play ? 0.8 : 0.2);
            }
        }
    }

    // function get_target(cardId :Int) :Promise {
    //     var cardModel = battleModel.get_card_from_id(cardId);
    //     switch (cardModel.cardType) {
    //         case Attack(_): return TargetSelectionState.Target([new core.HexLibrary.Hex(0,0), new core.HexLibrary.Hex(0,1), new core.HexLibrary.Hex(1,1)]); //Promise.resolve(new core.HexLibrary.Hex(0, 0)); // Select target
    //         default: return Promise.resolve();
    //     }
    // }

    override public function onmousedown(event :luxe.Input.MouseEvent) {
        if (!enabled) return;

        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);

        /* HACK */
        for (cardId in cardMap.keys()) {
            var cardEntity = cardMap[cardId];
            if (Luxe.utils.geometry.point_in_geometry(screen_pos, cardEntity.geometry)) {
                if (event.button == luxe.Input.MouseButton.left) {
                    if (battleModel.can_play_card(cardId)) {
                        grabbed_card(cardEntity);
                    }
                }
                break;
            }
        }
    }

    function grabbed_card(cardEntity :CardEntity) {
        grabbedCardEntity = cardEntity;
    }

    override public function onmouseup(event :luxe.Input.MouseEvent) {
        if (!enabled) return;

        if (grabbedCardEntity != null) {
            grabbedCardEntity.color.a = 1;
            grabbedCardEntity = null;
            position_cards();
        }
    }

    // override public function onmouseup(event :luxe.Input.MouseEvent) {
    //     if (!enabled) return;
    //
    //     var screen_pos = event.pos;
    //     var world_pos = Luxe.camera.screen_point_to_world(event.pos);
    //
    //     /* HACK */
    //     for (cardId in cardMap.keys()) {
    //         var cardEntity = cardMap[cardId];
    //         if (Luxe.utils.geometry.point_in_geometry(screen_pos, cardEntity.geometry)) {
    //             if (event.button == luxe.Input.MouseButton.left) {
    //                 if (battleModel.can_play_card(cardId)) {
    //                     trace('Select target');
    //                     get_target(cardId)
    //                         .then(function(?target :core.HexLibrary.Hex) {
    //                             trace('Got target: $target');
    //                             battleModel.do_action(PlayCard(cardId, target));
    //                         })
    //                         .error(function() {
    //                             trace('Error getting target');
    //                         });
    //                 }
    //             } else if (event.button == luxe.Input.MouseButton.right) {
    //                 battleModel.do_action(DiscardCard(cardId));
    //             }
    //             break;
    //         }
    //     }
    // }
}
