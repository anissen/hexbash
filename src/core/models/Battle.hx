package core.models;

import core.Enums;
import core.models.Minion;
import core.MessageQueue;
import core.PromiseQueue;
import core.HexLibrary.Hex;
import snow.api.Promise;

using core.HexLibrary.HexTools;
using core.tools.ArrayTools;

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

    var player :Player;

    var game_over :Bool = false;

    public function new() {
        minions = new Map();
        // effects = new Map();
        currentPlayerId = 0;
        random = new luxe.utils.Random(42);

        player = Game.player;

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
        // var battle = core.factories.BattleFactory.Generate(seed);
        // battle.hexes.map(add_hex);
        for (m in minions) {
            emit(MinionAdded(m.id));
        }
    }

    public function start_game() {
        // draw cards for player
        handle_start_turn();
    }

    function discard_hand() {
        for (card in player.hand) {
            emit(CardDiscarded(card.id));
        }
        player.hand = [];
    }

    function draw_card(card :Card) {
        if (card != null) {
            player.hand.push(card);
            emit(CardDrawn(card.id));
        }
    }

    function draw_new_hand() {
        discard_hand();

        var hand_size = 3;
        var equipmentCards = player.get_cards_from_equipment();
        for (i in player.hand.length ... hand_size) {
            if (equipmentCards.length == 0) break;
            var card = equipmentCards.splice(0, 1)[0];
            draw_card(card);
        }

        for (i in player.hand.length ... hand_size) {
            var card = player.deck.pop();
            draw_card(card);
        }
    }

    public function replay() {
        // reset();
        actions.deserialize(actions.serialize());
    }

    function handle_action(action :Action) {
        if (game_over) return;
        switch (action) {
            case MinionAction(modelId, action): handle_minion_action(modelId, action);
            case PlayCard(cardId, target): handle_play_card(cardId, target);
            case DiscardCard(cardId): handle_discard_card(cardId);
            case EndTurn: handle_end_turn(); handle_start_turn();
        }
    }

    function handle_end_turn() {
        currentPlayerId = (currentPlayerId + 1) % 2;
        // // draw cards for player
        // draw_new_hand();
        // discard_hand();
    }

    function handle_start_turn() {
        for (m in minions) {
            if (m.playerId != currentPlayerId) continue;
            m.actions = 1;
        }
        emit(TurnStarted(currentPlayerId));
        if (currentPlayerId == 0) { // HACK
            draw_new_hand();
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
        player.hand.remove(card);
        // player.deck.unshift(card); // try adding played card back into deck as a mechanic
        switch (card.type) {
            // case Potion(power): handle_drink_potion(hero, power);
            case Minion(name, cost): handle_play_minion(hero, name, cost);
            // case Tower(name, cost, trigger, effect): handle_play_tower(hero, name, cost, trigger, effect);
            case Spell(effect, cost): handle_play_spell(effect, cost);
            case Curse(effect): handle_play_spell(effect, 0);
            case Attack(power): handle_play_attack(power, target);
        }

        if (player.hand.length == 0) {
            handle_action(EndTurn);
        }
    }

    function handle_discard_card(cardId :Int) {
        var card = get_card_from_id(cardId);

        player.hand.remove(card);
        switch (card.type) { // try adding discarded MINION and SPELL cards back into deck as a mechanic
            case Minion(_, _): player.deck.discard(card);
            default:
        }
        emit(CardDiscarded(cardId));

        // heal_minion(hero.id, 1); // Test: heal 1 when discarding

        if (player.hand.length == 0) {
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
        add_minion(core.factories.MinionFactory.Create(name, currentPlayerId, randomHex));
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
        var attackerId = hero.id;
        var defenderId = get_minion(target).id;

        emit(MinionAttacked(attackerId, defenderId));

        damage_minion(defenderId, power);
    }

    public function add_hex(hex :Hex) {
        hexes.set(hex.key, hex);
        emit(HexAdded(hex));
    }

    public function add_minion(minion :Minion) {
        minions[minion.id] = minion;
        if (minion.hero && minion.playerId == 0) hero = minion; // GIANT HACK!
        emit(MinionAdded(minion.id));
    }

    function emit(event :Event) :Void {
        events.handle(event);
        // for (eff in effects) {
        //     if (eff.trigger(this, event)) {
        //         trace('TRIGGERED! ($event)');
        //         var commands = eff.effect(this);
        //         for (command in commands) {
        //             trace('effect: $command');
        //             do_command(command);
        //         }
        //     }
        // }
    }

    function do_command(command :Command) :Void {
        switch (command) {
            case DamageMinion(modelId, amount): damage_minion(modelId, amount);
            case HealMinion(modelId, amount): heal_minion(modelId, amount);
            case MoveMinion(modelId, hex): handle_move(modelId, hex);
        }
    }

    function kill_minion(modelId :Int) {
        var minion = get_minion_from_id(modelId);
        minions.remove(modelId);

        // effects.remove('tower_${modelId}'); // HACK HACK HACK!!!

        emit(MinionDied(modelId));

        if (minion.hero) end_game(minion.playerId != 0); // GIANT HACK:

        if (minion.playerId != 0) player.equipment.push(new core.models.Equipment.CursedSword()); // Test
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

    function end_game(won :Bool) {
        game_over = true;

        // Drain life from minions
        for (minion in get_minions()) {
            if (minion.playerId == 0 && minion.id != hero.id) {
                kill_minion(minion.id);
                heal_minion(hero.id, 1);
            }
        }

        player.life = hero.power;

        // Put unused cards back into the deck
        for (card in player.hand) {
            switch (card.type) {
                case Minion(_): player.deck.add(card);
                case Spell(_): player.deck.add(card);
                default: // Don't add attack and curse cards
            }
        }
        player.hand = [];

        emit(won ? GameWon : GameLost);
    }



    // TODO: Move the following functions elsewhere!

    public function get_current_player() :Int {
        return currentPlayerId;
    }

    public function get_current_hero() :Minion {
        return hero;
    }

    public function get_minion_from_id(id :Int) :Minion {
        return minions[id];
    }

    public function get_deck_size() {
        return player.deck.count();
    }

    public function get_targets_for_card(cardId :Int) :Array<Hex> {
        var card = get_card_from_id(cardId);
        if (card == null) return [];
        return switch (card.type) {
            case Minion(_, _):
                hero.hex.ring(1).map(function(hex) {
                    if (!has_hex(hex)) return null;
                    if (get_minion(hex) != null) return null;
                    return hex;
                }).filter(function(hex) { return (hex != null); });
            case Attack(_):
                // var hero = get_hero(get_current_player());
                hero.hex.ring(1).map(function(hex) {
                    var other = get_minion(hex);
                    if (other == null || other.playerId == hero.playerId) return null;
                    return hex;
                }).filter(function(hex) { return (hex != null); });
            case Curse(_): [hero.hex];
            default: [];
        };
    }

    public function get_random() :luxe.utils.Random {
        return random;
    }

    public function get_minion_moves(modelId :Int) :Array<MinionAction> {
        var model = get_minion_from_id(modelId);
        if (model.actions <= 0) return [];
        var targets = switch (model.movement) {
            case Freely(range): model.hex.range(range);
            case Jump(range): model.hex.ring(range);
        }
        return targets.map(function(hex) {
            if (is_walkable(hex)) return Move(hex);
            return null;
        }).filter(function(action) { return (action != null); });
    }

    public function get_minion_attacks(modelId :Int) :Array<MinionAction> {
        var model = get_minion_from_id(modelId);
        if (model.actions <= 0) return [];
        if (model.id == hero.id) return []; // Hero cannot attack normally
        // if (model.hero) return []; // Test mechanic: Heroes cannot attack but has to use cards to deal damage
        return model.hex.range(model.range).map(function(hex) {
            var other = get_minion(hex);
            if (other != null && other.playerId != model.playerId) return core.MinionAction.Attack(other.id);
            return null;
        }).filter(function(action) { return (action != null); });
    }

    public function get_minion_actions(modelId :Int) :Array<MinionAction> {
        return get_minion_attacks(modelId).concat(get_minion_moves(modelId)).concat([Nothing]);
    }

    public function get_minion(hex :Hex) :Minion {
        for (m in minions) {
            if (m.hex.key == hex.key) return m;
        }
        return null;
    }

    // public function get_card_cost(cardId :Int) :Int {
    //     var card = get_card_from_id(cardId);
    //     return switch (card.type) {
    //         case Minion(_, cost): cost;
    //         // case Tower(_, cost, _, _): cost;
    //         // case Potion(power): power;
    //         case Spell(_, cost): cost;
    //         case Attack(_): 0;
    //     }
    // }

    public function can_play_card(cardId :Int) :Bool {
        var card = get_card_from_id(cardId);
        return (card.cost < hero.power);
    }

    public function has_hex(hex :Hex) {
        return hexes.exists(hex.key);
    }

    public function get_minions() :Array<Minion> {
        return [ for (m in minions) m ];
    }

    public function get_card_from_id(id :Int) :Card {
        for (c in player.hand) { // HACK
            if (c.id == id) return c;
        }
        return null;
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
