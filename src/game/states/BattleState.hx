
package game.states;

import core.HexLibrary;
import luxe.Input.MouseEvent;
import luxe.options.VisualOptions;
import luxe.Scene;
import luxe.States.State;
import luxe.tween.Actuate;
import luxe.Vector;
import luxe.Visual;
import luxe.Color;
import snow.api.Promise;

import core.models.Battle;
import core.models.Card;
import core.Enums;
import core.models.Minion;
import core.PromiseQueue;
import game.Entities.MinionEntity;
import game.Entities.HeroEntity;
import game.Entities.HexSpriteTile;
import game.Entities.HexGrid;
import game.components.PopIn;

using core.HexLibrary.HexTools;
using core.tools.ArrayTools;
using game.tools.TweenTools;

class BattleState extends State {
    static public var StateId :String = 'BattleState';
    var levelScene :Scene;
    var minionMap :Map<Int, MinionEntity>;
    var hexMap :Map<String, HexSpriteTile>;
    var battle :Battle;
    var hexGrid :HexGrid;
    var guiBatcher :phoenix.Batcher;
    var handState :HandState;

    public function new() {
        super({ name: StateId });
        hexGrid = new HexGrid(35, 6, 4); //new HexGrid();
        levelScene = new Scene();
        guiBatcher = Luxe.renderer.create_batcher({ name: 'gui', layer: 4 });
    }

    override function init() {

    }

    override function onenter(data :Dynamic) {
        // core.models.Game.player.deck.print();

        reset(data.enemy, 1000 * Math.random());

        Luxe.camera.zoom = 0.2;
        luxe.tween.Actuate.tween(Luxe.camera, 1.0, { zoom: 1.5 });
        Luxe.camera.pos = new Vector(0, 0);
        //reset(87634.34);
    }

    override function onleave(_) {
        clear();
    }

    function clear() {
        Actuate.reset();
        levelScene.empty();
        hexMap = new Map();
        minionMap = new Map();
        if (handState != null) handState.reset();
    }

    function reset(enemy :String, seed :Float) {
        clear();

        battle = new Battle();
        battle.listen(handle_event);

        handState = new HandState(battle, guiBatcher, levelScene);
        HandState.hexGrid = hexGrid; // HACK

        Main.states.add(handState);
        Main.states.enable(HandState.StateId);

        load_map(enemy, seed);
        //battle.load_map(seed);
        // battle.add_card_to_deck({ name: 'Attack', cost: 1, power: 2, type: Attack(1), icon: 'wolf-head.png', id: 0 });
        // battle.add_card_to_deck({ name: 'Attack', cost: 1, power: 2, type: Attack(1), icon: 'wolf-head.png', id: 1 });
        // battle.add_card_to_deck({ name: 'Attack', cost: 1, power: 2, type: Attack(1), icon: 'wolf-head.png', id: 2 });
        // battle.add_card_to_deck({ name: 'Minion', cost: 1, power: 2, type: Minion('Wolf', 3), icon: 'wolf-head.png', id: 0 });
        // battle.add_card_to_deck({ name: 'Minion', cost: 1, power: 2, type: Minion('Wolf', 3), icon: 'wolf-head.png', id: 1 });

        battle.start_game();
    }

