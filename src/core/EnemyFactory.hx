package core;

import generativegrammar.Generator;
import generativegrammar.Tree;
using generativegrammar.TreeTools;

typedef EnemyData = {
    var name :String;
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
            enemy_database[d.name] = d;
        }

        var enemy_grammar = Luxe.resources.text('assets/data/encounter_grammar.txt').asset.text;
        generator = new Generator();
        generator.add_rules(enemy_grammar);
    }

    public function create(name :String) {
        return enemy_database[name];
    }

    public function create_random() {
        var name = generator.generate('Encounter').leafs()[0];
        return create(name);
    }

    public function create_random_list() {
        var names = generator.generate('Encounter').leafs();
        return [ for (name in names) create(name) ];
    }
}
