import util;
import term;
import main;
import map;
import std.math;

class Actor
{
	Map map;
	private int _x, _y;

	abstract void update();
	abstract void draw(int x, int y);

	this(Map map, int x, int y)
	{
		this.map = map;
		_x = x;
		_y = y;
		map.actors.insert(this);
		map.get_tile(x, y).actor = this;
	}

	@property int x() { return _x; }
	@property int y() { return _y; }

	void set_pos(int x, int y)
	{
		map.get_tile(_x, _y).actor = null;
		map.get_tile(x, y).actor = this;
		_x = x;
		_y = y;
	}

	bool act_move(int x, int y)
	{
		// Must be an adjacent tile.
		if (abs(x-_x) > 1 || abs(y-_y) > 1) {
			return false;
		}

		if (map.get_tile(x, y).is_blocking
		|| map.get_tile(x, y).actor !is null) {
			return false;
		}
		set_pos(x, y);
		return true;
	}
}

class PlayerActor : Actor
{
	this(Map map, int x, int y)
	{
		super(map, x, y);
	}

	override void set_pos(int x, int y)
	{
		super.set_pos(x, y);
		main_game.centerizeCamera(x, y);
	}

	override void update()
	{
		auto key = term.readKey();
		if (key >= Key.digit_1 && key <= Key.digit_9) {
			act_move(x+util.key_to_x[key], y+util.key_to_y[key]);
		}
	}

	override void draw(int x, int y)
	{
		term.setSymbol(x, y, Symbol('@', Color.white, Color.black, false));
	}
}

class AiActor : Actor
{
	this(Map map, int x, int y)
	{
		super(map, x, y);
	}

	override void update()
	{

	}

	override void draw(int x, int y)
	{

	}
}
