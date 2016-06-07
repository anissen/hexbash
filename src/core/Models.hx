package core;

import snow.api.Promise;
import core.HexLibrary;
using core.HexLibrary.HexTools;
using core.ArrayTools;

class MinionModel { // TODO: Make a hero type as well?
    static var Id :Int = 0;
    public var id :Int;
    public var title :String;
    public var playerId :Int;
    public var power :Int;
    public var hex :Hex;
    public var icon :String;
    @:isVar public var actions(get, set) :Int; // Actions should be :Array<Action>, where Action := Move | Attack | Any, e.g. actions = [ Move, Move, Attack ]
    public var hero :Bool;

    public function new(title :String, playerId :Int, power :Int, hex :Hex, icon :String, actions :Int = 1, hero :Bool = false, ?id :Int) {
        this.id = (id != null ? id : Id++);
        this.title = title;
        this.playerId = playerId;
        this.power = power;
        this.hex = hex;
        this.icon = icon;
        this.actions = actions;
        this.hero = hero;
    }

    function get_actions() {
        return actions;
    }

    function set_actions(a :Int) {
        return (actions = a);
    }

    public function clone() :MinionModel {
        return new MinionModel(title, playerId, power, hex, icon, actions, hero, id);
    }
}

class HeroModel extends MinionModel {
    public var max_power :Int;

    public function new(title :String, playerId :Int, power :Int, hex :Hex, icon :String, actions :Int = 1, hero :Bool = false, ?id :Int) {
        super(title, playerId, power, hex, icon, actions, true, id);
    }

    override public function clone() :HeroModel {
        return new HeroModel(title, playerId, power, hex, icon, actions, hero, id);
    }
}

class TowerModel extends MinionModel {
    public function new(title :String, playerId :Int, power :Int, hex :Hex, icon :String, actions :Int = 1, hero :Bool = false, ?id :Int) {
        super(title, playerId, power, hex, icon, actions, false, id);
    }

    override function get_actions() {
        return 0; // tower never has actions
    }

    override public function clone() :TowerModel {
        return new TowerModel(title, playerId, power, hex, icon, actions, hero, id);
    }
}

enum CardType {
    Minion(name :String, cost :Int);
    Tower(name :String, cost :Int, trigger :BattleModel->Event->Bool, effect :BattleModel->Array<Command>);
    Potion(power :Int);
    Spell(effect :BattleModel->Array<Command>, cost :Int);
    Attack(power :Int);
}

// enum PlayCard {
//     Minion(name :String, cost :Int, tile :Hex);
//     Tower(name :String, cost :Int, tile :Hex);
//     Potion(power :Int);
//     Spell(effect :BattleModel->Array<Command>, cost :Int);
//     Attack(power :Int);
// }

class CardModel {
    static var Id :Int = 0;
    public var id :Int;
    public var title :String;
    public var playerId :Int;
    public var cardType :CardType;

    public function new(title :String, playerId :Int, cardType :CardType, ?id :Int) {
        this.id = (id != null ? id : Id++);
        this.title = title;
        this.playerId = playerId;
        this.cardType = cardType;
    }

    public function clone() :CardModel {
        return new CardModel(title, playerId, cardType, id);
    }
}

// class PlayerModel {
//     static var Id :Int = 0;
//     public var id :Int;
//     public var ai :Bool;
//     // public var hero :MinionModel;
//     public var deck :Array<CardModel>;
//     public var hand :Array<CardModel>;
//
//     public function new(ai :Bool = true, ?deck :Array<CardModel>, ?hand :Array<CardModel>, ?id :Int) {
//         this.id = (id != null ? id : Id++);
//         this.ai = ai;
//         this.deck = (deck != null ? deck : []);
//         this.hand = (hand != null ? hand : []);
//     }
//
//     public function clone() :CardModel {
//         return new PlayerModel(ai, deck, hand, id);
//     }
// }

typedef EventListenerFunction = Event -> snow.api.Promise;

