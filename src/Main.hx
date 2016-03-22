
import luxe.States;
import luxe.Input.KeyEvent;
import luxe.Input.Key;

import game.states.*;

class Main extends luxe.Game {
    static public var states :States;

    override function config(config :luxe.AppConfig) {
        config.render.antialiasing = 4;

        config.preload.texts.push({ id: 'assets/scripts/test.hxs' });

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

        states = new States({ name: 'state_machine' });
        states.add(new BattleState());
        states.add(new MinionActionsState());
        states.set(BattleState.StateId);

        // #if desktop
        // trace('watching!');
        // Luxe.snow.io.module.watch_add('assets/');
        // #end
    }

    // Scale camera's viewport accordingly when game is scaled, common and suitable for most games
	// override function onwindowsized(e: luxe.Screen.WindowEvent) {
    //     Luxe.camera.viewport = new luxe.Rectangle(0, 0, e.event.x, e.event.y);
    // }

    override function onrender() {
        Luxe.draw.rectangle({
            x: 20,
            y: 20,
            w: Luxe.screen.w - 40,
            h: Luxe.screen.h - 40,
            immediate: true
        });
    }

    override function onkeyup(e :KeyEvent) {
        if (e.keycode == Key.enter && e.mod.alt) {
            // app.app.window.fullscreen = !app.app.window.fullscreen;
        } else if (e.keycode == Key.escape) {
            if (!Luxe.core.shutting_down) Luxe.shutdown();
        }
    }



    // ----------------------------------------------------



    // function notify_reload(d :luxe.resource.Resource.TextResource) {
    //     Luxe.events.fire('Luxe.reload', d);
    //     trace('fire reload with $d');
    // }
    //
    // override function onevent(event :snow.types.Types.SystemEvent) {
    //     if (event.type == snow.types.Types.SystemEventType.file) {
    //         var _type = event.file.type;
    //         trace('File event type:${_type}, path:${event.file.path} ts:${event.file.timestamp}');
    //     }
    //     // if (e.type == snow.types.Types.SystemEventType.file) {
    //         // var pos = e.file.path.indexOf("assets/");
    //         // if (pos >= 0) {
    //         //     var asset_key = e.file.path.substr(pos);
    //         //     asset_key = StringTools.replace(asset_key, '\\', '/');
    //         //
    //         //     trace('Trying to find asset with key "$asset_key" from ' + e.file.path);
    //         //
    //         //     var resource = Luxe.resources.get(asset_key);
    //         //     if (resource != null && StringTools.endsWith(asset_key, '.hx')) {
    //         //         resource.reload().then(notify_reload);
    //         //     } else {
    //         //         trace('Ignoring asset with key "$asset_key"');
    //         //     }
    //         // } else {
    //         //     trace('Non-asset file reload ignored (${e.file.path})');
    //         // }
    //     // }
    // }
}
