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

class MinionModel { // TODO: Make a hero type as well?
    static var Id :Int = 0;
    public var id :Int;
    public var title :String;
    public var playerId :Int;
    public var power :Int;
    public var hex :Hex;
    public var actions :Int;
    public var hero :Bool;

    public function new(title :String, playerId :Int, power :Int, hex :Hex, actions :Int = 1, hero :Bool = false, ?id :Int) {
        this.id = (id != null ? id : Id++);
        this.title = title;
        this.playerId = playerId;
        this.power = power;
        this.hex = hex;
        this.actions = actions;
        this.hero = hero;
    }

    public function clone() {
        return new MinionModel(title, playerId, power, hex, actions, hero, id);
    }
}

typedef EventListenerFunction = Event -> snow.api.Promise;

enum Action {
    MinionAction(modelId :Int, action :MinionAction);
    EndTurn();
}

enum MinionAction {
    Nothing;
    Move(hex :Hex);
    Attack(defenderModelId :Int);
}

enum Event {
    HexAdded(hex :Hex);
    MinionAdded(modelId :Int);
    MinionMoved(modelId :Int, from :Hex, to :Hex);
    MinionAttacked(attackerModelId :Int, defenderModelId :Int);
    MinionDamaged(modelId :Int, damage :Int);
    MinionDied(modelId :Int);
    TurnStarted(playerId :Int);
}

class BattleGameState {
    public var minions :Array<MinionModel>; // TODO: Make into a map<int, model>
    public var currentPlayerId :Int;
    public var random :luxe.utils.Random;

    public function new() {
        minions = [];
        currentPlayerId = 0;
        random = new luxe.utils.Random(42);
    }

    public function clone() :BattleGameState {
        var newGameState = new BattleGameState();
        newGameState.minions = [ for (model in minions) model.clone() ];
        newGameState.currentPlayerId = currentPlayerId;
        newGameState.random = new luxe.utils.Random(random.seed);
        return newGameState;
    }
}

class BattleModel {
    var hexes :Map<String, Hex>;
    var actions :MessageQueue<Action>;
    var events :PromiseQueue<Event>;
    var listeners :List<EventListenerFunction>;

    var state :BattleGameState;
    // var actions_finished_func :Void->Void;
    // public var actions_finished :Promise;

    public function new() {
        listeners = new List();
        // minions = [];
        hexes = new Map();

        state = new BattleGameState();


        // actions_finished = new Promise(function(resolve, reject) {
        //     actions_finished_func = resolve;
        // });

        actions = new MessageQueue({ serializable: true });
        actions.on = handle_action;
        // actions.finished = actions_finished_func;

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

    public function replay() {
        // reset();
        actions.deserialize(actions.serialize());
    }

    public function clone() :BattleModel {
        var newGameModel = new BattleModel();
        newGameModel.hexes = hexes;
        newGameModel.state = state.clone();
        return newGameModel;
    }

    function handle_action(action :Action) {
        trace('handle_action: $action');
        switch (action) {
        case MinionAction(modelId, action): handle_minion_action(modelId, action);
            case EndTurn: handle_start_turn();
        }
    }

    function handle_start_turn() {
        state.currentPlayerId = (state.currentPlayerId + 1) % 2;
        for (m in state.minions) {
            if (m.playerId != state.currentPlayerId) continue;
            m.actions = 1;
        }
        emit(TurnStarted(state.currentPlayerId));
    }

    function handle_minion_action(modelId :Int, action :MinionAction) {
        var model = get_minion_from_id(modelId);
        model.actions--;
        switch (action) {
            case Nothing: /* Do nothing */
            case Move(hex): handle_move(modelId, hex);
            case Attack(defenderId): handle_attack(modelId, defenderId);
        }
    }

    function handle_move(modelId :Int, hex :Hex) {
        // trace('handle_move, modelId: ${model.id}, hex: ${hex.key}, is_walkable(${is_walkable(hex)})');
        //if (get_minion(hex) != null) throw 'Destination hex is already occupied!';
        var model = get_minion_from_id(modelId);
        var from = model.hex;
        model.hex = hex;
        emit(MinionMoved(modelId, from, hex));
    }

    function handle_attack(attackerId :Int, defenderId :Int) {
        var attacker = get_minion_from_id(attackerId);
        var defender = get_minion_from_id(defenderId);
        emit(MinionAttacked(attackerId, defenderId));

        var minPower = Math.floor(Math.min(attacker.power, defender.power));
        defender.power -= minPower;
        emit(MinionDamaged(defenderId, minPower));

        attacker.power -= minPower;
        emit(MinionDamaged(attackerId, minPower));

        if (defender.power <= 0) remove_minion(defenderId);
        if (attacker.power <= 0) remove_minion(attackerId);
    }

    public function get_minion_moves(modelId :Int) :Array<MinionAction> {
        var model = get_minion_from_id(modelId);
        if (model.actions <= 0) return [];
        return model.hex.ring(1).map(function(hex) {
            if (is_walkable(hex)) return Move(hex);
            return null;
        }).filter(function(action) { return (action != null); });
    }

    public function get_minion_attacks(modelId :Int) :Array<MinionAction> {
        var model = get_minion_from_id(modelId);
        if (model.actions <= 0) return [];
        // trace('modelId: $modelId, model: $model');
        return model.hex.ring(1).map(function(hex) {
            var other = get_minion(hex);
            if (other != null && other.playerId != model.playerId) return Attack(other.id);
            return null;
        }).filter(function(action) { return (action != null); });
    }

    public function get_minion_actions(modelId :Int) :Array<MinionAction> {
        return get_minion_attacks(modelId).concat(get_minion_moves(modelId)).concat([Nothing]);
    }

    public function get_minion(hex :Hex) :MinionModel {
        for (m in state.minions) {
            if (m.hex.key == hex.key) return m;
        }
        return null;
    }

    public function add_hex(hex :Hex) {
        hexes.set(hex.key, hex);
        emit(HexAdded(hex));
    }

    public function has_hex(hex :Hex) {
        return hexes.exists(hex.key);
    }

    public function add_minion(minion :MinionModel) {
        state.minions.push(minion);
        emit(MinionAdded(minion.id));
    }

    public function remove_minion(minionId :Int) {
        state.minions.remove(get_minion_from_id(minionId));
        emit(MinionDied(minionId));
    }

    public function get_minions() :Array<MinionModel> {
        return state.minions;
    }

    public function get_minion_from_id(id :Int) :MinionModel {
        for (m in state.minions) {
            if (m.id == id) return m;
        }
        return null;
        // return minion from minion map

        // TODO: Consider a simpler solution that avoids cloning the game state altogether
    }

    public function emit(event :Event) :Void {
        events.handle(event);
    }

    public function is_walkable(hex :Hex) {
        if (!has_hex(hex)) return false;
        if (get_minion(hex) != null) return false;
        return true;
    }

    public function get_path(start :Hex, end :Hex) :Array<Hex> {
        return start.find_path(end, 100, 6, is_walkable);
    }

    public function do_action(action :Action) {
        actions.emit([action]);
    }

    public function listen(func: EventListenerFunction) {
        listeners.add(func);
    }
}