    function load_map(enemy :String, seed :Float) {
        var hexes = core.factories.MapFactory.create_custom_map();

        var enemy_hex = new Hex(1, -2);
        var hero_hex = new Hex(-1, 2);

        // remove random hexes
        // var hexes_to_remove = 2;
        // for (i in 0 ... hexes_to_remove) {
        //     if (hexes.length <= 1) break;
        //     var random_index = Math.floor(hexes.length * Math.random());
        //     var random_hex = hexes[random_index];
        //     var path = hero_hex.find_path(enemy_hex, hexes.length, 1000, function (h) {
        //         if (h.key == random_hex.key) return false;
        //         for (hex in hexes) {
        //             if (hex.key == h.key) return true;
        //         }
        //         return false;
        //     }, true);
        //     if (path.length > 0) { // there is a path from hero to enemy
        //         hexes.splice(random_index, 1)[0];
        //     }
        // }

        var random_index = Math.floor(hexes.length * Math.random());
        hexes.splice(random_index, 1)[0];

        hexes.push(enemy_hex);
        hexes.push(hero_hex);

        if (Math.random() < 0.1) hexes.push(new Hex(0, 2));  // upper left
        if (Math.random() < 0.1) hexes.push(new Hex(2, -2)); // upper right
        if (Math.random() < 0.1) hexes.push(new Hex(-2, 2)); // lower left
        if (Math.random() < 0.1) hexes.push(new Hex(0, 2));  // lower right

        hexes.map(battle.add_hex);

        // function get_random_placement() {
        //     while (true) {
        //         var random_hex = hexes[Math.floor(hexes.length * Math.random())];
        //         if (battle.get_minion(random_hex) == null) return random_hex;
        //     }
        // }

        function get_placement_near(hex :Hex) :Null<Hex> {
            var hexes = hex.range(1);
            hexes.push(hex);
            for (h in hexes.shuffle()) {
                if (battle.has_hex(h) && battle.get_minion(h) == null) return h;
            }
            return null;
        }

        function create_enemy_minion(data :core.factories.EnemyFactory.EnemyData) {
            var enemyId = 1;
            var maybe_hex = get_placement_near(enemy_hex);
            if (maybe_hex == null) return;
            var model = new Minion(data.identifier, enemyId, Luxe.utils.random.int(1, 6), maybe_hex, data.icon, false);
            battle.add_minion(model);
        }

        var enemy_hero = core.factories.MinionFactory.Create(enemy, 1, get_placement_near(enemy_hex));
        enemy_hero.hero = true;
        battle.add_minion(enemy_hero);
        // battle.add_minion(new Minion('Enemy', 1, 4, new Hex(0, 0), 'crowned-skull.png', true)); // TODO: Should be part of normal generation

        battle.add_minion(new Minion('Hero', 0, core.models.Game.player.life, get_placement_near(hero_hex), 'pointy-hat.png', true));
        var minion_hex = get_placement_near(hero_hex);
        if (minion_hex != null) {
            battle.add_minion(new Minion('Rat', 0, Luxe.utils.random.int(1, 6), minion_hex, 'wolf-head.png', false));
        }

        core.factories.EnemyFactory.CreateMany().map(create_enemy_minion);
    }

    function handle_event(event :Event) :Promise {
        return switch (event) {
            case HexAdded(hex): add_hex(hex);
            case MinionAdded(modelId): add_minion(modelId);
            case MinionMoved(modelId, from, to): move_minion(modelId, from, to);
            case MinionDamaged(modelId, amount): damage_minion(modelId, amount);
            case MinionHealed(modelId, amount): heal_minion(modelId, amount);
            case MinionAttacked(attackerId, defenderId): attack_minion(attackerId, defenderId);
            case MinionDied(modelId): remove_minion(modelId);
            case TurnStarted(playerId): turn_started(playerId);
            case CardPlayed(cardId): handState.play_card(cardId);
            case CardDrawn(cardId): handState.draw_card(cardId);
            case CardDiscarded(cardId): handState.discard_card(cardId);
            case GameWon: game_over(true);
            case GameLost: game_over(false);
        };
    }

    function add_hex(hex :Hex) :Promise {
        var pos = hexGrid.hex_to_pos(hex);
        // var tile = new HexTile({
        //     pos: new Vector(pos.x, pos.y),
        //     r: hexGrid.hexSize,
        //     scene: levelScene
        // });
        var tile = new HexSpriteTile({
            pos: new Vector(pos.x, pos.y + 12),
            texture: Luxe.resources.texture('assets/images/tiles/tile' + (Math.random() > 0.3 ? 'Grass' : 'Dirt') + '_full.png'),
            depth: -100 + hex.r,
            scene: levelScene
        });
        var popIn = new FastPopIn();
        tile.add(popIn);
        hexMap[hex.key] = tile;
        return popIn.promise;
    }

    function add_minion(modelId :Int) :Promise {
        var model = battle.get_minion_from_id(modelId);
        var minionPos = hexGrid.hex_to_pos(model.hex);
        var options :game.Entities.MinionOptions = {
            model: model,
            pos: new Vector(minionPos.x, minionPos.y),
            color: (model.playerId == 0 ? new Color(129/255, 83/255, 118/255) : new Color(229/255, 83/255, 118/255)),
            depth: 2,
            scene: levelScene
        };
        var minion = (/*model.hero ? new HeroEntity(options) : */ new MinionEntity(options));
        minionMap.set(modelId, minion);
        var popIn = new PopIn();
        minion.add(popIn);
        return popIn.promise;
    }

    function remove_minion(modelId :Int) :Promise {
        var minion = minion_from_model(modelId);
        minion.destroy();
        minionMap.remove(modelId);
        return Promise.resolve();
    }