enum Action {
    MinionAction(modelId :Int, action :MinionAction);
    PlayCard(cardId :Int, ?target :Hex);
    DiscardCard(cardId :Int);
    EndTurn();
}

enum MinionAction {
    Nothing;
    Move(hex :Hex);
    Attack(defenderModelId :Int);
}

enum Command {
    DamageMinion(modelId :Int, amount :Int);
    HealMinion(modelId :Int, amount :Int);
    MoveMinion(modelId :Int, hex :Hex);
}

enum Event {
    HexAdded(hex :Hex);
    MinionAdded(modelId :Int);
    MinionMoved(modelId :Int, from :Hex, to :Hex);
    MinionAttacked(attackerModelId :Int, defenderModelId :Int);
    MinionDamaged(modelId :Int, amount :Int);
    MinionHealed(modelId :Int, amount :Int);
    MinionDied(modelId :Int);
    TurnStarted(playerId :Int);
    CardPlayed(cardId :Int);
    CardDiscarded(cardId :Int);
    CardDrawn(cardId :Int);
    GameWon();
    GameLost();
}

// enum CardTarget {
//     Global;
//     Hex(hex :Hex);
// }

// class Player {
//     public var deck :Array<CardModel>;
//     public var life :Int;
//
//     public function new() {
//         deck = [];
//         life = 10;
//     }
// }

class BattleGameState {
    public var minions :Array<MinionModel>; // TODO: Make into a map<int, model>
    public var effects :Map<String, { trigger :BattleModel->Event->Bool, effect :BattleModel->Array<Command> }>;
    public var currentPlayerId :Int;
    public var random :luxe.utils.Random;

    public var playerDeck :Array<CardModel>;
    public var playerHand :Array<CardModel>;

    public function new() {
        minions = [];
        effects = new Map();
        playerDeck = [];
        playerHand = [];
        currentPlayerId = 0;
        random = new luxe.utils.Random(42);
    }

