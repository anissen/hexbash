package game;

import core.HexLibrary;
import luxe.Input.MouseEvent;
import luxe.options.VisualOptions;
import luxe.Scene;
import luxe.States.State;
import luxe.tween.Actuate;
import luxe.Vector;
import luxe.Visual;
import luxe.Color;

import core.Models;
import game.Entities.Card;
import game.Entities.Minion;
import game.Entities.HexTile;
import game.Entities.BattleMap;
import game.Components;

using core.HexLibrary.HexTools;

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
        handle_event(eventQueue.pop());
    }

    function handle_event(event :Event) {
        switch (event) {
            case HexAdded(hex): add_hex(hex);
            case MinionAdded(model): add_minion(model);
            case MinionMoved(model, from, to): move_minion(model, from, to);
            case MinionDamaged(model, damage): damage_minion(model, damage);
            case MinionAttacked(attacker, defender): attack_minion(attacker, defender);
            case MinionDied(model): remove_minion(model);
        }
    }

    function add_hex(hex :Hex) {
        var pos = Layout.hexToPixel(battleMap.layout, hex);
        var tile = new HexTile({
            pos: new Vector(pos.x, pos.y),
            r: battleMap.hexSize,
            scene: levelScene
        });
        tile.add(new PopIn());
        hexMap[hex.key] = tile;
    }

    function add_minion(model :MinionModel) {
        var minionPos = Layout.hexToPixel(battleMap.layout, model.hex);
        var minion = new Minion({
            model: model,
            pos: new Vector(minionPos.x, minionPos.y),
            color: (model.playerId == 0 ? new Color(129/255, 83/255, 118/255) : new Color(229/255, 83/255, 118/255)),
            depth: 2
        });
        minionMap.set(model.id, minion);
        minion.add(new PopIn());
        if (model.playerId == 0) minion.add(new Selectable(select));
    }

    function remove_minion(model :MinionModel) {
        var minion = minion_from_model(model);
        minion.destroy();
        minionMap.remove(model.id);
    }

    function minion_from_model(model :MinionModel) {
        return minionMap.get(model.id);
    }

    function move_minion(model :MinionModel, from :Hex, to :Hex) {
        trace('move_minion: from $from to $to');
        var minion = minion_from_model(model);
        minion.pos = battleMap.hex_to_pos(from);
        var pos = battleMap.hex_to_pos(to); // TODO: Rename to pos_from_hex
        luxe.tween.Actuate.tween(minion, 0.5, { x: pos.x, y: pos.y });
    }

    function damage_minion(model :MinionModel, damage :Int) {
        trace('damage_minion: $damage damage');
        var minion = minion_from_model(model);
        luxe.tween.Actuate.tween(minion.color, 0.5, { r: 1 }).reflect();
    }

    function attack_minion(attackerModel :MinionModel, defenderModel :MinionModel) {
        trace('attack_minion: $attackerModel attacks $defenderModel');
        var attacker = minion_from_model(attackerModel);
        var defender = minion_from_model(defenderModel);
        Actuate.tween(attacker.pos, 0.5, { x: defender.pos.x, y: defender.pos.y }).reflect();
    }

    function setup_map() {
        battleModel.add_minion(new MinionModel('Enemy', 1, 8, new Hex(3, -2, 0)));
        battleModel.add_minion(new MinionModel('Hero', 0, 5, new Hex(-1, 0, 0)));
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
        if (event.keycode == luxe.Input.Key.key_a) {
            var minion = minionMap.iterator().next();
            if (minion == null) return;
            var minionModel = minion.model;
            var hexes = minionModel.hex.reachable(battleModel.is_walkable, 1);
            if (hexes.length == 0) return;
            var randomHex = hexes[Math.floor(hexes.length * Math.random())];
            battleModel.do_action(core.Models.Action.Move(minionModel, randomHex));
        } else if (event.keycode == luxe.Input.Key.key_r) {
            battleModel.replay();
        }
    }
}
