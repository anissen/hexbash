
package game.states;

import luxe.Input.MouseEvent;
import luxe.States.State;
import luxe.Vector;
import luxe.tween.Actuate;
import game.Entities.CardEntity;
import game.Entities.DeckEntity;
import core.models.Battle;
import core.models.Minion;
import phoenix.Batcher;
import luxe.Scene;
import luxe.Color;

import snow.api.Promise;

class HandState extends State {
    static public var StateId :String = 'HandState';
    var deckEntity :DeckEntity;
    var cardMap :Map<Int, CardEntity>;
    var battle :Battle;
    var batcher :Batcher;
    var scene :Scene;
    var grabbedCardEntity :CardEntity;
    var card_y :Float;
    static public var hexGrid :game.Entities.HexGrid; // HACK!

    public function new(battle :Battle, batcher :Batcher, scene :Scene) {
        super({ name: StateId });
        this.battle = battle;
        this.batcher = batcher;
        this.scene = scene;
        card_y = Luxe.screen.height - 100;

        reset();
    }

    override function onenabled<T>(value :T) {
        card_y = Luxe.screen.height - 100;

        if (deckEntity == null) {
            deckEntity = new DeckEntity({
                centered: true,
                pos: new Vector(Luxe.screen.width - 300, Luxe.screen.height),
                color: new Color(0, 0, 0),
                batcher: this.batcher,
                depth: 4,
                scene: this.scene
            });
            deckEntity.set_text('Deck');
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
        var card = battle.get_card_from_id(cardId);
        var color = switch (card.type) {
            case Minion(_): new Color(0.2, 0.5, 0.5);
            // case Tower(_, _): new Color(0.2, 0.3, 0.8);
            // case Potion(_): new Color(0.2, 0.8, 0.3);
            case Spell(_): new Color(0.8, 0.2, 0.3);
            case Curse(_): new Color(0.7, 0.0, 0.6);
            case Attack(_): new Color(1.0, 0.1, 0.2);
        };
        var cardEntity = new CardEntity({
            centered: true,
            card: card,
            pos: deckEntity.pos.clone(),
            color: color,
            batcher: batcher,
            depth: 3,
            scene: scene
        });
        cardMap.set(card.id, cardEntity);

        var deckSize = battle.get_deck_size();
        deckEntity.set_text('Deck\n\nCards: $deckSize');

        var draw_animation = new Promise(function(resolve) {
            Actuate.tween(cardEntity, 0.2, { rotation_z: -10 + 20 * Math.random() });
            Actuate.tween(cardEntity.pos, 0.4, { x: deckEntity.pos.x + 50 - 150 * Math.random(), y: deckEntity.pos.y - 100 - 50 * Math.random() }).onComplete(resolve);
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

        if (deckEntity == null) return Promise.resolve(); // If we're terminating the game

        return new Promise(function(resolve) {
            Actuate.tween(deckEntity.pos, 0.3, {
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
        if (cardEntity == null) return Promise.resolve();

        cardMap.remove(cardId);
        if (grabbedCardEntity == cardEntity) release_grabbed_card();
        cardEntity.destroy();

        var deckSize = battle.get_deck_size();
        deckEntity.set_text('Deck\n\nCards: $deckSize');

        return position_cards();
    }

    public function reset() {
        cardMap = new Map();
    }

    override public function onmousemove(event :luxe.Input.MouseEvent) {
        if (!enabled) return;

        if (grabbedCardEntity != null) {
            grabbedCardEntity.rotation_z = luxe.utils.Maths.clamp(grabbedCardEntity.rotation_z + event.x_rel / 50, -5, 5);
            grabbedCardEntity.color.a = 0; // Remove everything but the icon instead
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
                var can_play = battle.can_play_card(cardId);
                cardEntity.color.r = (can_play ? 0.8 : 0.2);
            }
        }
    }

    override public function onmousedown(event :luxe.Input.MouseEvent) {
        if (!enabled) return;
        if (event.button != luxe.Input.MouseButton.left) return;

        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);

        /* HACK */
        for (cardId in cardMap.keys()) {
            var cardEntity = cardMap[cardId];
            if (Luxe.utils.geometry.point_in_geometry(screen_pos, cardEntity.geometry)) {
                grab_card(cardEntity);
                break;
            }
        }
    }

    function grab_card(cardEntity :CardEntity) {
        grabbedCardEntity = cardEntity;
        var deckText = switch (cardEntity.card.type) {
            case Attack(_): 'Discard';
            case Curse(_): 'Curse!';
            default: 'Put Back';
        }
        deckEntity.set_text(deckText);
    }

    function release_grabbed_card() {
        if (grabbedCardEntity != null) grabbedCardEntity.color.a = 1;
        grabbedCardEntity = null;

        var deckSize = battle.get_deck_size();
        deckEntity.set_text('Deck\n\nCards: $deckSize');
    }

    override public function onmouseup(event :luxe.Input.MouseEvent) {
        if (!enabled) return;
        if (grabbedCardEntity == null) return;

        var cardId = grabbedCardEntity.card.id;

        // if card is dropped on the deck
        var is_curse = switch (grabbedCardEntity.card.type) {
            case core.Enums.CardType.Curse: true;
            default: false;
        };
        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);
        if (!is_curse && Luxe.utils.geometry.point_in_geometry(screen_pos, deckEntity.geometry)) {
            battle.do_action(DiscardCard(cardId));
            return;
        }

        // if card is dropped on a target
        if (battle.can_play_card(cardId)) {
            var mouse_hex = hexGrid.pos_to_hex(world_pos);
            var targets = battle.get_targets_for_card(cardId);
            for (hex in targets) {
                if (hex.key == mouse_hex.key) {
                    battle.do_action(PlayCard(cardId, hex));
                    return;
                }
            }
        }

        // if card has no valid drop, put it back
        release_grabbed_card();
        position_cards();
    }

    override public function onrender() {
        // TODO: Maybe only update this when drawing cards and playing cards (e.g. when the state changes)
        // for (cardId in cardMap.keys()) {
        //     cardMap[cardId].color.a = (battle.get_targets_for_card(cardId).length == 0 ? 0.5 : 1.0);
        // }

        if (grabbedCardEntity != null) {
            var cardId = grabbedCardEntity.card.id;

            var world_pos = Luxe.camera.screen_point_to_world(Luxe.screen.cursor.pos);
            var mouse_hex = hexGrid.pos_to_hex(world_pos);
            var targets = battle.get_targets_for_card(cardId);
            var card = battle.get_card_from_id(cardId);

            function is_target_highlighted(target :core.HexLibrary.Hex) {
                // if mouse over
                if (target.key == mouse_hex.key) return true;

                // if card is type minion and the mouse is over ANY of the targets
                switch (card.type) {
                    case Minion(_):
                    default: return false;
                }
                var over_target = false;
                for (t in targets) {
                    if (t.key == mouse_hex.key) return true;
                }
                return false;
            }

            for (target in targets) {
                var pos = hexGrid.hex_to_pos(target);
                var radius = (is_target_highlighted(target) ? 35 : 30);
                Luxe.draw.circle({ x: pos.x, y: pos.y, color: new Color(1, 0.5, 1, 0.4), r: radius, immediate: true, depth: 15 });
                Luxe.draw.texture({ texture: Luxe.resources.texture('assets/images/icons/${card.icon}'), size: new Vector(radius, radius), immediate: true, x: pos.x - radius * 0.5, y: pos.y - radius * 0.5 });
            }
        }
    }
}
