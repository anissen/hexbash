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

    public function new(title :String, playerId :Int, power :Int, hex :Hex) {
        this.id = Id++;
        this.title = title;
        this.playerId = playerId;
        this.power = power;
        this.hex = hex;
    }
}

typedef EventListenerFunction = Event -> snow.api.Promise;

enum Action {
    Move(model :MinionModel, hex :Hex);
    Attack(attackerModel :MinionModel, defenderModel :MinionModel);
}

enum Event {
    HexAdded(hex :Hex);
    MinionAdded(model :MinionModel);
    MinionMoved(model :MinionModel, from :Hex, to :Hex);
    MinionAttacked(attackerModel :MinionModel, defenderModel :MinionModel);
    MinionDamaged(model :MinionModel, damage :Int);
    MinionDied(model :MinionModel);
}

class BattleModel {
    var actions :MessageQueue<Action>;
    var events :PromiseQueue<Event>;
    var hexes :Map<String, Hex>;
    var minions :Array<MinionModel>;
    var random :luxe.utils.Random;
    var listeners :List<EventListenerFunction>;

    public function new() {
        listeners = new List();
        random = new luxe.utils.Random(43);
        hexes = new Map();
        minions = [];

        actions = new MessageQueue({ serializable: true });
        actions.on = handle_action;

        events = new PromiseQueue();
        events.set_handler(function(event :Event) {
            var promises :Array<Promise> = [ for (l in listeners) l(event) ];
            return Promise.all(promises);
        });
    }

    public function load_map() {
        var map_radius :Int = 4;
        var tempHexes = MapFactory.create_hexagon_map(map_radius);
        for (hex in tempHexes) {
            if (random.get() < 0.7) add_hex(hex);
        }
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

    public function replay() {
        // reset();
        actions.deserialize(actions.serialize());
    }

    public function do_action(action :Action) {
        actions.emit([action]);
    }

    function handle_action(action :Action) {
        switch (action) {
            case Move(minion, hex): handle_move(minion, hex);
            case Attack(attacker, defender): handle_attack(attacker, defender);
        }
    }

    function handle_move(model :MinionModel, hex :Hex) {
        if (get_minion(hex) != null) throw 'Destination hex is already occupied!';
        var from = model.hex;
        model.hex = hex;
        emit(MinionMoved(model, from, hex));
    }

    function handle_attack(attacker :MinionModel, defender :MinionModel) {
        emit(MinionAttacked(attacker, defender));

        var minPower = Math.floor(Math.min(attacker.power, defender.power));
        defender.power -= minPower;
        emit(MinionDamaged(defender, minPower));

        emit(MinionAttacked(defender, attacker));

        attacker.power -= minPower;
        emit(MinionDamaged(attacker, minPower));

        if (defender.power <= 0) remove_minion(defender);
        if (attacker.power <= 0) remove_minion(attacker);
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
