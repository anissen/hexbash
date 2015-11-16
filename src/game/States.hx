package game;

import core.HexLibrary;
import luxe.Input.MouseEvent;
import luxe.options.VisualOptions;
import luxe.Scene;
import luxe.States.State;
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
        minion.pos = battleMap.hex_to_pos(to);
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
        luxe.tween.Actuate.tween(attacker.pos, 0.5, { x: defender.pos.x, y: defender.pos.y }).reflect();
    }

    function select(m :Minion) {
        Main.states.set(MinionActionState.StateId, { battleModel: battleModel, battleMap: battleMap, minion: m });
    }

    function selectCard(c :Card) {
        Main.states.set(CardCastState.StateId, { battleMap: battleMap, card: c });
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
            card.add(new SelectableCard(selectCard));
        }
    }
}

class MinionActionState extends State {
    static public var StateId :String = 'MinionActionState';

    var battleModel :BattleModel;
    var battleMap :BattleMap;
    var path_dots :Array<Vector>;
    var reachable_dots :Array<Vector>;
    var attack_dots :Array<Vector>;
    var selected :Minion;

    var mouseMoveEvent :String;
    var clickEvent :String;

    public function new() {
        super({ name: StateId });
        path_dots = [];
        reachable_dots = [];
        attack_dots = [];
    }

    function select(p :Minion) {
        if (selected != null) selected.remove('Selected');
        if (selected == p) {
            selected = null;
            return;
        }
        selected = p;
        selected.add(new Selected({ name: 'Selected' }));

        var hex = battleMap.pos_to_hex(selected.pos);
        var reachable = hex.reachable(battleModel.is_walkable, 2);
        reachable_dots = [ for (r in reachable) {
            var pos = Layout.hexToPixel(battleMap.layout, r);
            new Vector(pos.x, pos.y);
        }];

        attack_dots = [];
        for (a in hex.ring(1)) {
            var model = battleModel.get_minion(a);
            if (model == null || model.playerId == selected.model.playerId) continue;
            var pos = Layout.hexToPixel(battleMap.layout, a);
            attack_dots.push(new Vector(pos.x, pos.y));
        }
    }

    override function onenter<T>(_data :T) {
        trace('MinionActionState::onenter');
        var data :{ battleModel :BattleModel, battleMap :BattleMap, minion :Minion } = cast _data;
        battleModel = data.battleModel;
        battleMap = data.battleMap;

        setup();

        select(data.minion);
    }

    override function onleave<T>(_data :T) {
        trace('MinionActionState::onleave');
        battleMap.events.unlisten(mouseMoveEvent);
        battleMap.events.unlisten(clickEvent);
    }

    function setup() {
        function get_path_positions(hex) {
            if (selected == null) return [];
            var hero_hex = battleMap.pos_to_hex(selected.pos);
            return battleModel.get_path(hero_hex, hex);
        }

        mouseMoveEvent = battleMap.events.listen(BattleMap.HEX_MOUSEMOVED_EVENT, function(hex :Hex) {
            if (selected == null) return;
            path_dots = [];
            for (p in get_path_positions(hex)) {
                var pos = Layout.hexToPixel(battleMap.layout, p);
                path_dots.push(new Vector(pos.x, pos.y));
            }
        });

        clickEvent = battleMap.events.listen(BattleMap.HEX_CLICKED_EVENT, function(hex :Hex) {
            if (selected == null) return;

            var model = battleModel.get_minion(hex);
            if (model != null) {
                if (model.playerId != selected.model.playerId) {
                    battleModel.do_action(Attack(selected.model, model));
                }
                return;
            }

            battleModel.do_action(Move(selected.model, hex));
            /*
            // Attack
            var model = battleModel.get_minion(hex);
            if (model != null && model.playerId != selected.model.playerId) {
                var minPower = Math.floor(Math.min(model.power, selected.model.power));
                model.power -= minPower;
                selected.model.power -= minPower;
                return;
            }

            // Move
            var path = get_path_positions(hex);
            if (path.length == 0) return;
            path_dots = [];
            reachable_dots = [];
            attack_dots = [];
            var count :Int = 0;
            var timePerHex :Float = 0.2;
            for (p in path) {
                var pos = battleMap.hex_to_pos(p);
                Luxe.timer.schedule(count * timePerHex, function() {
                    luxe.tween.Actuate.tween(selected.pos, timePerHex, { x: pos.x, y: pos.y });
                    selected.model.hex = p;
                });
                count++;
            }
            */
        });
    }

    override function onrender() {
        for (dot in reachable_dots) {
            Luxe.draw.circle({
                x: dot.x,
                y: dot.y,
                r: 10,
                color: new Color(0.8, 0.8, 1.0),
                immediate: true,
                depth: 10
            });
        }
        for (dot in path_dots) {
            Luxe.draw.circle({
                x: dot.x,
                y: dot.y,
                r: 20,
                immediate: true,
                depth: 10
            });
        }
        for (dot in attack_dots) {
            Luxe.draw.circle({
                x: dot.x,
                y: dot.y,
                r: 25,
                color: new Color(1.0, 0.6, 0.6),
                immediate: true,
                depth: 10
            });
        }
    }
}

class CardCastState extends State {
    static public var StateId :String = 'CardCastState';

    var battleMap :BattleMap;
    var selectedCard :Card;
    var clickEvent :String;

    public function new() {
        super({ name: StateId });
    }

    function selectCard(c :Card) {
        if (selectedCard != null) selectedCard.remove('SelectedCard');
        if (selectedCard == c) {
            selectedCard = null;
            return;
        }
        selectedCard = c;
        selectedCard.add(new SelectedCard({ name: 'SelectedCard' }));
    }

    override function onenter<T>(_data :T) {
        trace('CardCastState::onenter');
        var data :{battleMap :BattleMap, card :Card} = cast _data;
        battleMap = data.battleMap;

        setup();

        selectCard(data.card);
    }

    override function onleave<T>(_data :T) {
        trace('CardCastState::onleave');
        battleMap.events.unlisten(clickEvent);
    }

    function setup() {
        clickEvent = battleMap.events.listen(BattleMap.HEX_CLICKED_EVENT, function(hex :Hex) {
            if (selectedCard == null) return;
            selectedCard.trigger(hex);
            selectedCard.destroy();
            Main.states.set(BattleState.StateId);
        });
    }
}
