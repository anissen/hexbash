package core.factories;

import core.models.Minion;
import core.HexLibrary.Hex;

typedef AbilitiesData = {
    @:optional var jump :Int;
    @:optional var range :Int;
    @:optional var haste :Bool;
}

typedef MinionData = {
    var name :String;
    var identifier :String;
    var icon :String;
    var power :Int;
    // var abilities :Array<{ key :String, value :Int }>;
    var abilities :AbilitiesData;
    @:optional var hero :Bool;
};

class MinionFactory {
    static var minion_database :Map<String, MinionData>;

    static public function Initialize(minionDatabase :Array<MinionData>) {
        minion_database = new Map();

        for (m in minionDatabase) {
            minion_database[m.identifier] = m;
        }
    }

    static public function GetData(identifier :String) :MinionData {
        if (minion_database == null) throw 'Minion database not initialized!';
        return minion_database[identifier];
    }

    static public function Create(identifier :String, playerId :Int, hex :Hex) :Minion {
        var data = GetData(identifier);
        var minion = new Minion(data.name, playerId, data.power, hex, data.icon, (data.hero != null ? data.hero : false));

        if (data.abilities != null) {
            if (data.abilities.jump != null) {
                minion.movement = Jump(data.abilities.jump);
            }
            if (data.abilities.range != null) {
                minion.range = data.abilities.range;
            }
            if (data.abilities.haste != null && data.abilities.haste) {
                minion.actions = 1;
            }
        }
        // for (ability in data.abilities) {
        //     switch (ability) {
        //         case { key: 'jump', value: x }: minion.movement = Jump(x); trace('Jump $x!!');
        //         default: trace('Unmatched ability "${ability}"');
        //     }
        // }
        return minion;
    }
}
