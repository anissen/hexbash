package core.models;

interface CardProvider {
    function get_cards() :Array<Card>;
}

// @structInit
class Equipment {
    public function new() {
    }
}

class Fists extends Equipment implements CardProvider {
    public function get_cards() :Array<Card> {
        // 100% chance for providing 1 card per turn
        // return [{ name: 'Punch', cost: 0, power: 1, type: Attack(1), icon: 'wolf-head.png', id: 0 }];
        var power = 1 + Math.floor(3 * Math.random());
        return [new Card.AttackCard('Punch $power', power, 'fist.png')];
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
