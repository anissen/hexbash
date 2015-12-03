
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
import game.Entities.Card;
import game.Entities.Minion;
import game.Entities.Hero;
import game.Entities.HexTile;
import game.Entities.BattleMap;
import game.Components;

using core.HexLibrary.HexTools;
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
    var minionMap :Map<Int, Minion>;
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
    }

    override function init() {
        battleModel.listen(handle_event);
        battleModel.load_map();

        setup_map();
        setup_hand();
    }

    function handle_event(event :Event) :Promise {
        return switch (event) {
            case HexAdded(hex): add_hex(hex);
            case MinionAdded(modelId): add_minion(modelId);
            case MinionMoved(modelId, from, to): move_minion(modelId, from, to);
            case MinionDamaged(modelId, damage): damage_minion(modelId, damage);
            case MinionAttacked(attackerId, defenderId): attack_minion(attackerId, defenderId);
            case MinionDied(modelId): remove_minion(modelId);
            case TurnStarted(playerId): turn_started(playerId);
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
        var minion = (model.hero ? new Hero(options) : new Minion(options));
        minionMap.set(model.id, minion);
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
        trace('Turn started for player $playerId');
        if (Main.states.enabled(MinionActionsState.StateId)) {
            Main.states.disable(MinionActionsState.StateId);
        }

        currentPlayer = playerId;
        if (currentPlayer == 1) { // AI
            do_ai_actions();
        }
        return Promise.resolve();
    }

    function get_ai_minion_action(battleModel :BattleModel, model :MinionModel) :MinionAction {
        // simple AI:
        // 1. Attacks enemy if possible
        // 2. Moves towards enemy hero if possible
        // 3. Performs random available action

        var attackActions = battleModel.get_minion_attacks(model.id);
        if (attackActions.length > 0) {
            return attackActions[Math.floor(attackActions.length * Math.random())];
        }

        var playerMinions = battleModel.get_minions().filter(function(m) { return m.playerId != model.playerId; });
        if (playerMinions.length > 0) {
            var firstPlayerMinion = playerMinions[0];
            var path = model.hex.find_path(firstPlayerMinion.hex, 100, 6, battleModel.is_walkable, true);
            if (path.length > 0) {
                return Move(path[0]);
            }
        }

        var actions = battleModel.get_minion_actions(model.id);
        if (actions.length > 0) {
            return actions[Math.floor(actions.length * Math.random())];
        }

        return Nothing;
    }

    function do_ai_actions() {
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

    function minion_from_model(modelId :Int) {
        return minionMap.get(modelId);
    }

    function move_minion(modelId :Int, from :Hex, to :Hex) :Promise {
        // trace('move_minion: from $from to $to');
        var minion = minion_from_model(modelId);
        minion.pos = battleMap.hex_to_pos(from);
        var pos = battleMap.hex_to_pos(to); // TODO: Rename to pos_from_hex
        return Actuate.tween(minion.pos, 0.3, { x: pos.x, y: pos.y }).toPromise();
    }

    function damage_minion(modelId :Int, damage :Int) :Promise {
        // trace('damage_minion: $damage damage');
        var minion = minion_from_model(modelId);
        return new Promise(function(resolve) {
            Actuate.tween(minion.color, 0.2, { r: 1.0, g: 1.0, b: 1.0 }).reflect().repeat(1)
                .onComplete(function() { minion.damage(damage); resolve(); });
        });
    }

    function attack_minion(attackerModelId :Int, defenderModelId :Int) :Promise {
        // trace('attack_minion: $attackerModel attacks $defenderModel');
        var attacker = minion_from_model(attackerModelId);
        var defender = minion_from_model(defenderModelId);
        return Actuate.tween(attacker.pos, 0.2, { x: defender.pos.x, y: defender.pos.y }).reflect().repeat(1).toPromise();
    }

    function setup_map() {
        // TODO: Load from file
        var playerId = 0;
        battleModel.add_minion(new MinionModel('Hero', playerId, 13, new Hex(-1, 2), null, true));
        battleModel.add_minion(new MinionModel('Hero Minion 1', playerId, 2, new Hex(-2, 2)));

        var enemyId = 1;
        battleModel.add_minion(new MinionModel('Enemy', enemyId, 8, new Hex(1, -2), null, true));
        battleModel.add_minion(new MinionModel('Enemy Minion 1', enemyId, 3, new Hex(0, -2)));
        battleModel.add_minion(new MinionModel('Enemy Minion 2', enemyId, 3, new Hex(2, -2)));
    }

    function setup_hand() {
        function create_minion(hex) {
            battleModel.add_minion(new MinionModel('Minion', 0, 3, hex));
        }

        var cardCount = 3;
        for (i in 0 ... cardCount) {
            var card = new Card({ pos: new Vector(200 + 120 * i, 600), depth: 3, effect: create_minion });
            card.add(new PopIn());
        }
    }

    override public function onmouseup(event :luxe.Input.MouseEvent) {
        /* HACK */
        for (model in battleModel.get_minions()) {
            if (model.playerId != 0) continue; // Only open actions for own minions
            if (model.actions <= 0) continue;
            var pos = Luxe.camera.screen_point_to_world(event.pos);
            var minion = minionMap[model.id];
            if (Luxe.utils.geometry.point_in_geometry(pos, minion.geometry)) {
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
        }/* else if (event.keycode == luxe.Input.Key.key_r) {
            battleModel.replay();
        } */
    }
}
