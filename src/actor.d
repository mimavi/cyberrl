import std.container;
import std.math;
import util;
import term;
import main;
import menu;
import item;
import game;

class Actor
{
	Game game;
	@("Saved") Array!Item items;
	bool is_despawned = false;
	private int _x, _y;

	abstract void update();
	abstract @property Symbol symbol();

	@property int x() { return _x; }
	@property int y() { return _y; }

	this()
	{
		items = Array!Item();
	}

	void draw(int x, int y)
	{
		term.setSymbol(x, y, symbol);
	}

	void initPos(int x, int y)
	{
		game.map.getTile(x, y).actor = this;
		_x = x;
		_y = y;
	}

	void setPos(int x, int y)
	{
		game.map.getTile(_x, _y).actor = null;
		initPos(x, y);
	}

	// NOTE:
	// `act_*` methods are designed to be completely safe.
	// No matter what input they get, they MUST NOT throw any exception,
	// error or cause crashing or freezing.

	bool act_move_to(int x, int y)
	{
		// Must be an adjacent tile.
		if (abs(x-_x) > 1 || abs(y-_y) > 1) {
			return false;
		}

		if (game.map.getTile(x, y).is_blocking
		|| game.map.getTile(x, y).actor !is null) {
			return false;
		}
		setPos(x, y);
		return true;
	}

	bool act_pick_up(int index)
	{
		if (index < 0 || index >= game.map.getTile(x, y).items.length) {
			return false;
		}
		auto item = game.map.getTile(x, y).items[index];
		auto range = game.map.getTile(x, y).items[index..index+1];
		game.map.getTile(x, y).items.linearRemove(range);
		items.insertBack(item);
		return true;
	}

	bool act_drop(int index)
	{
		if (index < 0 || index >= items.length) {
			return false;
		}
		auto item = items[index];
		auto range = items[index..index+1];
		items.linearRemove(range);
		game.map.getTile(x, y).items.insertBack(item);
		return true;
	}
}

class PlayerActor : Actor
{
	override @property Symbol symbol() { return Symbol('@'); }
	override void initPos(int x, int y)
	{
		super.initPos(x, y);
		main_game.centerizeCamera(x, y);
	}

	override void update()
	{
		bool has_acted = false;
		do {
			main_game.draw();
			auto key = term.readKey();
			if (key >= Key.digit_1 && key <= Key.digit_9) {
				has_acted = 
					act_move_to(x+util.key_to_x[key], y+util.key_to_y[key]);
			} else if (key == Key.g) {
				int index;
				if (menu.select_item(game.map.getTile(x, y).items,
					"Select item to pick up:", index))
				{
					has_acted = act_pick_up(index);
				}
			} else if (key == Key.d) {
				int index;
				if (menu.select_item(items,
					"Select item to drop:", index))
				{
					has_acted = act_drop(index);
				}
			}
		} while(!has_acted);

	}
}

class AiActor : Actor
{
	override void update()
	{

	}
}
