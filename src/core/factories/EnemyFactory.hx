package core.factories;

import generativegrammar.Generator;
import generativegrammar.Tree;
using generativegrammar.TreeTools;

typedef EnemyData = {
    var identifier :String;
    var icon :String;
    var speed :Float;
    var idle :Float;
    var chase_tiles :Int;
};

class EnemyFactory {
    var generator = new Generator();
    var enemy_database :Map<String, EnemyData>;

    public function new(enemyDatabase :Array<EnemyData>, enemyGrammar :String) {
        enemy_database = new Map();

        for (d in enemyDatabase) {
            enemy_database[d.identifier] = d;
        }

        generator = new Generator();
        generator.add_rules(enemyGrammar);
    }

    public function create(identifier :String) :EnemyData {
        return enemy_database[identifier];
    }

    public function create_random() :EnemyData {
        var identifier = generator.generate('Encounter').leafs()[0];
        return create(identifier);
    }

    public function create_many() :Array<EnemyData> {
        var identifiers = generator.generate('Encounter').leafs();
        return [ for (id in identifiers) create(id) ];
    }
}
