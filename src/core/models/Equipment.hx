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
    public function new() {
        super();
    }

    public function get_cards() :Array<Card> {
        // 100% chance for providing 1 card per turn
        // return [{ name: 'Punch', cost: 0, power: 1, type: Attack(1), icon: 'wolf-head.png', id: 0 }];
        var power = 1 + Math.floor(3 * Math.random());
        return [new Card.AttackCard('Punch $power', power, 'fist.png')];
    }
}

class Sword extends Equipment implements CardProvider {
    public function new() {
        super();
    }

    public function get_cards() :Array<Card> {
        // 100% chance for providing 2 card per turn
        return [new Card.AttackCard('Slash 5', 5, 'gladius.png'), new Card.AttackCard('Stab 3', 3, 'gladius.png')];
    }
}
