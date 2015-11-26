package core;

import snow.api.Promise;
import core.HexLibrary;
using core.HexLibrary.HexTools;

/*
Idea:
BattleState
    HAS a BattleMap
    HAS cards
    HAS entities
    States:
    -> MinionActionState
    -> CardCastState

Model-View separation between LevelMap, minions, Cards
*/

class MinionModel {
    static var Id :Int = 0;
    public var id :Int;
    public var title :String;
    public var playerId :Int;
    public var power :Int;
    public var hex :Hex;
    public var actions :Int;

    public function new(title :String, playerId :Int, power :Int, hex :Hex, ?id :Int) {
        this.id = (id != null ? id : Id++);
        this.title = title;
        this.playerId = playerId;
        this.power = power;
        this.hex = hex;
        this.actions = 1;
    }

    // public function clone() {
    //     return new MinionModel(title, playerId, power, hex, id);
    // }
}

typedef EventListenerFunction = Event -> snow.api.Promise;

enum Action {
    MinionAction(model :MinionModel, action :MinionAction);
    EndTurn();
}

enum MinionAction {
    Move(hex :Hex);
    Attack(defenderModel :MinionModel);
}

enum Event {
    HexAdded(hex :Hex);
    MinionAdded(model :MinionModel);
    MinionMoved(model :MinionModel, from :Hex, to :Hex);
    MinionAttacked(attackerModel :MinionModel, defenderModel :MinionModel);
    MinionDamaged(model :MinionModel, damage :Int);
    MinionDied(model :MinionModel);
    TurnStarted(playerId :Int);
}

class BattleModel {
    var actions :MessageQueue<Action>;
    var events :PromiseQueue<Event>;
    var hexes :Map<String, Hex>;
    var minions :Array<MinionModel>;
    var random :luxe.utils.Random;
    var listeners :List<EventListenerFunction>;
    var currentPlayerId :Int;
    var actions_finished_func :Void->Void;
    public var actions_finished :Promise;

    public function new() {
        listeners = new List();
        random = new luxe.utils.Random(42);
        hexes = new Map();
        minions = [];
        currentPlayerId = 0;

        actions_finished = new Promise(function(resolve, reject) {
            actions_finished_func = resolve;
        });

        actions = new MessageQueue({ serializable: true });
        actions.on = handle_action;
        actions.finished = actions_finished_func;

        events = new PromiseQueue();
        events.set_handler(function(event :Event) {
            var promises :Array<Promise> = [];
            for (l in listeners) promises.push(l(event));
            return Promise.all(promises);
        });
    }

    public function load_map() {
        var map_radius :Int = 3;
        var mapHexes = MapFactory.create_hexagon_map(map_radius);
        mapHexes = mapHexes.filter(function(hex) {
            return (hex.key != '0,0' && hex.key != '-2,0' && hex.key != '2,0');
        });
        mapHexes.map(add_hex);
    }

    function add_hex(hex :Hex) {
        hexes.set(hex.key, hex);
        emit(HexAdded(hex));
    }

    public function has_hex(hex :Hex) {
        return hexes.exists(hex.key);
    }

    public function get_minion(hex :Hex) :MinionModel {
        for (m in minions) {
            if (m.hex.key == hex.key) return m;
        }
        return null;
    }

    public function add_minion(m :MinionModel) {
        minions.push(m);
        emit(MinionAdded(m));
    }

    public function remove_minion(m :MinionModel) {
        minions.remove(m);
        emit(MinionDied(m));
    }

    public function get_minions() :Array<MinionModel> {
        return minions;
    }

    public function replay() {
        // reset();
        actions.deserialize(actions.serialize());
    }

    public function do_action(action :Action) {
        actions.emit([action]);
    }

    function handle_action(action :Action) {
        trace('handle_action: $action');
        switch (action) {
            case MinionAction(model, action): handle_minion_action(model, action);
            case EndTurn: handle_start_turn();
        }
    }

    function handle_start_turn() {
        currentPlayerId = (currentPlayerId + 1) % 2;
        for (m in minions) {
            if (m.playerId != currentPlayerId) continue;
            m.actions = 1;
        }
        emit(TurnStarted(currentPlayerId));
    }

    function handle_minion_action(model :MinionModel, action :MinionAction) {
        switch (action) {
            case Move(hex): handle_move(model, hex);
            case Attack(defender): handle_attack(model, defender);
        }
    }

    function handle_move(model :MinionModel, hex :Hex) {
        trace('handle_move, modelId: ${model.id}, hex: ${hex.key}, is_walkable(${is_walkable(hex)})');
        //if (get_minion(hex) != null) throw 'Destination hex is already occupied!';
        var from = model.hex;
        model.hex = hex;
        emit(MinionMoved(model, from, hex));
    }

    function handle_attack(attacker :MinionModel, defender :MinionModel) {
        emit(MinionAttacked(attacker, defender));

        var minPower = Math.floor(Math.min(attacker.power, defender.power));
        defender.power -= minPower;
        emit(MinionDamaged(defender, minPower));

        attacker.power -= minPower;
        emit(MinionDamaged(attacker, minPower));

        if (defender.power <= 0) remove_minion(defender);
        if (attacker.power <= 0) remove_minion(attacker);
    }

    public function get_minion_moves(model :MinionModel) :Array<MinionAction> {
        return model.hex.ring(1).map(function(hex) {
            if (is_walkable(hex)) return Move(hex);
            return null;
        }).filter(function(action) { return (action != null); });
    }

    public function get_minion_attacks(model :MinionModel) :Array<MinionAction> {
        return model.hex.ring(1).map(function(hex) {
            var other = get_minion(hex);
            if (other != null && other.playerId != model.playerId) return Attack(other);
            return null;
        }).filter(function(action) { return (action != null); });
    }

    public function get_minion_actions(model :MinionModel) :Array<MinionAction> {
        return get_minion_attacks(model).concat(get_minion_moves(model));
    }

    function emit(event :Event) :Void {
        events.handle(event);
    }

    public function listen(func: EventListenerFunction) {
        listeners.add(func);
    }

    public function is_walkable(hex :Hex) {
        if (!has_hex(hex)) return false;
        if (get_minion(hex) != null) return false;
        return true;
    }

    public function get_path(start :Hex, end :Hex) :Array<Hex> {
        return start.find_path(end, 100, 6, is_walkable);
    }
}
