static import term;
static import map;
import std.stdio;

void main()
{
	try {
		map.Map _map = new map.Map(23, 23);
		_map.dummyGen();
		foreach (y; 0.._map.height) {
			foreach (x; 0.._map.width) {
				term.setSymbol(x, y, term.Symbol(_map.cell(x, y).tile_type == map.Tile.floor ? '.' : '#',
					term.Color.white, term.Color.black, false));
			}
		}
	}
	catch (Error e) {
		term.print(0, 0, e.msg, term.Color.white, term.Color.black, false, 30);
		term.readKey();
		return;
	}
	term.print(10, 10, "Hello World!", term.Color.yellow, term.Color.black, true, 30);
	term.readKey();
}
