
package game.states;

import luxe.Input.MouseEvent;
import luxe.States.State;
import luxe.Vector;
import luxe.tween.Actuate;
import game.Entities.CardEntity;
import game.Entities.DeckEntity;
import core.Models.BattleModel;
import phoenix.Batcher;
import luxe.Scene;
import luxe.Color;

import snow.api.Promise;

class HandState extends State {
    static public var StateId :String = 'HandState';
    var deck :DeckEntity;
    var cardMap :Map<Int, CardEntity>;
    var battleModel :BattleModel;
    var batcher :Batcher;
    var scene :Scene;
    var grabbedCardEntity :CardEntity;
    var card_y :Float;
    static public var hexGrid :game.Entities.HexGrid; // HACK!

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

        if (deck == null) {
            deck = new DeckEntity({
                centered: true,
                pos: new Vector(Luxe.screen.width - 300, Luxe.screen.height),
                color: new Color(0, 0, 0),
                batcher: this.batcher,
                depth: 4,
                scene: this.scene
            });
            deck.set_text('Deck');
        }

        position_cards();
    }

    override function ondisabled<T>(value :T) {
        card_y = Luxe.screen.height;
        position_cards();
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
            pos: deck.pos.clone(),
            color: color,
            batcher: batcher,
            depth: 3,
            scene: scene
        });
        cardMap.set(card.id, cardEntity);

        var deckSize = battleModel.get_deck_size();
        deck.set_text('Deck\n\nCards: $deckSize');

        var draw_animation = new Promise(function(resolve) {
            Actuate.tween(cardEntity, 0.2, { rotation_z: -10 + 20 * Math.random() });
            Actuate.tween(cardEntity.pos, 0.4, { x: deck.pos.x + 50 - 150 * Math.random(), y: deck.pos.y - 100 - 50 * Math.random() }).onComplete(resolve);
        });
        return draw_animation.then(position_cards);
    }

    function position_cards() :Promise {
        var cardCount = Lambda.count(cardMap);
        var cardWidth = 130;
        var startX = (Luxe.screen.width / 2) - ((cardCount + 1 /* deck */) / 2) * cardWidth;
        var i = cardCount - 1;
        for (c in cardMap) {
            Actuate.tween(c.pos, 0.3, {
                x: startX + (i--) * cardWidth,
                y: card_y
            });
            Actuate.tween(c, 0.3, {
                rotation_z: 0
            });
        }

        return new Promise(function(resolve) {
            Actuate.tween(deck.pos, 0.3, {
                x: startX + cardCount * cardWidth,
                y: card_y
            }).onComplete(resolve);
        });
    }

    public function play_card(cardId :Int) :Promise {
        return remove_card(cardId);
    }

    public function discard_card(cardId :Int) :Promise {
        return remove_card(cardId);
    }

    public function remove_card(cardId :Int) :Promise {
        var cardEntity = card_from_model(cardId);
        cardMap.remove(cardId);
        if (grabbedCardEntity == cardEntity) grabbedCardEntity = null;
        cardEntity.destroy();

        var deckSize = battleModel.get_deck_size();
        deck.set_text('Deck\n\nCards: $deckSize');

        return position_cards();
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
        if (event.button != luxe.Input.MouseButton.left) return;

        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);

        /* HACK */
        for (cardId in cardMap.keys()) {
            var cardEntity = cardMap[cardId];
            if (Luxe.utils.geometry.point_in_geometry(screen_pos, cardEntity.geometry)) {
                grabbed_card(cardEntity);
                break;
            }
        }
    }

    function grabbed_card(cardEntity :CardEntity) {
        grabbedCardEntity = cardEntity;
    }

    override public function onmouseup(event :luxe.Input.MouseEvent) {
        if (!enabled) return;
        if (grabbedCardEntity == null) return;

        var cardId = -1;
        for (key in cardMap.keys()) {
            if (cardMap[key] == grabbedCardEntity) cardId = key;
        }
        if (cardId == -1) return;

        // if card is dropped on the deck
        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);
        if (Luxe.utils.geometry.point_in_geometry(screen_pos, deck.geometry)) {
            battleModel.do_action(DiscardCard(cardId));
            return;
        }

        // if card is dropped on a target
        // TODO:
        var mouse_hex = hexGrid.pos_to_hex(screen_pos);
        var targets = [new core.HexLibrary.Hex(0, 0), new core.HexLibrary.Hex(0, 1)]; // battleModel.get_targets_for_card(cardId);
        for (hex in targets) {
            if (hex.key == mouse_hex.key) {
                battleModel.do_action(PlayCard(cardId, hex));
                return;
            }
        }

        // if card has no valid drop, put it back
        grabbedCardEntity.color.a = 1;
        grabbedCardEntity = null;
        position_cards();
    }

    override public function onrender() {
        if (grabbedCardEntity != null) {
            var targets = [new core.HexLibrary.Hex(0, 0), new core.HexLibrary.Hex(0, 1)]; // battleModel.get_targets_for_card(cardId);
            for (target in targets) {
                var pos = hexGrid.hex_to_pos(target);
                Luxe.draw.circle({ x: pos.x, y: pos.y, color: new Color(1, 0.5, 1, 0.4), r: 30, immediate: true, depth: 15 });
            }
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
