
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
            case MinionAdded(model): add_minion(model);
            case MinionMoved(model, from, to): move_minion(model, from, to);
            case MinionDamaged(model, damage): damage_minion(model, damage);
            case MinionAttacked(attacker, defender): attack_minion(attacker, defender);
            case MinionDied(model): remove_minion(model);
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

    function add_minion(model :MinionModel) :Promise {
        var minionPos = Layout.hexToPixel(battleMap.layout, model.hex);
        var minion = new Minion({
            model: model,
            pos: new Vector(minionPos.x, minionPos.y),
            color: (model.playerId == 0 ? new Color(129/255, 83/255, 118/255) : new Color(229/255, 83/255, 118/255)),
            depth: 2
        });
        minionMap.set(model.id, minion);
        var popIn = new PopIn();
        minion.add(popIn);
        return popIn.promise;
    }

    function remove_minion(model :MinionModel) :Promise {
        var minion = minion_from_model(model);
        minion.destroy();
        minionMap.remove(model.id);
        return Promise.resolve();
    }

    function minion_from_model(model :MinionModel) {
        return minionMap.get(model.id);
    }

    function move_minion(model :MinionModel, from :Hex, to :Hex) :Promise {
        // trace('move_minion: from $from to $to');
        var minion = minion_from_model(model);
        minion.pos = battleMap.hex_to_pos(from);
        var pos = battleMap.hex_to_pos(to); // TODO: Rename to pos_from_hex
        return Actuate.tween(minion.pos, 0.3, { x: pos.x, y: pos.y }).toPromise();
    }

    function damage_minion(model :MinionModel, damage :Int) :Promise {
        // trace('damage_minion: $damage damage');
        var minion = minion_from_model(model);
        return new Promise(function(resolve) {
            Actuate.tween(minion.color, 0.2, { r: 1.0, g: 1.0, b: 1.0 }).reflect().repeat(1)
                .onComplete(function() { minion.set_power(model.power); resolve(); });
        });
    }

    function attack_minion(attackerModel :MinionModel, defenderModel :MinionModel) :Promise {
        // trace('attack_minion: $attackerModel attacks $defenderModel');
        var attacker = minion_from_model(attackerModel);
        var defender = minion_from_model(defenderModel);
        return Actuate.tween(attacker.pos, 0.2, { x: defender.pos.x, y: defender.pos.y }).reflect().repeat(1).toPromise();
    }

    function setup_map() {
        battleModel.add_minion(new MinionModel('Hero', 0, 5, new Hex(-1, 2, 0)));

        battleModel.add_minion(new MinionModel('Enemy', 1, 8, new Hex(1, -2, 0)));
        battleModel.add_minion(new MinionModel('Enemy Minion 1', 1, 3, new Hex(0, -2, 0)));
        battleModel.add_minion(new MinionModel('Enemy Minion 2', 1, 3, new Hex(2, -2, 0)));
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

    override public function onkeydown(event :luxe.Input.KeyEvent) {
        if (event.keycode == luxe.Input.Key.key_m) {
            var minion = minionMap[0];
            if (minion == null) return;
            var minionModel = minion.model;
            var moves = battleModel.get_minion_moves(minionModel);
            if (moves.length == 0) return;
            var randomMove = moves[Math.floor(moves.length * Math.random())];
            battleModel.do_action(randomMove);
        } else if (event.keycode == luxe.Input.Key.key_a) {
            var minion = minionMap[0];
            if (minion == null) return;
            var minionModel = minion.model;
            var attacks = battleModel.get_minion_attacks(minionModel);
            if (attacks.length == 0) return;
            var randomAttack = attacks[Math.floor(attacks.length * Math.random())];
            battleModel.do_action(randomAttack);
        } else if (event.keycode == luxe.Input.Key.key_p) {
            var minion = minionMap[1];
            var minion2 = minionMap[0];
            if (minion == null || minion2 == null) return;
            var minionModel = minion.model;
            var minionModel2 = minion2.model;
            // var nearbyHexes = minionModel2.hex.reachable(battleModel.is_walkable, 1); // HACK because endpoint is not reachable
            // var randomNearbyHex = nearbyHexes[Math.floor(nearbyHexes.length * Math.random())];

            function walkable(hex :Hex) {
                if (!battleModel.has_hex(hex)) return false;
                if (hex.key == minionModel2.hex.key) return true; // Ignore that goal is occupied by a minion
                if (battleModel.get_minion(hex) != null) return false;
                return true;
            }

            var path = minionModel.hex.find_path(minionModel2.hex, 100, 6, walkable);
            for (i in 0 ... path.length - 1 /* don't move on top of minion2 */) {
                battleModel.do_action(core.Models.Action.Move(minionModel, path[i]));
            }
        } /* else if (event.keycode == luxe.Input.Key.key_r) {
            battleModel.replay();
        } */
    }
}
