
import luxe.States;
import luxe.Input.KeyEvent;
import luxe.Input.Key;
#if desktop
import filewatch.Filewatch;
#end

import game.states.*;


// ------ PostProcess ------
import phoenix.Batcher.BlendMode;
import phoenix.RenderTexture;
import phoenix.Texture;
import phoenix.Batcher;
import phoenix.Shader;
import luxe.Sprite;
import luxe.Vector;
import luxe.Color;

class PostProcess {
    var output: RenderTexture;
    var batch: Batcher;
    var view: Sprite;
    public var shader: Shader;

    public function new(shader :Shader) {
        output = new RenderTexture({ id: 'render-to-texture', width: Luxe.screen.w, height: Luxe.screen.h });
        batch = Luxe.renderer.create_batcher({ no_add: true });
        this.shader = shader;
        view = new Sprite({
            no_scene: true,
            centered: false,
            pos: new Vector(0,0),
            size: Luxe.screen.size,
            texture: output,
            shader: shader, //Luxe.renderer.shaders.textured.shader,
            batcher: batch
        });
    }

    public function toggle() {
        view.shader = (view.shader == shader ? Luxe.renderer.shaders.textured.shader : shader);
    }

    public function prerender() {
        Luxe.renderer.target = output;
        Luxe.renderer.clear(new Color(0,0,0,1));
    }

    public function postrender() {
        Luxe.renderer.target = null;
        Luxe.renderer.clear(new Color(1,0,0,1));
        Luxe.renderer.blend_mode(BlendMode.src_alpha, BlendMode.zero);
        batch.draw();
        Luxe.renderer.blend_mode();
    }
}
// ------ PostProcess ------

class Main extends luxe.Game {
    static public var states :States;
    var fullscreen :Bool = false;
    var postprocess :PostProcess;

    override function config(config :luxe.AppConfig) {
        config.render.antialiasing = 4;

        // config.preload.textures.push({ id: 'assets/images/cultist.png' });
        config.preload.textures.push({ id: 'assets/images/tileGrass_full.png' });
        config.preload.textures.push({ id: 'assets/images/tileDirt_full.png' });
        config.preload.textures.push({ id: 'assets/images/treeGreen_low.png' });
        config.preload.textures.push({ id: 'assets/images/icons/orc-head.png' });
        config.preload.textures.push({ id: 'assets/images/icons/spider-alt.png' });
        config.preload.textures.push({ id: 'assets/images/icons/pointy-hat.png' });
        config.preload.texts.push({ id: 'assets/scripts/test.hxs' });
        config.preload.shaders.push({ id: 'postprocess', frag_id: 'assets/shaders/postprocess.glsl', vert_id: 'default' });


        // config.render.depth_bits = 24;
        // config.render.depth = true;
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
        postprocess.toggle();

        states = new States({ name: 'state_machine' });
        states.add(new BattleState());
        states.add(new MinionActionsState());
        states.add(new WorldState());
        states.set(WorldState.StateId);

        #if desktop
            var assets_path = '/Users/nissen/code/snowkit/hexbash/assets';
            trace('watching "$assets_path"');

            function on_file_changed(event :FilewatchEvent) {
                trace('type: ${event.type} path: ${event.path}');
                if (event.type == FWE_modify || event.type == FWE_create) {
                    var pos = event.path.indexOf("assets/");
                    if (pos >= 0) {
                        var asset_key = event.path.substr(pos);
                        asset_key = StringTools.replace(asset_key, '\\', '/');

                        trace('Trying to find asset with key "$asset_key" from ' + event.path);

                        var resource = Luxe.resources.get(asset_key);
                        if (resource != null /*&& StringTools.endsWith(asset_key, '.hxs') */) {
                            trace('Reloading asset with key "$asset_key"');
                            resource.reload();
                        } else {
                            trace('Ignoring asset with key "$asset_key"');
                        }
                    }
                }
            }

            Filewatch.init(on_file_changed);
            Filewatch.add_watch('$assets_path');
        #end
    }

    // Scale camera's viewport accordingly when game is scaled, common and suitable for most games
	// override function onwindowsized(e: luxe.Screen.WindowEvent) {
    //     Luxe.camera.viewport = new luxe.Rectangle(0, 0, e.event.x, e.event.y);
    // }

    // override function onrender() {
    //     Luxe.draw.rectangle({
    //         x: 20,
    //         y: 20,
    //         w: Luxe.screen.w - 40,
    //         h: Luxe.screen.h - 40,
    //         immediate: true
    //     });
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
