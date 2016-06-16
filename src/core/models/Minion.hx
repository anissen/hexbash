package core.models;

import core.HexLibrary.Hex;

class Minion {
    public var playerId :Int;
    public var power :Int;
    public var hex :Hex;
    public var icon :String;
    public var actions :Int;
    public var id :Int;
    static var Id :Int = 0;

    public function new(name :String, playerId :Int, power :Int, hex :Hex, icon :String) { // TEMP! Replace with @:structInit
        this.playerId = playerId;
        this.power = power;
        this.hex = hex;
        this.icon = icon;
        this.id = Id++;
    }
}
