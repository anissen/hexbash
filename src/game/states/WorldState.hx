
package game.states;

import luxe.Input.MouseEvent;
import luxe.States.State;
import luxe.Vector;
import luxe.Sprite;
import luxe.tween.Actuate;
import game.Entities.CardEntity;
import game.Components.PopIn;
import core.Models.BattleModel;
import phoenix.Batcher;
import luxe.Scene;
import luxe.Color;
import snow.api.Promise;
import core.MapFactory;
import game.Entities.HexTile;
import game.Entities.HexSpriteTile;
import game.Entities.HexGrid;
import game.Components;
import core.HexLibrary.Hex;
import core.HexLibrary.Layout;

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

    var hero :Sprite;
    var enemies :Array<Sprite>;

    var path_shown :Array<Vector>;
    var path :Array<Hex>;

    // var water_shader :phoenix.Shader;

    public function new() {
        super({ name: StateId });

        path = [];
        path_shown = [];
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
        hexGrid.events.listen(HexGrid.HEX_MOUSEMOVED_EVENT, onhexmoved);
        hexGrid.events.listen(HexGrid.HEX_CLICKED_EVENT, onhexclicked);

        hexes = new Map();
        enemies = [];

        var hex_list = MapFactory.create_hexagon_map(10); // .create_rectangular_map(10, 10);
        for (h in hex_list) {
            if (Math.random() < 0.2) continue; // make some random holes
            add_hex(h);
        }
        // hex_list.map(add_hex);

        hero = new Sprite({
            pos: hexGrid.hex_to_pos(new Hex(0, 0)),
            texture: Luxe.resources.texture('assets/images/icons/pointy-hat.png'),
            color: new Color(0, 0.5, 0.5),
            scale: new Vector(0.1, 0.1),
            depth: 98
        });
    }

    override function onleave(_) {
        Luxe.scene.empty();
    }

    function add_hex(hex :Hex) {
        var pos = hexGrid.hex_to_pos(hex);
        var height = -3 + 6 * Math.random();
        pos.y += height;

        new HexSpriteTile({
            pos: new Vector(pos.x, pos.y + 12),
            texture: Luxe.resources.texture('assets/images/tile' + (Math.random() > 0.3 ? 'Grass' : 'Dirt') + '_full.png'),
            depth: hex.r
        });

        var walkable = true;
        if (Math.random() > 0.9) {
            var enemy = new Sprite({
                pos: new Vector(pos.x, pos.y),
                texture: Luxe.resources.texture('assets/images/icons/' + (Math.random() < 0.5 ? 'orc-head.png' : 'spider-alt.png')),
                color: new Color(1, 1, 1), // new ColorHSL(360 * Math.random(), 0.8, 0.8),
                scale: new Vector(0.08, 0.08),
                depth: 99
            });
            new Sprite({
                pos: new Vector(256, 256),
                centered: true,
                texture: Luxe.resources.texture('assets/images/icons/shadow.png'),
                color: new Color(0, 0, 0),
                scale: new Vector(1.4, 1.4),
                depth: 98,
                parent: enemy
            });
            enemies.push(enemy);
        } else if (Math.random() > 0.9) {
            walkable = false;
            new Sprite({
                pos: new Vector(pos.x, pos.y - 25),
                texture: Luxe.resources.texture('assets/images/treeGreen_low.png'),
                depth: 100
            });
        }
        if (walkable) hexes[hex.key] = hex;
    }

    function is_walkable(h :Hex) {
        return hexes.exists(h.key);
    }

    function onhexclicked(hex :Hex) {
        var hero_hex = hexGrid.pos_to_hex(hero.pos);
        path = hero_hex.find_path(hex, 5, 100, is_walkable); // TODO: Arguments?!
    }

    function onhexmoved(hex :Hex) {
        if (path.length > 0) return;
        var hero_hex = hexGrid.pos_to_hex(hero.pos);
        path_shown = hero_hex.find_path(hex, 5, 100, is_walkable).map(function(h) {
            return hexGrid.hex_to_pos(h);
        });
    }

    override function update(dt :Float) {
        // water_shader.set_float('time', Luxe.core.tick_start + dt);

        if (path.length == 0) {
            for (p in path_shown) {
                Luxe.draw.circle({
                    x: p.x,
                    y: p.y,
                    r: 10,
                    immediate: true,
                    depth: 101
                });
            }
            return;
        }
        path_shown = [];

        var move_to = hexGrid.hex_to_pos(path[0]);
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
                var new_pos = hexGrid.hex_to_pos(new_hex);
                var move_to = new MoveTo(new_pos, Math.random());
                move_to.onCompleted = function() {
                    var hero_hex = hexGrid.pos_to_hex(hero.pos);
                    if (new_hex.key == hero_hex.key) {
                        Main.states.set(BattleState.StateId);
                    }
                };
                enemy.add(move_to);
            }
        }
    }
}
