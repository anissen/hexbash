package core.models;

class Card {
    public var name :String;
    public var cost :Int;
    public var icon :String;
    public var type :core.Enums.CardType;
    public var id :Int;
    static var Id :Int = 0;

    public function new(name :String, cost :Int, icon :String, type :core.Enums.CardType) {
        this.name = name;
        this.cost = cost;
        this.icon = icon;
        this.type = type;
        this.id = Id++;
    }
}

class AttackCard extends Card {
    public function new(name :String, power :Int, icon :String) {
        super('$name $power', 0, icon, core.Enums.CardType.Attack(power));
    }
}

class MinionCard extends Card {
    public function new(identifier :String) {
        var data = core.factories.MinionFactory.GetData(identifier);
        super('${data.name} ${data.power}', data.power, data.icon, core.Enums.CardType.Minion(identifier));
    }
}
