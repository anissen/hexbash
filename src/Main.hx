
import luxe.States;
import luxe.Input.KeyEvent;
import luxe.Input.Key;

class Main extends luxe.Game {
    static public var states :States;

    override function config(config :luxe.AppConfig) {
        config.render.antialiasing = 4;

        // config.render.depth_bits = 24;
        // config.render.depth = true;

        return config;
    }

    override function ready() {
        Luxe.renderer.clear_color.set(25/255, 35/255, 55/255);

        states = new States({ name: 'state_machine' });
        states.add(new GameState.BattleState());
        states.add(new GameState.PieceActionState());
        states.add(new GameState.CardCastState());
        states.set(GameState.BattleState.StateId);
    }

    override function onkeyup(e :KeyEvent) {
        if (e.keycode == Key.enter && e.mod.alt) {
            app.app.window.fullscreen = !app.app.window.fullscreen;
        } else if (e.keycode == Key.escape) {
            Luxe.shutdown();
        }
    }
}
