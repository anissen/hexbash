
package game.states;

import core.HexLibrary;
import luxe.Input.MouseEvent;
import luxe.options.VisualOptions;
import luxe.Scene;
import luxe.States.State;
import luxe.tween.Actuate;
import luxe.Vector;
import luxe.Visual;
import luxe.Color;
import snow.api.Promise;

import core.Models;
import core.PromiseQueue;
import game.Entities.CardEntity;
import game.Entities.MinionEntity;
import game.Entities.HeroEntity;
import game.Entities.HexTile;
import game.Entities.BattleMap;
import game.Components;

using core.HexLibrary.HexTools;
using core.ArrayTools;
using game.states.BattleState.TweenTools;

class TweenTools {
    static public function toPromise(tween :luxe.tween.actuators.GenericActuator.IGenericActuator) :Promise {
        return new Promise(function(resolve) {
            tween.onComplete(resolve);
        });
    }
}

class BattleState extends State {
    static public var StateId :String = 'BattleState';
    var levelScene :Scene;
    var minionMap :Map<Int, MinionEntity>;
    var cardMap :Map<Int, CardEntity>;
    var hexMap :Map<String, HexTile>;
    var battleModel :BattleModel;
    var battleMap :BattleMap;
    var currentPlayer :Int;

    public function new() {
        super({ name: StateId });
        battleModel = new BattleModel();
        battleMap = new BattleMap();
        levelScene = new Scene();
        hexMap = new Map();
        minionMap = new Map();
        cardMap = new Map();
    }

    override function init() {
        battleModel.listen(handle_event);
        battleModel.load_map(87634.34);
        battleModel.start_game();
    }

    function handle_event(event :Event) :Promise {
        return switch (event) {
            case HexAdded(hex): add_hex(hex);
            case MinionAdded(modelId): add_minion(modelId);
            case MinionMoved(modelId, from, to): move_minion(modelId, from, to);
            case MinionDamaged(modelId, amount): damage_minion(modelId, amount);
            case MinionHealed(modelId, amount): heal_minion(modelId, amount);
            case MinionAttacked(attackerId, defenderId): attack_minion(attackerId, defenderId);
            case MinionDied(modelId): remove_minion(modelId);
            case TurnStarted(playerId): turn_started(playerId);
            case CardPlayed(cardId): play_card(cardId);
            case CardDrawn(cardId): draw_card(cardId);
        };
    }

    function add_hex(hex :Hex) :Promise {
        var pos = Layout.hexToPixel(battleMap.layout, hex);
        var tile = new HexTile({
            pos: new Vector(pos.x, pos.y),
            r: battleMap.hexSize,
            scene: levelScene
        });
        var popIn = new FastPopIn();
        tile.add(popIn);
        hexMap[hex.key] = tile;
        return popIn.promise;
    }

    function add_minion(modelId :Int) :Promise {
        var model = battleModel.get_minion_from_id(modelId);
        var minionPos = Layout.hexToPixel(battleMap.layout, model.hex);
        var options :game.Entities.MinionOptions = {
            model: model,
            pos: new Vector(minionPos.x, minionPos.y),
            color: (model.playerId == 0 ? new Color(129/255, 83/255, 118/255) : new Color(229/255, 83/255, 118/255)),
            depth: 2
        };
        var minion = (model.hero ? new HeroEntity(options) : new MinionEntity(options));
        minionMap.set(modelId, minion);
        var popIn = new PopIn();
        minion.add(popIn);
        return popIn.promise;
    }

    function remove_minion(modelId :Int) :Promise {
        var minion = minion_from_model(modelId);
        minion.destroy();
        minionMap.remove(modelId);
        return Promise.resolve();
    }

    function draw_card(cardId :Int) :Promise {
        var card = battleModel.get_card_from_id(cardId);
        var cost = switch (card.cardType) {
            case Minion(_, cost): cost;
            case Potion(power): power;
        };
        var cardEntity = new CardEntity({
            text: card.title,
            cost: cost,
            pos: new Vector(600, 600),
            depth: 3,
            scene: levelScene
        });
        cardMap.set(card.id, cardEntity);
        var i = 0;
        for (c in cardMap) {
            luxe.tween.Actuate.tween(c.pos, 0.3, { x: 600 - 120 * (i++) });
        }
        var popIn = new PopIn();
        cardEntity.add(popIn);
        return popIn.promise;
    }

    function play_card(cardId :Int) :Promise {
        var cardEntity = card_from_model(cardId);
        cardMap.remove(cardId);
        cardEntity.destroy();
        return Promise.resolve();
    }

    function turn_started(playerId :Int) :Promise {
        if (Main.states.enabled(MinionActionsState.StateId)) {
            Main.states.disable(MinionActionsState.StateId);
        }

        currentPlayer = playerId;
        if (currentPlayer == 1) { // AI
            do_ai_actions();
        }
        return Promise.resolve();
    }

