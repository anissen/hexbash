
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
import game.Entities.MinionEntity;
import game.Entities.HeroEntity;
import game.Entities.HexSpriteTile;
import game.Entities.HexGrid;
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
    var hexMap :Map<String, HexSpriteTile>;
    var battleModel :BattleModel;
    var hexGrid :HexGrid;
    var currentPlayer :Int;
    var guiBatcher :phoenix.Batcher;
    var handState :HandState;

    public function new() {
        super({ name: StateId });
        battleModel = new BattleModel();
        hexGrid = new HexGrid(35, 6, 4); //new HexGrid();
        levelScene = new Scene();
        guiBatcher = Luxe.renderer.create_batcher({ name: 'gui', layer: 4 });
        handState = new HandState(battleModel, guiBatcher, levelScene);
        battleModel.listen(handle_event);
    }

    override function init() {

    }

    override function onenter(_) {
        Luxe.camera.zoom = 0.2;
        luxe.tween.Actuate.tween(Luxe.camera, 1.0, { zoom: 1.5 });
        Luxe.camera.pos = new Vector(0, 0);
        //reset(87634.34);
        reset(1000 * Math.random());
    }

    override function onleave(_) {
        clear();
    }

    function clear() {
        levelScene.empty();
        hexMap = new Map();
        minionMap = new Map();
        handState.reset();
    }

    function reset(seed :Float) {
        clear();

        Main.states.add(handState);
        Main.states.enable(HandState.StateId);

        battleModel.load_map(seed);
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
            case CardPlayed(cardId): handState.play_card(cardId);
            case CardDrawn(cardId): handState.draw_card(cardId);
            case CardDiscarded(cardId): handState.discard_card(cardId);
            case GameWon: game_over(true);
            case GameLost: game_over(false);
        };
    }

    function add_hex(hex :Hex) :Promise {
        var pos = hexGrid.hex_to_pos(hex);
        // var tile = new HexTile({
        //     pos: new Vector(pos.x, pos.y),
        //     r: hexGrid.hexSize,
        //     scene: levelScene
        // });
        var tile = new HexSpriteTile({
            pos: new Vector(pos.x, pos.y + 12),
            texture: Luxe.resources.texture('assets/images/tile' + (Math.random() > 0.3 ? 'Grass' : 'Dirt') + '_full.png'),
            depth: -100 + hex.r
        });
        var popIn = new FastPopIn();
        tile.add(popIn);
        hexMap[hex.key] = tile;
        return popIn.promise;
    }

    function add_minion(modelId :Int) :Promise {
        var model = battleModel.get_minion_from_id(modelId);
        var minionPos = hexGrid.hex_to_pos(model.hex);
        var options :game.Entities.MinionOptions = {
            model: model,
            pos: new Vector(minionPos.x, minionPos.y),
            color: (model.playerId == 0 ? new Color(129/255, 83/255, 118/255) : new Color(229/255, 83/255, 118/255)),
            depth: 2,
            scene: levelScene
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

    function turn_started(playerId :Int) :Promise {
        if (Main.states.enabled(MinionActionsState.StateId)) {
            Main.states.disable(MinionActionsState.StateId);
            Main.states.enable(HandState.StateId);
        }

        currentPlayer = playerId;
        if (currentPlayer == 1) { // AI
            core.AI.do_actions(battleModel);
        }
        return Promise.resolve();
    }

    function minion_from_model(minionId :Int) {
        return minionMap.get(minionId);
    }

    function move_minion(modelId :Int, from :Hex, to :Hex) :Promise {
        var minion = minion_from_model(modelId);
        minion.pos = hexGrid.hex_to_pos(from);
        var pos = hexGrid.hex_to_pos(to); // TODO: Rename to pos_from_hex
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
        var defenderPos = defender.pos.clone(); // in case defender dies
        Luxe.camera.shake(2);
        return Actuate.tween(attacker.pos, 0.2, { x: defenderPos.x, y: defenderPos.y }).reflect().repeat(1).toPromise();
    }

    function game_over(won :Bool) {
        trace('Game Over - You ${won ? "Won" : "Lost"}!');
        reset(battleModel.get_random().get());
        return Promise.resolve();
    }

    override public function onmousemove(event :luxe.Input.MouseEvent) {
        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);

        /* HACK */
        for (model in battleModel.get_minions()) {
            if (model.playerId != 0) continue; // Only open actions for own minions
            var minion = minionMap[model.id];
            if (minion == null) continue;
            minion.color.r = (model.actions > 0 ? 0.5 : 0.3);
            if (minion != null && Luxe.utils.geometry.point_in_geometry(world_pos, minion.geometry)) {
                minion.color.r = (model.actions > 0 ? 0.8 : 0.3);
            }
        }
    }

    override public function onmouseup(event :luxe.Input.MouseEvent) {
        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);

        /* HACK */
        for (model in battleModel.get_minions()) {
            if (model.playerId != 0) continue; // Only open actions for own minions
            var minion = minionMap[model.id];
            if (minion == null) continue;
            if (Luxe.utils.geometry.point_in_geometry(world_pos, minion.geometry)) {
                if (Main.states.enabled(MinionActionsState.StateId)) {
                    Main.states.disable(MinionActionsState.StateId);
                    Main.states.enable(HandState.StateId);
                } else {
                    Main.states.disable(HandState.StateId);
                    Main.states.enable(MinionActionsState.StateId, { model: model, battleModel: battleModel, hexGrid: hexGrid });
                }
                return;
            }
        }
    }

    override public function onkeyup(event :luxe.Input.KeyEvent) {
        switch (event.keycode) {
            // case luxe.Input.Key.enter: battleModel.do_action(core.Models.Action.EndTurn);
            case luxe.Input.Key.key_r: reset(1000 * Math.random());
            case luxe.Input.Key.kp_minus: Luxe.camera.zoom -= 0.05;
            case luxe.Input.Key.kp_period: Luxe.camera.zoom += 0.05;
        }
    }
}
