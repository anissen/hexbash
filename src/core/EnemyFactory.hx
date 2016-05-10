package core;

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

    public function new() {
        enemy_database = new Map();

        var database :Array<EnemyData> = Luxe.resources.json('assets/data/world_enemies.json').asset.json;
        for (d in database) {
            enemy_database[d.identifier] = d;
        }

        var enemy_grammar = Luxe.resources.text('assets/data/encounter_grammar.txt').asset.text;
        generator = new Generator();
        generator.add_rules(enemy_grammar);
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
