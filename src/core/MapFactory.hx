package core;

import core.HexLibrary;

class MapFactory {
    static public function create_custom_map() :Array<Hex> {
        var hexes = create_hexagon_map(2);
        hexes.push(new Hex(1, -2));
        hexes.push(new Hex(-1, 2));
        return hexes;
    }

    static public function create_hexagon_map(radius :Int = 3) :Array<Hex> {
        var hexes = [];
        for (q in -radius + 1 ... radius) {
            var r1 = Math.round(Math.max(-radius, -q - radius));
            var r2 = Math.round(Math.min(radius, -q + radius));
            for (r in r1 + 1 ... r2) {
                hexes.push(new Hex(q, r, -q - r));
            }
        }
        return hexes;
    }

    static public function create_rectangular_map(width :Int = 3, height :Int = 3) :Array<Hex> {
        var hexes = [];
        var w = Math.floor(width / 2);
        var h = Math.floor(height / 2);
        for (r in -h ... h + 1) {
            var r_offset = Math.floor(r / 2);
            for (q in -r_offset - w ... w - r_offset + 1) {
                hexes.push(new Hex(q, r, -q - r));
            }
        }
        return hexes;
    }
}