    function get_ai_minion_action(battleModel :BattleModel, model :MinionModel) :MinionAction { // TODO: Move this into a separate file

        // simple AI:
        // 1. Attacks enemy if possible
        // 2. Moves towards enemy hero if possible
        // 3. Performs random available action

        function random_int(v :Int) {
            return battleModel.get_random().int(v);
        }

        var attackActions = battleModel.get_minion_attacks(model.id);
        if (attackActions.length > 0) {
            // Attack hero if available
            for (attack in attackActions) {
                switch (attack) {
                    case Attack(defenderId): if (battleModel.get_minion_from_id(defenderId).hero) return attack;
                    case _:
                }
            }
            return attackActions.random();
        }

        var playerMinions = battleModel.get_minions().filter(function(m) { return m.playerId != model.playerId; });
        if (playerMinions.length > 0) {
            var playerMinion = playerMinions[0];

            var playerHero = playerMinions.filter(function(m) { return m.hero; });
            if (playerHero.length > 0) {
                playerMinion = playerHero[0];
            }

            // hex i walkable if it exists and a) is unoccupied or b) is occupied by an enemy (to be killed)
            function walkable(hex :Hex) :Bool {
                if (!battleModel.has_hex(hex)) return false;
                var minion = battleModel.get_minion(hex);
                return (minion == null || minion.playerId != model.playerId);
            }

            var path = model.hex.find_path(playerMinion.hex, 100, 6, walkable, true);
            if (path.length > 0) return Move(path[0]);
        }

        var actions = battleModel.get_minion_actions(model.id);
        if (actions.length > 0) {
            return actions[Math.floor(actions.length * Math.random())];
        }

        return Nothing;
    }

    function do_ai_actions() { // TODO: Move this into a separate file
        var newBattleModel = battleModel;
        var chosenActions = [];
        while (true) {
            var model = null;
            var actions = [];
            for (m in newBattleModel.get_minions()) {
                if (m.playerId != currentPlayer) continue;
                if (m.actions <= 0) continue;
                model = m;
                actions = newBattleModel.get_minion_actions(m.id);
                if (actions.length > 0) break;
            }
            if (model == null || actions.length == 0) break;

            // has minion with available actions
            var minion_action = get_ai_minion_action(newBattleModel, model);
            var ai_action = MinionAction(model.id, minion_action);
            chosenActions.push(ai_action);

            newBattleModel = newBattleModel.clone();
            newBattleModel.do_action(ai_action);
        }

        for (action in chosenActions) {
            battleModel.do_action(action);
        }
        battleModel.do_action(EndTurn);
    }

    function minion_from_model(minionId :Int) {
        return minionMap.get(minionId);
    }

    function card_from_model(cardId :Int) {
        return cardMap.get(cardId);
    }

    function move_minion(modelId :Int, from :Hex, to :Hex) :Promise {
        var minion = minion_from_model(modelId);
        minion.pos = battleMap.hex_to_pos(from);
        var pos = battleMap.hex_to_pos(to); // TODO: Rename to pos_from_hex
        return Actuate.tween(minion.pos, 0.2, { x: pos.x, y: pos.y }).toPromise();
    }

    function damage_minion(modelId :Int, amount :Int) :Promise {
        var minion = minion_from_model(modelId);
        return new Promise(function(resolve) {
            Actuate.tween(minion.color, 0.1, { r: 1.0, g: 1.0, b: 1.0 }).reflect().repeat(1)
                .onComplete(function() { minion.damage(amount); resolve(); });
        });
    }

    function heal_minion(modelId :Int, amount :Int) :Promise {
        var minion = minion_from_model(modelId);
        return new Promise(function(resolve) {
            Actuate.tween(minion.color, 0.1, { r: 0.0, g: 1.0, b: 0.0 }).reflect().repeat(1)
                .onComplete(function() { minion.heal(amount); resolve(); });
        });
    }

    function attack_minion(attackerModelId :Int, defenderModelId :Int) :Promise {
        var attacker = minion_from_model(attackerModelId);
        var defender = minion_from_model(defenderModelId);
        return Actuate.tween(attacker.pos, 0.2, { x: defender.pos.x, y: defender.pos.y }).reflect().repeat(1).toPromise();
    }

    override public function onmouseup(event :luxe.Input.MouseEvent) {
        var pos = Luxe.camera.screen_point_to_world(event.pos);

        /* HACK */
        for (cardId in cardMap.keys()) {
            var cardEntity = cardMap[cardId];
            if (Luxe.utils.geometry.point_in_geometry(pos, cardEntity.geometry)) {
                battleModel.do_action(PlayCard(cardId));
                break;
            }
        }

        /* HACK */
        for (model in battleModel.get_minions()) {
            if (model.playerId != 0) continue; // Only open actions for own minions
            var minion = minionMap[model.id];
            if (minion != null && Luxe.utils.geometry.point_in_geometry(pos, minion.geometry)) {
                if (Main.states.enabled(MinionActionsState.StateId)) {
                    Main.states.disable(MinionActionsState.StateId);
                }
                Main.states.enable(MinionActionsState.StateId, { model: model, battleModel: battleModel, battleMap: battleMap });
                return;
            }
        }
    }

    override public function onkeyup(event :luxe.Input.KeyEvent) {
        if (event.keycode == luxe.Input.Key.enter) {
            battleModel.do_action(core.Models.Action.EndTurn);
        }
    }
}
