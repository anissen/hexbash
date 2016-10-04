
package game.states;

import luxe.Input.MouseEvent;
import luxe.States.State;
import luxe.Scene;
import luxe.Color;
import luxe.tween.Actuate;

import mint.Control;
import mint.types.Types;
import mint.render.luxe.LuxeMintRender;
import mint.render.luxe.Convert;
import mint.layout.margins.Margins;
import mint.focus.Focus;

class LootState extends State {
    static public var StateId :String = 'LootState';

    var canvas: mint.Canvas;
    var rendering: LuxeMintRender;
    var layout: Margins;
    var focus :Focus;

    public function new() {
        super({ name: StateId });
    }

    override function onenabled<T>(value :T) {
        var data :{ callback :Int->Void } = cast value;
        var callback = data.callback;
        rendering = new LuxeMintRender({
            depth: 1000,
            batcher: Luxe.renderer.create_batcher({ name: 'gui', layer: 5 })
        });
        layout = new Margins();

        var _scale = Luxe.screen.device_pixel_ratio;
        var auto_canvas = new game.ui.AutoCanvas({
            name: 'canvas',
            rendering: rendering,
            options: { color: new Color(1,1,1,0.0) },
            scale: _scale,
            x: 0,
            y: 0,
            w: Luxe.screen.w / _scale,
            h: Luxe.screen.h / _scale
        });

        auto_canvas.auto_listen();
        canvas = auto_canvas;
        focus = new Focus(canvas);

        var panel = new mint.Panel({
            parent: canvas,
            x: (Luxe.screen.w / _scale) / 2 - 150,
            y: (Luxe.screen.h / _scale) / 2 - 200,
            w: 300,
            h: 400,
            options: { color: new Color(0.5,0.5,0,0.8) },
        });

        function create_choice(startY :Int, index :Int) {
            var choice = new mint.Panel({
                parent: panel,
                x: 10,
                y: startY,
                w: 280,
                h: 185,
                options: { color: new Color(1,0.5,0,0.8) }
            });

            new mint.Label({
                parent: choice,
                name: 'label',
                x:10, y:5, w:100, h:32,
                text: 'Sword ++',
                align:left,
                text_size: 20,
                onclick: function(_,_) { trace('hello header!'); }
            });

            var description = new mint.Label({
                parent: choice,
                name: 'label2',
                x:85, y:35, w:190, h:190,
                text: 'Awesome sword of the ancients. It seems to glow in the dark.\n\n· 2-4 Damage\n* 10% Risk of curse',
                align: TextAlign.left,
                align_vertical: TextAlign.top,
                bounds_wrap: true,
                text_size: 14,
                onclick: function(_,_) { trace('hello text!'); }
            });
            description.mouse_input = false;

            new mint.Button({
                parent: choice,
                name: 'button',
                text: 'Choose',
                x: 10, y: 145, w: 260, h: 32,
                onclick: function(e,c) { trace('button clicked!'); callback(index); },
            });

            new mint.Image({
                parent: choice,
                name: 'image1',
                x: 10, y: 50, w: 64, h: 64,
                // onclick: function(e,c) { trace('image clicked!'); },
                path: 'assets/images/icons/wolf-head.png'
            });
        }

        create_choice(10, 0);
        create_choice(205, 1);
    }

    override function ondisabled<T>(value :T) {
        canvas.destroy();
    }
}
