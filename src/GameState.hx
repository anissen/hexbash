
import HexLibrary;
import luxe.Input.MouseEvent;
import luxe.options.VisualOptions;
import luxe.Scene;
import luxe.States.State;
import luxe.Vector;
import luxe.Visual;
import luxe.Color;

using HexLibrary.HexTools;

typedef HexTileOptions = {
    > VisualOptions,
    r :Float
}

class HexTile extends Visual {
    public var foreground :Visual;

    public function new(options :HexTileOptions) {
        super({
            pos: options.pos,
            color: new Color(26/255, 43/255, 65/255),
            geometry: Luxe.draw.ngon({ sides: 6, r: options.r, angle: 30, solid: true })
        });

        foreground = new Visual({
            pos: options.pos,
            color: new Color(52/255, 73/255, 103/255),
            geometry: Luxe.draw.ngon({ sides: 6, r: options.r - 5, angle: 30, solid: true })
        });
    }
}

class Blocked extends luxe.Component {
    public function new() {
        super({ name: 'Blocked' });
    }

    override function init() {
        var hexTile :HexTile = cast entity;
        hexTile.color.tween(1, { a: 0.0 });
        hexTile.foreground.color.tween(1, { r: 26/255, g: 39/255, b: 60/255 });
    }
}

/*
Idea:
BattleState
    HAS a BattleMap
    HAS cards
    HAS entities
    States:
    -> PieceActionState
    -> CardCastState

Model-View separation between LevelMap, Pieces, Cards
*/

// TODO: Abstract out the level logic to be able to listen to level events, e.g.
// * c
class BattleMap extends luxe.Entity {
    static public var HEX_CLICKED_EVENT :String = 'hex_clicked';
    static public var HEX_MOUSEMOVED_EVENT :String = 'hex_mousemoved';
    var levelScene :Scene;
    public /* HACK */ var layout :Layout;

    var map_radius :Int = 4;
    var hexSize :Int = 60;
    var margin  :Int = 5;

    var hexMap :Map<String, HexTile>;
    public var entities :Array<Piece>;
    var random :luxe.utils.Random;


    public function new() {
        super({ name: 'BattleMap' });
        hexMap = new Map();
        levelScene = new Scene();
        entities = [];
        random = new luxe.utils.Random(42);
    }

    override function init() {
        var hexes = MapFactory.create_hexagon_map(map_radius);

        var size = new Point(hexSize + margin, hexSize + margin);
        var origin = new Point(Luxe.screen.mid.x, Luxe.screen.mid.y);
        layout = new Layout(Layout.pointy, size, origin);

        for (hex in hexes) {
            var pos = Layout.hexToPixel(layout, hex);
            var tile = new HexTile({
                pos: new Vector(pos.x, pos.y),
                r: hexSize,
                scene: levelScene
            });
            if (random.get() < 0.3) {
                tile.add(new Blocked());
            }
            hexMap[hex.key] = tile;
        }
    }

    public function is_walkable(hex :Hex) {
        if (is_blocked(hex)) return false;
        if (get_entity(hex) != null) return false;
        return true;
    }

    public function get_entity(hex :Hex) {
        var tile = hex_to_tile(hex);
        if (tile == null) return null;
        for (e in entities) {
            if (pos_to_hex(e.pos).key == hex.key) return e;
        }
        return null;
    }

    public function is_blocked(hex :Hex) {
        var tile = hex_to_tile(hex);
        if (tile == null) return true;
        if (tile.has('Blocked')) return true;
        return false;
    }

    public function hex_to_tile(hex :Hex) :HexTile {
        return hexMap[hex.key];
    }

    public function mouseWorldPos(pos :Vector) :Vector {
        var r = Luxe.camera.view.screen_point_to_ray(pos);
        var result = Luxe.utils.geometry.intersect_ray_plane(r.origin, r.dir, new Vector(0, 0, 1), new Vector());
        result.z = 0;
        return result;
    }

    public function pos_to_hex(world_pos :Vector) :Hex {
        var fractionalHex = Layout.pixelToHex(layout, new Point(world_pos.x, world_pos.y));
        return FractionalHex.hexRound(fractionalHex);
    }

    public function get_path(start :Hex, end :Hex) :Array<Hex> {
        return start.find_path(end, 100, 6, is_walkable);
    }