    function turn_started(playerId :Int) :Promise {
        if (Main.states.enabled(MinionActionsState.StateId)) {
            Main.states.disable(MinionActionsState.StateId);
        }
        if (playerId == 0) {
            if (!Main.states.enabled(HandState.StateId)) Main.states.enable(HandState.StateId);
        } else {
            if (Main.states.enabled(HandState.StateId)) Main.states.disable(HandState.StateId);
        }

        if (playerId == 1) { // AI
            core.AI.do_actions(battle);
        }
        return Promise.resolve();
    }

    function minion_from_model(minionId :Int) {
        return minionMap.get(minionId);
    }

    function move_minion(modelId :Int, from :Hex, to :Hex) :Promise {
        var minion = minion_from_model(modelId);
        minion.pos = hexGrid.hex_to_pos(from);
        var pos = hexGrid.hex_to_pos(to); // TODO: Rename to pos_from_hex
        return Actuate.tween(minion.pos, 0.2, { x: pos.x, y: pos.y }).toPromise();
    }

    function damage_minion(modelId :Int, amount :Int) :Promise {
        var minion = minion_from_model(modelId);
        return new Promise(function(resolve) {
            Actuate.tween(minion.color, 0.1, { r: 1.0, g: 1.0, b: 1.0 }).reflect().repeat(1)
                .onComplete(function() { minion.damage(amount); resolve(); });
        });
    }

    function heal_minion(modelId :Int, amount :Int) :Promise {
        var minion = minion_from_model(modelId);
        return new Promise(function(resolve) {
            Actuate.tween(minion.color, 0.1, { r: 0.0, g: 1.0, b: 0.0 }).reflect().repeat(1)
                .onComplete(function() {
                    minion.heal(amount);
                    resolve();
                });
        });
    }

    function attack_minion(attackerModelId :Int, defenderModelId :Int) :Promise {
        var attacker = minion_from_model(attackerModelId);
        var defender = minion_from_model(defenderModelId);
        var defenderPos = defender.pos.clone(); // in case defender dies
        Luxe.camera.shake(2);
        return Actuate.tween(attacker.pos, 0.2, { x: defenderPos.x, y: defenderPos.y }).reflect().repeat(1).toPromise();
    }

    function game_over(won :Bool) {
        trace('Game Over - You ${won ? "Won" : "Lost"}!');
        if (Main.states.enabled(HandState.StateId)) Main.states.disable(HandState.StateId);
        // reset(battle.get_random().get());
        var cards = [new core.models.Card.MinionCard('spider'), new core.models.Card.MinionCard('wolf')];

        var promise = new Promise(function(resolve) {
            Main.states.enable(LootState.StateId, { cards: cards, callback: function(selection :Int) {
                Main.states.disable(LootState.StateId);
                trace('choose loot #$selection');
                if (selection == 0) {
                    core.models.Game.player.equipment = [new core.models.Equipment.Sword()];
                } else {
                    core.models.Game.player.equipment = [new core.models.Equipment.CursedSword()];
                }
                resolve();
            }});
        });

        return promise.then(to_overworld_map);
    }

    function to_overworld_map() {
        Main.states.set(WorldState.StateId);
    }

    override public function onmousemove(event :luxe.Input.MouseEvent) {
        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);

        /* HACK */
        for (model in battle.get_minions()) {
            if (model.playerId != 0) continue; // Only open actions for own minions
            var minion = minionMap[model.id];
            if (minion == null) continue;
            minion.color.r = (model.actions > 0 ? 0.5 : 0.3);
            if (minion != null && Luxe.utils.geometry.point_in_geometry(world_pos, minion.geometry)) {
                minion.color.r = (model.actions > 0 ? 0.8 : 0.3);
            }
        }
    }

    override public function onmousedown(event :luxe.Input.MouseEvent) {
        var screen_pos = event.pos;
        var world_pos = Luxe.camera.screen_point_to_world(event.pos);

        /* HACK */
        for (model in battle.get_minions()) {
            if (model.playerId != 0) continue; // Only open actions for own minions
            var minion = minionMap[model.id];
            if (minion == null) continue;
            if (Luxe.utils.geometry.point_in_geometry(world_pos, minion.geometry)) {
                Main.states.disable(HandState.StateId);
                Main.states.enable(MinionActionsState.StateId, { model: model, battle: battle, hexGrid: hexGrid });
                return;
            }
        }
    }

    override public function onkeyup(event :luxe.Input.KeyEvent) {
        switch (event.keycode) {
            // case luxe.Input.Key.enter: battle.do_action(core.Models.Action.EndTurn);
            case luxe.Input.Key.key_r: reset('spider', 1000 * Math.random());
            case luxe.Input.Key.key_w: game_over(true);
        }
    }
}
