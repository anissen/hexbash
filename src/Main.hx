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

        config.preload.textures.push({ id: 'assets/images/overlay_filter.png' });
        config.preload.textures.push({ id: 'assets/images/sun_ray.png' });

        config.preload.shaders.push({ id: 'postprocess', frag_id: 'assets/shaders/postprocess2.glsl', vert_id: 'default' });

        config.preload.jsons.push({ id: 'assets/data/world_enemies.json' });
        config.preload.texts.push({ id: 'assets/data/encounter_grammar.txt' });

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

        states = new States({ name: 'state_machine' });
        states.add(new BattleState());
        states.add(new MinionActionsState());
        states.add(new WorldState());
        states.add(new TargetSelectionState());
        states.set(WorldState.StateId);
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
            postprocess.toggle();
        } else if (e.keycode == Key.key_m) {
            states.set(WorldState.StateId);
        } else if (e.keycode == Key.key_b) {
            states.set(BattleState.StateId);
        } else if (e.keycode == Key.escape) {
            if (!Luxe.core.shutting_down) Luxe.shutdown();
        }
    }
}
