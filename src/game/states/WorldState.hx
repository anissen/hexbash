
package game.states;

import luxe.Input.MouseEvent;
import luxe.States.State;
import luxe.Vector;
import luxe.Sprite;
import luxe.tween.Actuate;
import game.Entities.CardEntity;
import game.components.PopIn;
import game.components.MoveTo;
import core.Models.BattleModel;
import phoenix.Batcher;
import luxe.Scene;
import luxe.Color;
import snow.api.Promise;
import core.MapFactory;
import game.Entities.HexTile;
import game.Entities.HexSpriteTile;
import game.Entities.HexGrid;
import game.entities.Enemy;
import core.HexLibrary.Hex;
import core.HexLibrary.Layout;

import libnoise.QualityMode;
import libnoise.ModuleBase;
import libnoise.generator.Perlin;

using Lambda;
using core.HexLibrary;

// enum WalkableTile {
//     Grass;
//     Dirt;
// }
//
// enum UnwalkableTile {
//     Empty;
//     Water;
// }
// enum BlockedTile {
//     Tree;
//     Rock;
// }
//
// enum TileType {
//     Walkable(type :WalkableTile);
//     Unwalkable(type :UnwalkableTile);
//     Blocked(type :BlockedTile);
// }

class WorldState extends State {
    static public var StateId :String = 'WorldState';
    var hexGrid :HexGrid;
    var hexes :Map<String, Hex>;
    var heights :Map<String, Float>;

    var hero :Sprite;
    var enemies :Array<Enemy>;

    // var path_shown :Array<Vector>;
    var path :Array<Hex>;

    var overlay_batcher :phoenix.Batcher;
    var overlay_filter :Sprite;
    // var water_shader :phoenix.Shader;

    public function new() {
        super({ name: StateId });

        path = [];
        // path_shown = [];
    }

    override function onenter(_) {
        Luxe.camera.zoom = 10;
        Luxe.renderer.clear_color.set(130/255, 220/255, 230/255); // water color
        // Luxe.renderer.clear_color.set(1, 20, 0);
        luxe.tween.Actuate.tween(Luxe.camera, 1.0, { zoom: 1 });

        // water_shader = Luxe.resources.shader('toon_water');
        // water_shader.set_vector2('resolution', Luxe.screen.size.clone());
        // new Sprite({
        //     centered: false,
        //     pos: new Vector(0, 0),
        //     color: new Color(139/255, 225/255, 235/255),
        //     size: Luxe.screen.size.clone(),
        //     shader: water_shader,
        //     texture: Luxe.resources.texture('assets/images/water.png'),
        //     batcher: Luxe.renderer.create_batcher({ name: 'water', layer: -1 })
        // });

        hexGrid = new HexGrid(35, 2, 0);
        // hexGrid.events.listen(HexGrid.HEX_MOUSEMOVED_EVENT, onhexmoved);
        hexGrid.events.listen(HexGrid.HEX_CLICKED_EVENT, onhexclicked);

        hexes = new Map();
        heights = new Map();
        enemies = [];

        create_map();

        hero = new Sprite({
            pos: hex_to_pos(new Hex(0, 0)),
            texture: Luxe.resources.texture('assets/images/icons/pointy-hat.png'),
            color: new Color(0, 0.5, 0.5),
            scale: new Vector(0.1, 0.1),
            depth: 98
        });

        overlay_batcher = Luxe.renderer.create_batcher({
            name: 'overlay',
            layer: 100
        });
        overlay_batcher.on(prerender, function(b :Batcher) {
            Luxe.renderer.blend_mode(BlendMode.src_alpha, BlendMode.one);
        });
        overlay_batcher.on(postrender, function(b :Batcher) {
            Luxe.renderer.blend_mode();
        });

        overlay_filter = new Sprite({
            pos: Luxe.screen.mid.clone(),
            texture: Luxe.resources.texture('assets/images/overlay_filter.png'),
            size: Luxe.screen.size.clone(),
            batcher: overlay_batcher
        });
        overlay_filter.color.a = 0.5;

        for (i in 0 ... 5) {
            var top = Math.random() < 0.5;
            var sun_ray = new Sprite({
                pos: top ? new Vector(Luxe.screen.w * 0.5 * Math.random(), 100 * Math.random()) : new Vector(100 * Math.random(), Luxe.screen.h * 0.5 * Math.random()),
                texture: Luxe.resources.texture('assets/images/sun_ray.png'),
                batcher: overlay_batcher,
                size: new Vector(50 + 250 * Math.random(), 400 + 400 * Math.random()),
                rotation_z: -30
            });
            sun_ray.color.a = 0.2;
        }
    }

    override function onleave(_) {
        Luxe.scene.empty();
    }

