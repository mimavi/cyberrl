enum Tile
{
	floor,
	wall
}

class Cell
{
	Tile tile_type;
}

class Map
{
	@property size_t width() { return _width; }
	@property size_t height() { return _height; }

	ref Cell cell(size_t x, size_t y) { return _array[x+y*_width]; }

	this(size_t width, size_t height) {
		_width = width;
		_height = height;
		_array.length = width*height;
		foreach (y; 0..height) {
			foreach (x; 0..width) {
				cell(x, y) = new Cell;
			}
		}
	}

	void dummyGen() {
		foreach (x; 0..width) {
			cell(x, 0).tile_type = Tile.wall;
			cell(x, height-1).tile_type = Tile.wall;
		}
		foreach (y; 0..height) {
			cell(0, y).tile_type = Tile.wall;
			cell(width-1, y).tile_type = Tile.wall;
		}
	}

	private size_t _width, _height;
	private Cell[] _array;
}
