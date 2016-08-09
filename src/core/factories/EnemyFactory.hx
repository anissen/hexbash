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
    static var generator = new Generator();
    static var enemy_database :Map<String, EnemyData>;

    static public function Initialize(enemyDatabase :Array<EnemyData>, enemyGrammar :String) {
        enemy_database = new Map();

        for (d in enemyDatabase) {
            enemy_database[d.identifier] = d;
        }

        generator = new Generator();
        generator.add_rules(enemyGrammar);
    }

    static public function Create(identifier :String) :EnemyData {
        return enemy_database[identifier];
    }

    static public function CreateRandom() :EnemyData {
        var identifier = generator.generate('Encounter').leafs()[0];
        return Create(identifier);
    }

    static public function CreateMany() :Array<EnemyData> {
        var identifiers = generator.generate('Encounter').leafs();
        return [ for (id in identifiers) Create(id) ];
    }
}