    function create_map() {
        var frequency = 0.01;
    	var lacunarity = 2.0;
    	var persistence = 0.5;
    	var octaves = 16;
    	var seed = 42;
    	var quality = HIGH;

        var module :ModuleBase = new Perlin(frequency, lacunarity, persistence, octaves, seed, quality);

        function get_normalized_value(val : Float) {
    		return (val + 1) / 2;
    	}

        var hex_list = MapFactory.create_hexagon_map(10); // .create_rectangular_map(10, 10);
        for (h in hex_list) {
            // if (Math.random() < 0.2) continue; // make some random holes
            var value = get_normalized_value(module.getValue(h.q * 15, h.r * 15, 0));
            if (value < water_level) continue;
            add_hex(h, value);
        }
        // hex_list.map(add_hex);
    }

    var water_level = 0.25;

    function add_hex(hex :Hex, value :Float) {
        var pos = hexGrid.hex_to_pos(hex);
        var max_height = (1 - water_level);
        var height_amount = (-max_height / 2) + ((value - water_level)) / max_height; // [-0.5;0.5]
        var height = height_amount * 25;
        pos.y += height;

        var tile_image = if (value < 0.4) {
            'Sand';
        } else if (value < 0.6) {
            'Dirt';
        } else if (value < 0.8) {
            'Grass';
        } else {
            'Snow';
        }
        var col = value * value;
        new HexSpriteTile({
            pos: new Vector(pos.x, pos.y + 12),
            // texture: Luxe.resources.texture('assets/images/tile' + (Math.random() > 0.3 ? 'Grass' : 'Dirt') + '_full.png'),
            texture: Luxe.resources.texture('assets/images/tiles/tile${tile_image}_full.png'),
            // color: new Color(value, value, value),
            depth: hex.r
        });

        var walkable = true;
        if (Math.random() > 0.95) {
            var enemy = new Enemy({
                pos: new Vector(pos.x, pos.y),
                type: (Math.random() < 0.5 ? Spider : Orc)
            });
            enemies.push(enemy);
        } else if (Math.random() > 0.9) {
            walkable = false;
            if (Math.random() < 0.8) {
                new Sprite({
                    pos: new Vector(pos.x, pos.y - 25),
                    texture: Luxe.resources.texture('assets/images/tiles/treeGreen_low.png'),
                    depth: 100
                });
            } else {
                new Sprite({
                    pos: new Vector(pos.x, pos.y + 10),
                    texture: Luxe.resources.texture('assets/images/tiles/rockStone.png'),
                    depth: 100
                });
            }
        }
        if (walkable) {
            hexes[hex.key] = hex;
            heights[hex.key] = height;
        }
    }

    function is_walkable(h :Hex) {
        return hexes.exists(h.key);
    }

    function hex_to_pos(hex :Hex) :Vector {
        var pos = hexGrid.hex_to_pos(hex);
        pos.y += heights[hex.key];
        return pos;
    }

    function onhexclicked(hex :Hex) {
        var hero_hex = hexGrid.pos_to_hex(hero.pos);
        path = hero_hex.find_path(hex, 20, 100, is_walkable);
    }

    // function onhexmoved(hex :Hex) {
    //     if (path.length > 0) return;
    //     var hero_hex = hexGrid.pos_to_hex(hero.pos);
    //     path_shown = hero_hex.find_path(hex, 5, 100, is_walkable).map(function(h) {
    //         return hex_to_pos(h);
    //     });
    // }

    override function onkeyup(e :luxe.Input.KeyEvent) {
        if (e.keycode == luxe.Input.Key.key_f) {
            overlay_filter.visible = !overlay_filter.visible;
        }
    }

    override function update(dt :Float) {
        // water_shader.set_float('time', Luxe.core.tick_start + dt);

        if (path.length == 0) {
            // for (p in path_shown) {
            //     Luxe.draw.circle({
            //         x: p.x,
            //         y: p.y,
            //         r: 10,
            //         immediate: true,
            //         depth: 101
            //     });
            // }
            return;
        }
        // path_shown = [];

        var move_to = hex_to_pos(path[0]);
        var diff = Vector.Subtract(move_to, hero.pos);
        if (diff.length > 2) {
            diff.normalize();
            hero.pos = Vector.Add(hero.pos, Vector.Multiply(diff, dt * 200));
            Luxe.camera.center = hero.pos;
        } else {
            var hex = path.shift();
            for (enemy in enemies) {
                var enemy_hex = hexGrid.pos_to_hex(enemy.pos);
                if (hex.key == enemy_hex.key) {
                    Main.states.set(BattleState.StateId);
                    return;
                }
            }
            for (enemy in enemies) {
                if (enemy.has('MoveTo')) continue; // Enemy is already moving
                if (Math.random() < 0.5) continue; // Enemy doesn't want to move
                var enemy_hex = hexGrid.pos_to_hex(enemy.pos);

                var reachable = enemy_hex.reachable(is_walkable, 1);
                if (reachable.length == 0) continue;
                var new_hex = reachable[Math.floor(reachable.length * Math.random())];
                var new_pos = hex_to_pos(new_hex);
                enemy.move_to(new_pos).onCompleted = function() {
                    var hero_hex = hexGrid.pos_to_hex(hero.pos);
                    if (new_hex.key == hero_hex.key) {
                        Main.states.set(BattleState.StateId);
                    }
                };
            }
        }
    }
}