    public function get_reachable(start :Hex, range :Int) :Array<Hex> {
        return start.reachable(is_walkable, range);
    }

    override function onmousemove(event :MouseEvent) {
        var world_pos = mouseWorldPos(event.pos);
        var hex = pos_to_hex(world_pos);
        events.fire(HEX_MOUSEMOVED_EVENT, hex);
    }

    override function onmouseup(event :MouseEvent) {
        var world_pos = mouseWorldPos(event.pos);
        var hex = pos_to_hex(world_pos);
        if (hex_to_tile(hex) == null) return;
        events.fire(HEX_CLICKED_EVENT, hex);
    }
}

class BattleState extends State {
    static public var StateId :String = 'BattleState';

    var battleMap :BattleMap;

    public function new() {
        super({ name: StateId });
        battleMap = new BattleMap();
    }

    override function init() {
        setup_map();
        setup_hand();
    }

    function select(p :Piece) {
        Main.states.set(PieceActionState.StateId, { battleMap: battleMap, piece: p });
    }

    function selectCard(c :Card) {
        Main.states.set(CardCastState.StateId, { battleMap: battleMap, card: c });
    }

    function setup_map() {
        var heroPos = Layout.hexToPixel(battleMap.layout, new Hex(-1, 0, 0));
        var hero = new Hero({ power: 7, pos: new Vector(heroPos.x, heroPos.y), color: new Color(229/255, 83/255, 118/255),/* scene: levelScene, */ depth: 2 });
        hero.add(new Selectable(select));

        var minionPos = Layout.hexToPixel(battleMap.layout, new Hex(-2, 1, 0));
        var minion = new Minion({
            power: 2,
            pos: new Vector(minionPos.x, minionPos.y),
            color: new Color(129/255, 83/255, 118/255),
            depth: 2
        });
        minion.add(new Selectable(select));

        var enemyPos = Layout.hexToPixel(battleMap.layout, new Hex(3, -2, 0));
        var enemy = new Hero({ power: 8, pos: new Vector(enemyPos.x, enemyPos.y), color: new Color(1, 0, 0), depth: 2 });

        battleMap.entities.push(hero);
        battleMap.entities.push(minion);
        battleMap.entities.push(enemy);
    }

    function setup_hand() {
        function nothing(hex) {}

        function create_minion(hex) {
            var minionPos = Layout.hexToPixel(battleMap.layout, hex);
            var minion = new Minion({
                power: 3,
                pos: new Vector(minionPos.x, minionPos.y),
                color: new Color(129/255, 83/255, 118/255),
                depth: 2
            });
            minion.add(new Selectable(select));

            battleMap.entities.push(minion);
        }
        var card1 = new Card({ pos: new Vector(200, 600), depth: 3, effect: create_minion });
        var card2 = new Card({ pos: new Vector(320, 600), depth: 3, effect: create_minion });
        var card3 = new Card({ pos: new Vector(440, 600), depth: 3, effect: create_minion });
        card1.add(new SelectableCard(selectCard));
        card2.add(new SelectableCard(selectCard));
        card3.add(new SelectableCard(selectCard));
    }
}

class PieceActionState extends State {
    static public var StateId :String = 'PieceActionState';

    var battleMap :BattleMap;
    var path_dots :Array<Vector>;
    var reachable_dots :Array<Vector>;
    var attack_dots :Array<Vector>;
    var selected :Piece;

    var mouseMoveEvent :String;
    var clickEvent :String;

    public function new() {
        super({ name: StateId });
        path_dots = [];
        reachable_dots = [];
        attack_dots = [];
    }

    function select(p :Piece) {
        if (selected != null) selected.remove('Selected');
        if (selected == p) {
            selected = null;
            return;
        }
        selected = p;
        selected.add(new Selected({ name: 'Selected' }));

        var hex = battleMap.pos_to_hex(selected.pos);
        var reachable = battleMap.get_reachable(hex, 2);
        reachable_dots = [ for (r in reachable) {
            var pos = Layout.hexToPixel(battleMap.layout, r);
            new Vector(pos.x, pos.y);
        }];

        attack_dots = [];
        for (a in hex.ring(1)) {
            var entity = battleMap.get_entity(a);
            if (entity == null) continue;
            var pos = Layout.hexToPixel(battleMap.layout, a);
            attack_dots.push(new Vector(pos.x, pos.y));
        }
    }