    public function clone() :BattleGameState {
        var newGameState = new BattleGameState();
        newGameState.minions = [ for (model in minions) model.clone() ];
        newGameState.effects = this.effects; // enough??
        newGameState.playerDeck = [ for (card in playerDeck) card.clone() ];
        newGameState.playerHand = [ for (card in playerHand) card.clone() ];
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

    public function new() {
        listeners = new List();
        hexes = new Map();
        state = new BattleGameState();

        actions = new MessageQueue({ serializable: true });
        actions.on = handle_action;

        events = new PromiseQueue();
        events.set_handler(function(event :Event) {
            var promises :Array<Promise> = [];
            for (l in listeners) promises.push(l(event));
            return Promise.all(promises);
        });
    }

    public function load_map(seed :Float) {
        var battle = BattleFactory.Generate(seed);
        battle.hexes.map(add_hex);
        state = battle.gameState;
        state.minions.map(function(m) { emit(MinionAdded(m.id)); });
    }

    public function start_game() {
        // draw cards for player
        draw_new_hand();
    }

    function discard_hand() {
        for (card in state.playerHand) {
            emit(CardDiscarded(card.id));
        }
        state.playerHand = [];
    }

    function draw_card() {
        var card = state.playerDeck.pop();
        if (card != null) {
            state.playerHand.push(card);
            emit(CardDrawn(card.id));
        }
    }

    public function get_deck_size() {
        return state.playerDeck.length;
    }

    function draw_new_hand() {
        discard_hand();

        var hand_size = 3;
        for (i in 0 ... hand_size) {
            draw_card();
        }
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
        switch (action) {
            case MinionAction(modelId, action): handle_minion_action(modelId, action);
            case PlayCard(cardId, target): handle_play_card(cardId, target);
            case DiscardCard(cardId): handle_discard_card(cardId);
            case EndTurn: handle_end_turn(); handle_start_turn();
        }
    }

    function handle_end_turn() {
        // // draw cards for player
        // draw_new_hand();
        // discard_hand();
    }

    function handle_start_turn() {
        state.currentPlayerId = (state.currentPlayerId + 1) % 2;
        for (m in state.minions) {
            if (m.playerId != state.currentPlayerId) continue;
            m.actions = 1;
        }
        emit(TurnStarted(state.currentPlayerId));
        if (state.currentPlayerId == 0) { // HACK
            // draw_card();
            // draw_new_hand();
            for (i in 0 ... (3 - state.playerHand.length)) { // draw so that hand has 3 cards
                draw_card();
            }
        }
    }

    function handle_minion_action(modelId :Int, action :MinionAction) {
        var model = get_minion_from_id(modelId);
        if (model.actions > 0) {
            model.actions--;
        } else {
            return;
            // damage_minion(modelId, 1); // Test; penalty for minions doing multiple actions per turn
            // if (model.power <= 0) return;
        }
        switch (action) {
            case Nothing: /* Do nothing */
            case Move(hex): handle_move(modelId, hex);
            case Attack(defenderId): handle_attack(modelId, defenderId);
        }
    }

    function handle_move(modelId :Int, hex :Hex) {
        // if (get_minion(hex) != null) throw 'Destination hex is already occupied!';
        var model = get_minion_from_id(modelId);
        var from = model.hex;
        model.hex = hex;
        emit(MinionMoved(modelId, from, hex));
        if (!has_hex(hex)) kill_minion(modelId);
    }

    function handle_attack(attackerId :Int, defenderId :Int) {
        var attacker = get_minion_from_id(attackerId);
        var defender = get_minion_from_id(defenderId);

        emit(MinionAttacked(attackerId, defenderId));

        damage_minion(defenderId, attacker.power);
    }

    function handle_play_card(cardId :Int, ?target :Hex) {
        var hero = get_hero(state.currentPlayerId);
        var card = get_card_from_id(cardId);

        emit(CardPlayed(cardId));
        state.playerHand.remove(card);
        // state.playerDeck.unshift(card); // try adding played card back into deck as a mechanic
        switch (card.cardType) {
            case Potion(power): handle_drink_potion(hero, power);
            case Minion(name, cost): handle_play_minion(hero, name, cost);
            case Tower(name, cost, trigger, effect): handle_play_tower(hero, name, cost, trigger, effect);
            case Spell(effect, cost): handle_play_spell(effect, cost);
            case Attack(power): handle_play_attack(power, target);
        }

        if (state.playerHand.length == 0) {
            handle_action(EndTurn);
        }
    }

    function handle_discard_card(cardId :Int) {
        var card = get_card_from_id(cardId);

        state.playerHand.remove(card);
        state.playerDeck.unshift(card); // try adding discarded card back into deck as a mechanic
        emit(CardDiscarded(cardId));

        // var hero = get_hero(get_current_player());
        // heal_minion(hero.id, 1); // Test: heal 1 when discarding

        if (state.playerHand.length == 0) {
            handle_action(EndTurn);
        }
    }

    function handle_drink_potion(hero :MinionModel, power :Int) {
        heal_minion(hero.id, power);
    }

    function handle_play_minion(hero :MinionModel, name :String, cost :Int) {
        damage_minion(hero.id, cost);
        if (hero.power <= 0) return;

        var nearbyHexes = hero.hex.reachable(is_walkable);
        if (nearbyHexes.length == 0) return; // should not happen
        var randomHex = nearbyHexes.random(function(v :Int) { return state.random.int(v); });
        add_minion(new MinionModel(name, 0, cost, randomHex, 'spider-alt.png'));
    }

    function handle_play_tower(hero :MinionModel, name :String, cost :Int, trigger, effect) {
        damage_minion(hero.id, cost);
        if (hero.power <= 0) return;

        var nearbyHexes = hero.hex.reachable(is_walkable);
        if (nearbyHexes.length == 0) return; // should not happen
        var randomHex = nearbyHexes.random(function(v :Int) { return state.random.int(v); });

        var tower = new TowerModel(name, 0, cost, randomHex, 'wolf-head.png');
        var effect_key = 'tower_${tower.id}';
        state.effects[effect_key] = { trigger: trigger, effect: effect };
        add_minion(tower);
    }

    function handle_play_spell(effect :BattleModel->Array<Command>, cost :Int) {
        var hero = get_hero(get_current_player());
        damage_minion(hero.id, cost);
        if (hero.power <= 0) return;

        var commands = effect(this);
        for (command in commands) {
            do_command(command);
        }
    }

    function handle_play_attack(power :Int, target :Hex) {
        var hero = get_hero(get_current_player());
        var minionId = get_minion(target).id;
        handle_attack(hero.id, minionId);
    }

    public function get_targets_for_card(cardId :Int) :Array<Hex> {
        var card = get_card_from_id(cardId);
        return switch (card.cardType) {
            case Attack(_):
                var hero = get_hero(get_current_player());
                hero.hex.ring(1).map(function(hex) {
                    var other = get_minion(hex);
                    if (other != null && other.playerId != hero.playerId) return hex;
                    return null;
                }).filter(function(hex) { return (hex != null); });
            default: [];
        };
    }

    public function get_hero(playerId :Int) :HeroModel { // HACK, should be a property of player
        for (model in state.minions) {
            if (model.playerId == playerId && model.hero) return cast model;
        }
        return null;
    }

    public function get_random() :luxe.utils.Random {
        return state.random;
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
        // if (model.hero) return []; // Test mechanic: Heroes cannot attack but has to use cards to deal damage
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

    public function get_card_cost(cardId :Int) :Int {
        var card = get_card_from_id(cardId);
        return switch (card.cardType) {
            case Minion(_, cost): cost;
            case Tower(_, cost, _, _): cost;
            case Potion(power): power;
            case Spell(_, cost): cost;
            case Attack(_): 0;
        }
    }

    public function can_play_card(cardId :Int) :Bool {
        var card = get_card_from_id(cardId);
        var cost = switch (card.cardType) {
            case Minion(_, cost): cost;
            case Tower(_, cost, _, _): cost;
            case Potion(power): -power; // heals
            case Spell(_, cost): cost;
            case Attack(_): 0;
        };
        var hero = get_hero(get_current_player());
        return (cost < hero.power);
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

    public function add_card_to_deck(card :CardModel) {
        state.playerDeck.push(card);
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
    }

    public function get_card_from_id(id :Int) :CardModel {
        for (c in state.playerHand) { // HACK
            if (c.id == id) return c;
        }
        return null;
    }

    public function get_current_player() :Int {
        return state.currentPlayerId;
    }

    function emit(event :Event) :Void {
        events.handle(event);
        for (eff in state.effects) {
            if (eff.trigger(this, event)) {
                trace('TRIGGERED! ($event)');
                var commands = eff.effect(this);
                for (command in commands) {
                    trace('effect: $command');
                    do_command(command);
                }
            }
        }
    }

    function do_command(command :Command) :Void {
        switch (command) {
            case DamageMinion(modelId, amount): damage_minion(modelId, amount);
            case HealMinion(modelId, amount): heal_minion(modelId, amount);
            case MoveMinion(modelId, hex): handle_move(modelId, hex);
        }
    }

    function kill_minion(modelId :Int) {
        state.minions.remove(get_minion_from_id(modelId));


        state.effects.remove('tower_${modelId}'); // HACK HACK HACK!!!


        emit(MinionDied(modelId));

        if (get_hero(1 /* hack */) == null) {
            emit(GameWon);
        } else if (get_hero(0 /* hack */) == null) {
            emit(GameLost);
        }
    }

    function damage_minion(modelId :Int, amount :Int) {
        if (amount <= 0) return;
        var model = get_minion_from_id(modelId);
        model.power -= amount;
        emit(MinionDamaged(modelId, amount));
        if (model.power <= 0) kill_minion(modelId);
    }

    function heal_minion(modelId :Int, amount :Int) {
        var model = get_minion_from_id(modelId);
        model.power += amount;
        emit(MinionHealed(modelId, amount));
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
