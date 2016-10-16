import luxe.States;
import luxe.Input.KeyEvent;
import luxe.Input.Key;

import game.PostProcess;
import game.states.*;

class Main extends luxe.Game {
    static public var states :States;
    var fullscreen :Bool = false;
    var postprocess :PostProcess;

    override function config(config :luxe.GameConfig) {
        config.render.antialiasing = 4;

        config.preload.textures.push({ id: 'assets/images/tiles/tileGrass_full.png' });
        config.preload.textures.push({ id: 'assets/images/tiles/tileDirt_full.png' });
        config.preload.textures.push({ id: 'assets/images/tiles/tileSand_full.png' });
        config.preload.textures.push({ id: 'assets/images/tiles/tileSnow_full.png' });
        config.preload.textures.push({ id: 'assets/images/tiles/treeGreen_low.png' });
        config.preload.textures.push({ id: 'assets/images/tiles/rockStone.png' });

        config.preload.textures.push({ id: 'assets/images/icons/orc-head.png' });
        config.preload.textures.push({ id: 'assets/images/icons/spider-alt.png' });
        config.preload.textures.push({ id: 'assets/images/icons/wolf-head.png' });
        config.preload.textures.push({ id: 'assets/images/icons/crowned-skull.png' });
        config.preload.textures.push({ id: 'assets/images/icons/pointy-hat.png' });
        config.preload.textures.push({ id: 'assets/images/icons/shadow.png' });
        config.preload.textures.push({ id: 'assets/images/icons/background.png' });
        config.preload.textures.push({ id: 'assets/images/icons/fist.png' });
        config.preload.textures.push({ id: 'assets/images/icons/gladius.png' });
        config.preload.textures.push({ id: 'assets/images/icons/bowman.png' });
        config.preload.textures.push({ id: 'assets/images/icons/jump-across.png' });
        config.preload.textures.push({ id: 'assets/images/icons/overlord-helm.png' });
        config.preload.textures.push({ id: 'assets/images/icons/village.png' });

        config.preload.textures.push({ id: 'assets/images/overlay_filter.png' });
        config.preload.textures.push({ id: 'assets/images/sun_ray.png' });

        config.preload.shaders.push({ id: 'postprocess', frag_id: 'assets/shaders/postprocess2.glsl', vert_id: 'default' });

        config.preload.jsons.push({ id: 'assets/data/world_enemies.json' });
        config.preload.jsons.push({ id: 'assets/data/minions.json' });
        config.preload.texts.push({ id: 'assets/data/encounter_grammar.txt' });
        config.preload.texts.push({ id: 'assets/data/equipment_grammar.txt' });

        config.preload.jsons.push({ id: 'assets/ui/loot_menu.json' });

        return config;
    }

    override function ready() {
        // Optional, set a consistent scale camera mode for the entire game
		// this is a luxe's wip feature
		Luxe.camera.size = new luxe.Vector(960, 640);
		// Luxe.camera.size_mode = luxe.Camera.SizeMode.cover;
		// Luxe.camera.center = new luxe.Vector();

        luxe.tween.Actuate.defaultEase = luxe.tween.easing.Quad.easeInOut;

        Luxe.renderer.clear_color.set(25/255, 35/255, 55/255);

        var shader = Luxe.resources.shader('postprocess');
        shader.set_vector2('resolution', Luxe.screen.size);
        postprocess = new PostProcess(shader);
        postprocess.toggle(); // disable shader for now

        setup_data();

        states = new States({ name: 'state_machine' });
        states.add(new BattleState());
        states.add(new MinionActionsState());
        states.add(new WorldState());
        states.add(new LootState());
        states.set(WorldState.StateId);
        // states.set(BattleState.StateId, { enemy: 'spider' });
        // states.enable(LootState.StateId);
    }

    function setup_data() {
        var minion_database :Array<core.factories.MinionFactory.MinionData> = Luxe.resources.json('assets/data/minions.json').asset.json;
        core.factories.MinionFactory.Initialize(minion_database);

        var enemy_database :Array<core.factories.EnemyFactory.EnemyData> = Luxe.resources.json('assets/data/world_enemies.json').asset.json;

        var enemy_grammar = Luxe.resources.text('assets/data/encounter_grammar.txt').asset.text;
        core.factories.EnemyFactory.Initialize(enemy_database, enemy_grammar);

        var equipment_grammar = Luxe.resources.text('assets/data/equipment_grammar.txt').asset.text;
        core.factories.EquipmentFactory.Initialize(equipment_grammar);

        for (i in 0 ... 5) {
            var level = i + 1;
            trace('weapon level $level: ' + core.factories.EquipmentFactory.Create(core.factories.EquipmentFactory.EquipmentType.Weapon, level));
        }

        var deck = core.models.Game.player.deck;
        deck.add(new core.models.Card.MinionCard('wolf'));
        deck.add(new core.models.Card.MinionCard('archer'));
        deck.add(new core.models.Card.MinionCard('jumper'));
    }

    // Scale camera's viewport accordingly when game is scaled, common and suitable for most games
	// override function onwindowsized(e: luxe.Screen.WindowEvent) {
    //     Luxe.camera.viewport = new luxe.Rectangle(0, 0, e.event.x, e.event.y);
    // }

    override function onprerender() {
        if (postprocess != null) postprocess.prerender();
    }

    override function update(dt :Float) {
        if (postprocess != null) postprocess.shader.set_float('time', Luxe.core.tick_start + dt);
    }

    override function onpostrender() {
        if (postprocess != null) postprocess.postrender();
    }

    override function onkeyup(e :KeyEvent) {
        if (e.keycode == Key.enter && e.mod.alt) {
            fullscreen = !fullscreen;
            Luxe.snow.runtime.window_fullscreen(fullscreen, true /* true-fullscreen */);
        } else if (e.keycode == Key.key_s) {
            // save state
            Luxe.io.string_save('save', 'blah test');
        } else if (e.keycode == Key.key_l) {
            // load saved state
            trace('loaded state: ' + Luxe.io.string_load('save'));
        } else if (e.keycode == Key.key_p) {
            postprocess.toggle();
        } else if (e.keycode == Key.key_m) {
            states.set(WorldState.StateId);
        } else if (e.keycode == Key.key_b) {
            states.set(BattleState.StateId, { enemy: 'spider' });
        } else if (e.keycode == Key.escape) {
            if (!Luxe.core.shutting_down) Luxe.shutdown();
        }
    }
}