    override function onenter<T>(_data :T) {
        trace('PieceActionState::onenter');
        var data :{ battleMap :BattleMap, piece :Piece } = cast _data;
        battleMap = data.battleMap;

        setup();

        select(data.piece);
    }

    override function onleave<T>(_data :T) {
        trace('PieceActionState::onleave');
        battleMap.events.unlisten(mouseMoveEvent);
        battleMap.events.unlisten(clickEvent);
    }

    function setup() {
        function get_path_positions(hex) {
            if (selected == null) return [];
            var hero_hex = battleMap.pos_to_hex(selected.pos);
            return battleMap.get_path(hero_hex, hex);
        }

        mouseMoveEvent = battleMap.events.listen(BattleMap.HEX_MOUSEMOVED_EVENT, function(hex :Hex) {
            if (selected == null) return;
            path_dots = [];
            if (battleMap.hex_to_tile(hex) == null)  return;
            for (p in get_path_positions(hex)) {
                var pos = Layout.hexToPixel(battleMap.layout, p);
                path_dots.push(new Vector(pos.x, pos.y));
            }
        });

        clickEvent = battleMap.events.listen(BattleMap.HEX_CLICKED_EVENT, function(hex :Hex) {
            if (selected == null) return;

            // Attack
            var entity = battleMap.get_entity(hex);
            if (entity != null && entity != selected) { // TODO: Check that it's the other player's entity
                entity.destroy();
                return;
            }

            // Move
            var path = get_path_positions(hex);
            if (path.length == 0) return;
            path_dots = [];
            reachable_dots = [];
            attack_dots = [];
            var count :Int = 0;
            var timePerHex :Float = 0.2;
            for (p in path) {
                var tile = battleMap.hex_to_tile(p);
                Luxe.timer.schedule(count * timePerHex, function() {
                    luxe.tween.Actuate.tween(selected.pos, timePerHex, { x: tile.pos.x, y: tile.pos.y });
                    // var this_hex = battleMap.pos_to_hex(tile.pos);
                    // var enemy_hex = battleMap.pos_to_hex(enemy.pos);
                    // if (this_hex.key == enemy_hex.key) enemy.destroy();
                });
                count++;
            }
        });
    }

    override function onrender() {
        for (dot in reachable_dots) {
            Luxe.draw.circle({
                x: dot.x,
                y: dot.y,
                r: 10,
                color: new Color(0.8, 0.8, 1.0),
                immediate: true,
                depth: 10
            });
        }
        for (dot in path_dots) {
            Luxe.draw.circle({
                x: dot.x,
                y: dot.y,
                r: 20,
                immediate: true,
                depth: 10
            });
        }
        for (dot in attack_dots) {
            Luxe.draw.circle({
                x: dot.x,
                y: dot.y,
                r: 25,
                color: new Color(1.0, 0.6, 0.6),
                immediate: true,
                depth: 10
            });
        }
    }
}

class CardCastState extends State {
    static public var StateId :String = 'CardCastState';

    var battleMap :BattleMap;
    var selectedCard :Card;
    var clickEvent :String;

    public function new() {
        super({ name: StateId });
    }

    function selectCard(c :Card) {
        if (selectedCard != null) selectedCard.remove('SelectedCard');
        if (selectedCard == c) {
            selectedCard = null;
            return;
        }
        selectedCard = c;
        selectedCard.add(new SelectedCard({ name: 'SelectedCard' }));
    }

    override function onenter<T>(_data :T) {
        trace('CardCastState::onenter');
        var data :{battleMap :BattleMap, card :Card} = cast _data;
        battleMap = data.battleMap;

        setup();

        selectCard(data.card);
    }

    override function onleave<T>(_data :T) {
        trace('CardCastState::onleave');
        battleMap.events.unlisten(clickEvent);
    }

    function setup() {
        clickEvent = battleMap.events.listen(BattleMap.HEX_CLICKED_EVENT, function(hex :Hex) {
            if (selectedCard == null) return;
            selectedCard.trigger(hex);
            selectedCard.destroy();
            Main.states.set(BattleState.StateId);
        });
    }
}

