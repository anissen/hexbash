package core.factories;

import generativegrammar.Generator;
using generativegrammar.TreeTools;

// typedef EnemyData = {
//     var identifier :String;
//     var icon :String;
//     var speed :Float;
//     var idle :Float;
//     var chase_tiles :Int;
// };

enum EquipmentType {
    Weapon;
}

class EquipmentFactory {
    static var generator = new Generator();

    static public function Initialize(equipmentGrammar :String) {
        generator = new Generator();
        generator.add_rules(equipmentGrammar);
    }

    static public function Create(equipmentType :EquipmentType, level :Int) :core.models.Equipment.CardProvider {
        var typeString = switch (equipmentType) {
            case Weapon: 'Weapon';
        };
        var terminals = generator.generate('${typeString}_level${level}').leafs();
        var attributes = [ for (t in terminals) terminal_to_attribute(t) ];
        return new core.models.Equipment.CustomWeapon(attributes);
    }

    static function terminal_to_attribute(terminal :String) {
        return switch (terminal) {
            case 'damage_small': core.models.Equipment.WeaponAbilityType.Damage(1);
            case 'damage_medium': core.models.Equipment.WeaponAbilityType.Damage(2);
            case 'curse': core.models.Equipment.WeaponAbilityType.Curse;
            case _: throw 'Unhandled case!';
        };
    }

    // static function generate(symbol :String) :Array<String> {
    //     return generator.generate(symbol).leafs();
    // }
}
