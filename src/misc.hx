public function get_deck_size() {
    return playerDeck.length;
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

public function get_random() :luxe.utils.Random {
    return random;
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
    for (m in minions) {
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

public function has_hex(hex :Hex) {
    return hexes.exists(hex.key);
}

public function get_minions() :Array<MinionModel> {
    return minions;
}

public function get_card_from_id(id :Int) :CardModel {
    for (c in playerHand) { // HACK
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
