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
        return [new Card.AttackCard('Punch 1', 1, 'wolf-head.png')];
    }
}
