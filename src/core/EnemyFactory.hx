package core;

typedef EnemyData = {
    var name :String;
    var icon :String;
    var speed :Float;
    var idle :Float;
    var chase_tiles :Int;
};

class EnemyFactory {
    var enemy_database :Map<String, EnemyData>;

    public function new(database :Array<EnemyData>) {
        enemy_database = new Map();
        for (d in database) {
            enemy_database[d.name] = d;
        }
    }

    public function create(name :String) {
        return enemy_database[name];
    }
}
