package core.models;

import core.HexLibrary.Hex;

enum MinionMovement {
    Freely(range :Int);
    Jump(range :Int);
}

class Minion {
    public var playerId :Int;
    public var power :Int;
    public var hex :Hex;
    public var icon :String;
    public var actions :Int;
    public var hero :Bool;
    public var range :Int;
    public var movement :MinionMovement;
    public var id :Int;
    static var Id :Int = 0;

    public function new(name :String, playerId :Int, power :Int, hex :Hex, icon :String, hero :Bool, range :Int = 1, ?movement :MinionMovement) { // TEMP! Replace with @:structInit
        this.playerId = playerId;
        this.power = power;
        this.hex = hex;
        this.icon = icon;
        this.actions = 0;
        this.hero = hero;
        this.range = range;
        this.movement = (movement != null ? movement : Freely(1));
        this.id = Id++;
    }
}