typedef PieceOptions = {
    > VisualOptions,
    power: Int
};
class Piece extends Visual {
    public function new(options :PieceOptions) {
        var _options = options;
        if (_options.color == null) _options.color = new Color(0, 0.5, 0.5);
        super(_options);

        new luxe.Text({
            text: '' + _options.power,
            align: luxe.Text.TextAlign.center,
            align_vertical: luxe.Text.TextAlign.center,
            parent: this,
            depth: _options.depth + 0.01
        });
    }
}

class Hero extends Piece {
    public function new(options :PieceOptions) {
        var _options = options;
        if (_options.geometry == null) _options.geometry = Luxe.draw.circle({ r: 40 });
        super(_options);
    }
}

class Minion extends Piece {
    public function new(options :PieceOptions) {
        var _options = options;
        if (_options.geometry == null) _options.geometry = Luxe.draw.circle({ r: 30 });
        super(_options);
    }
}

typedef CardOptions = {
    > luxe.options.SpriteOptions,
    effect: Hex->Void
}

class Card extends luxe.Sprite {
    var _options :CardOptions;

    public function new(options :CardOptions) {
        _options = options;
        if (_options.color == null) _options.color = new Color(0, 0.5, 0.5);
        if (_options.geometry == null) _options.geometry = Luxe.draw.box({
            rect: new luxe.Rectangle(0, 0, 100, 150)
        });
        super(_options);
    }

    public function trigger(hex :Hex) {
        _options.effect(hex);
    }
}

class Selectable extends luxe.Component {
    var func :Piece->Void;
    var piece :Piece;
    var is_mouse_over :Bool = false;

    public function new(f :Piece->Void) {
        super({ name: 'Selectable' });
        func = f;
    }

    override function init() {
        piece = cast entity;
    }

    function is_mouse_over_piece(pos) {
        var r = Luxe.camera.view.screen_point_to_ray(pos);
        var result = Luxe.utils.geometry.intersect_ray_plane(r.origin, r.dir, new Vector(0, 0, 1), new Vector());
        return (Luxe.utils.geometry.point_in_geometry(result, piece.geometry));
    }

    override function onmousemove(event :luxe.Input.MouseEvent) {
        is_mouse_over = is_mouse_over_piece(event.pos);
    }

    override function onmousedown(event :luxe.Input.MouseEvent) {
        if (is_mouse_over_piece(event.pos)) func(piece);
    }

    override function update(dt :Float) {
        if (is_mouse_over) Luxe.draw.circle({ x: entity.pos.x, y: entity.pos.y, r: 42, color: new Color(1, 0.8, 0.8), depth: 1, immediate: true });
    }
}

class Selected extends luxe.Component {
    override function update(dt :Float) {
        Luxe.draw.circle({ x: entity.pos.x, y: entity.pos.y, r: 45, depth: 1, immediate: true });
    }
}

class SelectableCard extends luxe.Component {
    var func :Card->Void;
    var card :Card;
    var is_mouse_over :Bool = false;

    public function new(f :Card->Void) {
        super({ name: 'SelectableCard' });
        func = f;
    }

    override function init() {
        card = cast entity;
    }

    function is_mouse_over_card(pos) {
        var r = Luxe.camera.view.screen_point_to_ray(pos);
        var result = Luxe.utils.geometry.intersect_ray_plane(r.origin, r.dir, new Vector(0, 0, 1), new Vector());
        return (Luxe.utils.geometry.point_in_geometry(result, card.geometry));
    }

    override function onmousemove(event :luxe.Input.MouseEvent) {
        is_mouse_over = is_mouse_over_card(event.pos);
    }

    override function onmouseup(event :luxe.Input.MouseEvent) {
        if (is_mouse_over_card(event.pos)) func(card);
    }

    override function update(dt :Float) {
        if (is_mouse_over) Luxe.draw.box({ rect: new luxe.Rectangle(entity.pos.x - 5, entity.pos.y - 5, 110, 160), color: new Color(1, 0.8, 0.8), depth: 1, immediate: true });
    }
}

class SelectedCard extends luxe.Component {
    override function update(dt :Float) {
        Luxe.draw.box({ rect: new luxe.Rectangle(entity.pos.x - 10, entity.pos.y - 10, 120, 170), depth: 1, immediate: true });
    }
}
