package core;

import core.models.Battle;
import core.HexLibrary.Hex;
import snow.api.Promise;

enum CardType {
    // TODO: Remove arguments, or maybe simplify to only one argument, e.g. Minion(MinionData) where MinionData = { name, cost } or enum MinionData { NormalMinion(name, cost); SuperMinion(x) };
    Minion(name :String);
    // Tower(name :String, cost :Int, trigger :Battle->Event->Bool, effect :Battle->Array<Command>);
    // Potion(power :Int);
    Spell(effect :Battle->Array<Command>, cost :Int);
    Attack(power :Int);
    Curse(effect :Battle->Array<Command>);
}

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
