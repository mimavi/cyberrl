import std.container;
import std.math;
import util;
import term;
import serializer;
import main;
import menu;
import item;
import game;

// XXX: I think this mixin business would be considered ugly by some people.
// Any better idea how to handle this better?

private string statMinus5To5Mixin(string name, string displayed_name)
{
	return "private int _"~name~";"
	~"@property int "~name~"() { return _"~name~"; }"
	~"string "~name~"_str()"
	~"{ return val_to_minus_5_to_5_adjective[_"~name~"]~\" "
	~displayed_name~"\"; }";
}

private string stat0To5Mixin(string name, string displayed_name)
{
	return "private int _"~name~";"
	~"@property int "~name~"() { return _"~name~"; }"
	~"string "~name~"_str()"
	~"{ return val_to_0_to_5_adjective[_"~name~"]~\" "
	~displayed_name~"\"; }";
}

// XXX: Perhaps this should be a struct,
// or maybe even just an associative array?
class ActorStats
{
	// The body attributes.
	mixin (statMinus5To5Mixin("strength", "strength"));
	mixin (statMinus5To5Mixin("dexterity", "dexterity"));
	mixin (statMinus5To5Mixin("agility", "agility"));
	mixin (statMinus5To5Mixin("endurance", "endurance"));
	// The mind attributes.
	mixin (statMinus5To5Mixin("reflex", "reflex"));
	mixin (statMinus5To5Mixin("observantness", "observantness"));
	mixin (statMinus5To5Mixin("intelligence", "intelligence"));
	// The technical skills.
	mixin (stat0To5Mixin("constructing", "constructing"));
	mixin (stat0To5Mixin("repairing", "repairing"));
	mixin (stat0To5Mixin("modding", "modding"));
	mixin (stat0To5Mixin("hacking", "hacking"));
	// The combat skills.
	mixin (stat0To5Mixin("striking", "striking"));
	mixin (stat0To5Mixin("aiming", "aiming"));
	mixin (stat0To5Mixin("extrapolating", "extrapolating"));
	mixin (stat0To5Mixin("throwing", "throwing"));
	mixin (stat0To5Mixin("dodging", "dodging"));
	// The knowledges.
	mixin (stat0To5Mixin("ballistics", "ballistics"));
	mixin (stat0To5Mixin("explosives", "explosives"));
	mixin (stat0To5Mixin("lasers", "lasers"));
	mixin (stat0To5Mixin("plasma", "plasma"));
	mixin (stat0To5Mixin("electromagnetism", "electromagnetism"));
	mixin (stat0To5Mixin("computers", "computers"));
	//int strength, agility, endurance; // The body attributes.
	//int reactiontime, observantness, intelligence; // The mind attributes.
	//int constructing, repairing, hacking, modding; // The technical skills.
	//int striking, aiming, throwing, dodging; // The combat skills.
	//int ballistics, laser, plasma, electromagnetism; // The knowledges.
}

class Actor// : Saved
{
	mixin Serializable;
	@noser Game game;
	Array!Item items;
	bool is_despawned = false;
	private int _x, _y;

	abstract void update();
	@property abstract Symbol symbol();

	@property int x() { return _x; }
	@property int y() { return _y; }

	this()
	{
		items = Array!Item();
	}

	this(Serializer serializer) { this(); }

	/*this(Serializer serializer)
	{
		load(serializer);
	}*/

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
	// The `act*` methods shall be designed to be completely safe.
	// No matter what input they get, they MUST NOT throw any exception,
	// error or cause any crashing or freezing.

	bool actMoveTo(int x, int y)
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

	bool actPickUp(int index)
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

	bool actDrop(int index)
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
	mixin InheritedSerializable;
	override @property Symbol symbol() { return Symbol('@'); }

	this() {}
	this(Serializer serializer) { this(); }

	/*this(Serializer serializer)
	{
		load(serializer);
	}*/

	/*static PlayerActor make(Serializer serializer)
	{
		return new PlayerActor(serializer);
	}*/

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
					actMoveTo(x+util.key_to_x[key], y+util.key_to_y[key]);
			} else if (key == Key.g) {
				int index;
				if (menu.selectItem(game.map.getTile(x, y).items,
					"Select item to pick up:", index))
				{
					has_acted = actPickUp(index);
				}
			} else if (key == Key.d) {
				int index;
				if (menu.selectItem(items,
					"Select item to drop:", index))
				{
					has_acted = actDrop(index);
				}
			}
		} while(!has_acted);

	}
}

class AiActor : Actor
{
	/*this(Serializer serializer)
	{
		load(serializer);
	}*/

	override void update()
	{

	}
}
