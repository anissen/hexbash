
package game.states;

import luxe.Input.MouseEvent;
import luxe.States.State;
import luxe.Vector;
import luxe.tween.Actuate;
import game.Entities.CardEntity;
import game.Components.PopIn;
import core.Models.BattleModel;
import phoenix.Batcher;
import luxe.Scene;

import snow.api.Promise;

class HandState extends State {
    static public var StateId :String = 'HandState';
    var cardMap :Map<Int, CardEntity>;
    var battleModel :BattleModel;
    var batcher :Batcher;
    var scene :Scene;

    public function new(battleModel :BattleModel, batcher :Batcher, scene :Scene) {
        super({ name: StateId });
        cardMap = new Map();
        this.battleModel = battleModel;
        this.batcher = batcher;
        this.scene = scene;
    }

    override function onenabled<T>(value :T) {
        for (cardId in cardMap.keys()) {
            var cardEntity = cardMap[cardId];
            luxe.tween.Actuate.tween(cardEntity.pos, 0.4, { y: Luxe.screen.height - 100 });
        }
    }

    override function ondisabled<T>(value :T) {
        for (cardId in cardMap.keys()) {
            var cardEntity = cardMap[cardId];
            luxe.tween.Actuate.tween(cardEntity.pos, 0.4, { y: Luxe.screen.height });
        }
    }

    function card_from_model(cardId :Int) {
        return cardMap.get(cardId);
    }

    public function draw_card(cardId :Int) :Promise {
        var card = battleModel.get_card_from_id(cardId);
        var cost = switch (card.cardType) {
            case Minion(_, cost): cost;
            case Potion(power): power;
            case Spell(_, cost): cost;
        };
        var cardEntity = new CardEntity({
            text: card.title,
            cost: cost,
            pos: new Vector(Luxe.screen.width - 100, Luxe.screen.height - 100),
            batcher: batcher,
            depth: 3,
            scene: scene
        });
        cardMap.set(card.id, cardEntity);
        var i = 0;
        for (c in cardMap) {
            luxe.tween.Actuate.tween(c.pos, 0.3, { x: Luxe.screen.width / 2 + 120 - 120 * (i++) });
        }
        var popIn = new PopIn();
        cardEntity.add(popIn);
        return popIn.promise;
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

    override public function onmousemove(event :luxe.Input.MouseEvent) {
        if (!enabled) return;

        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);

        /* HACK */
        for (cardId in cardMap.keys()) {
            var cardEntity = cardMap[cardId];
            cardEntity.color.r = 0.2;
            if (Luxe.utils.geometry.point_in_geometry(screen_pos, cardEntity.geometry)) {
                cardEntity.color.r = 0.8;
            }
        }
    }

    override public function onmouseup(event :luxe.Input.MouseEvent) {
        if (!enabled) return;

        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);

        /* HACK */
        for (cardId in cardMap.keys()) {
            var cardEntity = cardMap[cardId];
            if (Luxe.utils.geometry.point_in_geometry(screen_pos, cardEntity.geometry)) {
                if (event.button == luxe.Input.MouseButton.left) {
                    battleModel.do_action(PlayCard(cardId));
                } else if (event.button == luxe.Input.MouseButton.right) {
                    battleModel.do_action(DiscardCard(cardId));
                }
                break;
            }
        }
    }
}
