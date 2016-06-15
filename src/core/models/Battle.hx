package core.models;

import core.Models;
import core.MessageQueue;
import core.PromiseQueue;
import core.HexLibrary.Hex;
import snow.api.Promise;

class Battle {
    var hero :Minion;

    var minions :Map<Int, Minion>;
    // var effects :Map<String, { trigger :Battle->Event->Bool, effect :Battle->Array<Command> }>;
    var currentPlayerId :Int;
    var random :luxe.utils.Random;

    var hexes :Map<String, Hex>;
    var actions :MessageQueue<Action>;
    var events :PromiseQueue<Event>;
    var listeners :List<EventListenerFunction>;

    public function new() {
        minions = new Map();
        // effects = new Map();
        currentPlayerId = 0;
        random = new luxe.utils.Random(42);

        listeners = new List();
        hexes = new Map();

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
        var battle = core.factories.BattleFactory.Generate(seed);
        battle.hexes.map(add_hex);
        minions.map(function(m) { emit(MinionAdded(m.id)); });
    }

    public function start_game() {
        // draw cards for player
        draw_new_hand();
    }

    function discard_hand() {
        for (card in playerHand) {
            emit(CardDiscarded(card.id));
        }
        playerHand = [];
    }

    function draw_card() {
        var card = playerDeck.pop();
        if (card != null) {
            playerHand.push(card);
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
        currentPlayerId = (currentPlayerId + 1) % 2;
        for (m in minions) {
            if (m.playerId != currentPlayerId) continue;
            m.actions = 1;
        }
        emit(TurnStarted(currentPlayerId));
        if (currentPlayerId == 0) { // HACK
            // draw_card();
            // draw_new_hand();
            for (i in 0 ... (3 - playerHand.length)) { // draw so that hand has 3 cards
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
        var card = get_card_from_id(cardId);

        emit(CardPlayed(cardId));
        playerHand.remove(card);
        // playerDeck.unshift(card); // try adding played card back into deck as a mechanic
        switch (card.cardType) {
            // case Potion(power): handle_drink_potion(hero, power);
            case Minion(name, cost): handle_play_minion(hero, name, cost);
            // case Tower(name, cost, trigger, effect): handle_play_tower(hero, name, cost, trigger, effect);
            // case Spell(effect, cost): handle_play_spell(effect, cost);
            case Attack(power): handle_play_attack(power, target);
        }

        if (playerHand.length == 0) {
            handle_action(EndTurn);
        }
    }

    function handle_discard_card(cardId :Int) {
        var card = get_card_from_id(cardId);

        playerHand.remove(card);
        playerDeck.unshift(card); // try adding discarded card back into deck as a mechanic
        emit(CardDiscarded(cardId));

        // heal_minion(hero.id, 1); // Test: heal 1 when discarding

        if (playerHand.length == 0) {
            handle_action(EndTurn);
        }
    }

    // function handle_drink_potion(hero :Minion, power :Int) {
    //     heal_minion(hero.id, power);
    // }

    function handle_play_minion(hero :Minion, name :String, cost :Int) {
        damage_minion(hero.id, cost);
        if (hero.power <= 0) return;

        var nearbyHexes = hero.hex.reachable(is_walkable);
        if (nearbyHexes.length == 0) return; // should not happen
        var randomHex = nearbyHexes.random(function(v :Int) { return random.int(v); });
        add_minion(new Minion(name, 0, cost, randomHex, 'spider-alt.png'));
    }

    // function handle_play_tower(hero :Minion, name :String, cost :Int, trigger, effect) {
    //     damage_minion(hero.id, cost);
    //     if (hero.power <= 0) return;
    //
    //     var nearbyHexes = hero.hex.reachable(is_walkable);
    //     if (nearbyHexes.length == 0) return; // should not happen
    //     var randomHex = nearbyHexes.random(function(v :Int) { return random.int(v); });
    //
    //     var tower = new TowerModel(name, 0, cost, randomHex, 'wolf-head.png');
    //     var effect_key = 'tower_${tower.id}';
    //     effects[effect_key] = { trigger: trigger, effect: effect };
    //     add_minion(tower);
    // }

    function handle_play_spell(effect :Battle->Array<Command>, cost :Int) {
        damage_minion(hero.id, cost);
        if (hero.power <= 0) return;

        var commands = effect(this);
        for (command in commands) {
            do_command(command);
        }
    }

    function handle_play_attack(power :Int, target :Hex) {
        var minionId = get_minion(target).id;
        handle_attack(hero.id, minionId);
    }

    public function add_hex(hex :Hex) {
        hexes.set(hex.key, hex);
        emit(HexAdded(hex));
    }

    public function add_minion(minion :Minion) {
        minions.push(minion);
        emit(MinionAdded(minion.id));
    }

    public function add_card_to_deck(card :Card) {
        playerDeck.push(card);
    }

    function emit(event :Event) :Void {
        events.handle(event);
        for (eff in effects) {
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
        minions.remove(get_minion_from_id(modelId));

        // effects.remove('tower_${modelId}'); // HACK HACK HACK!!!

        emit(MinionDied(modelId));

        emit(GameWon); // TODO: Missing GameLost handling
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

    public function do_action(action :Action) {
        actions.emit([action]);
    }

    public function listen(func: EventListenerFunction) {
        listeners.add(func);
    }



    public function get_minion_from_id(id :Int) :Minion {
        return minions[id];
    }
}
