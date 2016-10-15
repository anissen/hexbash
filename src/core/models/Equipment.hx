package core.models;

interface CardProvider {
    function get_cards() :Array<Card>;
}

// @structInit
class Equipment {
    public function new() {
    }
}

enum WeaponAbilityType {
    Damage(value :Int);
    MaybeDamage(value :Int);
    Curse(/* function */);
    Leech(/* ... */);
    PushBack(/* ... */);
}

typedef WeaponAbility = { cost :Int, rarity :Float, type :WeaponAbilityType };

class CustomWeapon extends Equipment implements CardProvider {
    var abilities :Array<WeaponAbilityType>;

    public function new(abilities :Array<WeaponAbilityType>) {
        super();
        this.abilities = abilities;
    }

    public function get_cards() :Array<Card> {
        var damage = 0;
        var maybe_damage = 0;
        for (a in abilities) {
            switch (a) {
                case Damage(value): damage += value;
                case MaybeDamage(value): maybe_damage += value;
                case Curse: trace('CURSE! (TODO: Do something here)');
                case _:
            }
        }
        return [new Card.AttackCard('Weapon', damage + Math.floor(maybe_damage * Math.random()), 'fist.png')];
    }
}

class WeaponBuilder {
    var abilities :Array<WeaponAbility>;

    public function new() {
        abilities = [
            { cost: -1, rarity: 0.5, type: Curse },
            { cost: 1, rarity: 1, type: MaybeDamage(1) },
            { cost: 2, rarity: 0.8, type: Damage(1) },
            { cost: 2, rarity: 0.6, type: MaybeDamage(2) },
            { cost: 3, rarity: 0.4, type: Damage(2) }
        ];
    }

    public function get_weapon(level :Int /* weapon has max cost equal to level */) :CardProvider {
        // var usable_abilities = abilities.copy();
        var picked_abilities = [];
        while (level > 0) {
            var usable_abilities = abilities.filter(function(a) {
                return a.cost <= level && a.rarity > Math.random();
            });
            if (usable_abilities.length == 0) break;

            var random_ability = usable_abilities[Math.floor(usable_abilities.length * Math.random())];
            picked_abilities.push(random_ability.type);
            level -= random_ability.cost;
            if (picked_abilities.length >= level) break; // prevent too many abilities
        }
        return new CustomWeapon(picked_abilities);
    }
}

class Fists extends Equipment implements CardProvider {
    public function get_cards() :Array<Card> {
        // 100% chance for providing 1 card per turn
        // return [{ name: 'Punch', cost: 0, power: 1, type: Attack(1), icon: 'wolf-head.png', id: 0 }];
        var power = 1 + Math.floor(2 * Math.random());
        return [new Card.AttackCard('Punch', power, 'fist.png')];
    }
}

class Sword extends Equipment implements CardProvider {
    public function get_cards() :Array<Card> {
        // 100% chance for providing 1 card per turn
        var rand = Math.random();
        if (rand < 0.5) {
            return [new Card.AttackCard('Stab', 2, 'gladius.png')];
        } else {
            return [new Card.AttackCard('Swing', 3, 'gladius.png')];
        }
    }
}

class CursedSword extends Equipment implements CardProvider /* extends Sword */ {
    public function get_cards() :Array<Card> {
        // 20% risk of getting a curse instead
        if (Math.random() < 0.2) {
            function curse(battle :core.models.Battle) {
                return [core.Enums.Command.DamageMinion(battle.get_current_hero().id, 2)];
            }
            return [new Card.Card('Curse', 0, 'fist.png', core.Enums.CardType.Curse(curse))];
        }
        return [new Card.AttackCard('Slash', 5, 'gladius.png')];
    }
}
