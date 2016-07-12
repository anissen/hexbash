package core.models;

class Card {
    public var name :String;
    public var cost :Int;
    public var power :Int;
    // public var identifier :String;
    public var icon :String;
    public var type :core.Enums.CardType;
    public var id :Int;
    static var Id :Int = 0;

    public function new(name :String, cost :Int, power :Int, icon :String, type :core.Enums.CardType) {
        this.name = name;
        this.cost = cost;
        this.power = power;
        this.icon = icon;
        this.type = type;
        this.id = Id++;
    }
}
