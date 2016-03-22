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
    public var actions :Int; // Actions should be :Array<Action>, where Action := Move | Attack | Any, e.g. actions = [ Move, Move, Attack ]
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

    public function clone() :MinionModel {
        return new MinionModel(title, playerId, power, hex, actions, hero, id);
    }
}

class HeroModel extends MinionModel {
    public var max_power :Int;

    public function new(title :String, playerId :Int, power :Int, hex :Hex, actions :Int = 1, hero :Bool = false, ?id :Int) {
        super(title, playerId, power, hex, actions, true, id);
    }

    override public function clone() :HeroModel {
        return new HeroModel(title, playerId, power, hex, actions, hero, id);
    }
}

enum CardType {
    Minion(name :String, cost :Int);
    Potion(power :Int);
    Spell(effect :BattleModel->Array<Command>, cost :Int);
}

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
    PlayCard(cardId :Int);
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

class BattleGameState {
    public var minions :Array<MinionModel>; // TODO: Make into a map<int, model>
    public var currentPlayerId :Int;
    public var random :luxe.utils.Random;

    public var playerDeck :Array<CardModel>;
    public var playerHand :Array<CardModel>;

    public function new() {
        minions = [];
        playerDeck = [];
        playerHand = [];
        currentPlayerId = 0;
        random = new luxe.utils.Random(42);
    }

    public function clone() :BattleGameState {
        var newGameState = new BattleGameState();
        newGameState.minions = [ for (model in minions) model.clone() ];
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
            case PlayCard(cardId): handle_play_card(cardId);
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
        if (get_minion(hex) != null) throw 'Destination hex is already occupied!';
        var model = get_minion_from_id(modelId);
        var from = model.hex;
        model.hex = hex;
        emit(MinionMoved(modelId, from, hex));
    }

    function handle_attack(attackerId :Int, defenderId :Int) {
        var attacker = get_minion_from_id(attackerId);
        var defender = get_minion_from_id(defenderId);

        emit(MinionAttacked(attackerId, defenderId));

        damage_minion(defenderId, attacker.power);
    }

    function handle_play_card(cardId :Int) {
        var hero = get_hero(state.currentPlayerId);
        var card = get_card_from_id(cardId);

        emit(CardPlayed(cardId));
        state.playerHand.remove(card);
        state.playerDeck.unshift(card); // try adding played card back into deck as a mechanic
        switch (card.cardType) {
            case Potion(power): handle_drink_potion(hero, power);
            case Minion(name, cost): handle_play_minion(hero, name, cost);
            case Spell(effect, cost): handle_play_spell(effect, cost);
        }

        if (state.playerHand.length == 0) {
            handle_action(EndTurn);
        }
    }

    function handle_discard_card(cardId :Int) {
        var card = get_card_from_id(cardId);

        emit(CardDiscarded(cardId));
        state.playerHand.remove(card);

        var hero = get_hero(get_current_player());
        heal_minion(hero.id, 1); // Test: heal 1 when discarding

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
        add_minion(new MinionModel(name, 0, cost, randomHex));
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

    function get_hero(playerId :Int) :HeroModel { // HACK, should be a property of player
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
    }

    function do_command(command :Command) :Void {
        switch (command) {
            case DamageMinion(modelId, amount): damage_minion(modelId, amount);
            case HealMinion(modelId, amount): heal_minion(modelId, amount);
        }
    }

    function damage_minion(modelId :Int, amount :Int) {
        var model = get_minion_from_id(modelId);
        model.power -= amount;
        emit(MinionDamaged(modelId, amount));
        if (model.power <= 0) {
            state.minions.remove(get_minion_from_id(modelId));
            emit(MinionDied(modelId));

            if (get_hero(1 /* hack */) == null) {
                emit(GameWon);
            } else if (get_hero(0 /* hack */) == null) {
                emit(GameLost);
            }
        }
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
