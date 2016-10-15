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
        // // code to set maximum 1 special attribute:
        // var has_special = false;
        // generator.set_validation(function(t) {
        //     if (t == 'Special') {
        //         if (has_special) return false;
        //         has_special = true;
        //     }
        //     return true;
        // });
        var terminals = generator.generate('${typeString}_level${level}').leafs();
        var attributes = [ for (t in terminals) terminal_to_attribute(t) ];
        return new core.models.Equipment.CustomWeapon(attributes);
    }

    static function terminal_to_attribute(terminal :String) {
        // trace('terminal: $terminal');
        return switch (terminal) {
            case 'maybe_damage_small': core.models.Equipment.WeaponAbilityType.MaybeDamage(1);
            case 'damage_small': core.models.Equipment.WeaponAbilityType.Damage(1);
            case 'maybe_damage_medium': core.models.Equipment.WeaponAbilityType.MaybeDamage(2);
            case 'damage_medium': core.models.Equipment.WeaponAbilityType.Damage(2);
            // case 'increase_min_damage': core.models.Equipment.WeaponAbilityType.Damage(1);
            case 'curse': core.models.Equipment.WeaponAbilityType.Curse;
            case 'leech': core.models.Equipment.WeaponAbilityType.Leech;     // TODO: implement
            case 'push_back': core.models.Equipment.WeaponAbilityType.PushBack; // TODO: implement
            case _: throw 'Unhandled case!';
        };
    }

    // static function generate(symbol :String) :Array<String> {
    //     return generator.generate(symbol).leafs();
    // }
}
