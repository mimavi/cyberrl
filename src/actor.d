import std.algorithm.comparison;
import std.container;
import std.math;
import util;
import term;
import serializer;
import main;
import menu;
import item;
import map;

// XXX: Perhaps this should be renamed to something clearer, i.e.
// `ActorStatIndex`.
enum ActorStat
{
	none = -1,
	// The attributes.
	attributes_min,
		strength = attributes_min,
		dexterity,
		agility,
		endurance,
		reflex,
		observantness,
		intelligence,
	attributes_max = intelligence,

	// The technical skills.
	technical_skills_min,
		constructing = technical_skills_min,
		repairing,
		modding,
		hacking,
	technical_skills_max = hacking,

	// The combat skills.
	combat_skills_min,
		striking = combat_skills_min,
		aiming,
		extrapolating,
		throwing,
		dodging,
	combat_skills_max = dodging,

	// The knowledges.
	knowledges_min,
		ballistics = knowledges_min,
		explosives,
		lasers,
		plasma,
		electromagnetism,
		computers,
	knowledges_max = computers,
}

struct ActorStats
{
	mixin Serializable;
	enum attribute_min = -5;
	enum attribute_max = 5;
	enum skill_min = 0;
	enum skill_max = 5;
	enum knowledge_min = 0;
	enum knowledge_max = 5;
	enum names = [
		ActorStat.strength: "strength",
		ActorStat.dexterity: "dexterity",
		ActorStat.agility: "agility",
		ActorStat.endurance: "endurance",
		ActorStat.reflex: "reflex",
		ActorStat.observantness: "observantness",
		ActorStat.intelligence: "intelligence",
		ActorStat.constructing: "constructing",
		ActorStat.repairing: "repairing",
		ActorStat.modding: "modding",
		ActorStat.hacking: "hacking",
		ActorStat.striking: "striking",
		ActorStat.aiming: "aiming",
		ActorStat.extrapolating: "extrapolating",
		ActorStat.throwing: "throwing",
		ActorStat.dodging: "dodging",
		ActorStat.ballistics: "ballistics",
		ActorStat.explosives: "explosives",
		ActorStat.lasers: "lasers",
		ActorStat.plasma: "plasma",
		ActorStat.electromagnetism: "electromagnetism",
		ActorStat.computers: "computers",
	];
	int[ActorStat.max+1] stats;
	alias stats this;

	this(Serializer serializer) {}
	void beforesave(Serializer serializer) {}
	void beforeload(Serializer serializer) {}
	void aftersave(Serializer serializer) {}
	void afterload(Serializer serializer) {}

	string toString(ActorStat stat)
	{
		if (stat >= ActorStat.attributes_min
		&& stat <= ActorStat.attributes_max) {
			return val_to_minus_5_to_5_adjective[stats[stat]]
				~" "~names[stat];
		} else if ((stat >= ActorStat.technical_skills_min
		&& stat <= ActorStat.technical_skills_max)
		|| (stat >= ActorStat.combat_skills_min
		&& stat <= ActorStat.combat_skills_max)
		|| (stat >= ActorStat.knowledges_min
		&& stat <= ActorStat.knowledges_max)) {
			return val_to_0_to_5_adjective[stats[stat]]~" "~names[stat];
		}
		assert(false);
	}

	bool trySet(ActorStat stat, int val)
	{
		if (stat >= ActorStat.attributes_min
		&& stat <= ActorStat.attributes_max) {
			if (val > attribute_max || val < attribute_min) {
				return false;
			}
		} else if ((stat >= ActorStat.technical_skills_min
		&& stat <= ActorStat.technical_skills_max)
		|| (stat >= ActorStat.combat_skills_min
		&& stat <= ActorStat.combat_skills_max)) {
			if (val > skill_max || val < skill_min) {
				return false;
			}
		} else if (stat >= ActorStat.knowledges_min
		&& stat <= ActorStat.knowledges_max) {
			if (val > knowledge_max || val < knowledge_min) {
				return false;
			}
		} else {
			assert(false);
		}
		stats[stat] = val;
		return true;
	}
}

class Actor// : Saved
{
	mixin Serializable;
	//@noser Game game;
	@noser Map map;
	ActorStats stats;
	Array!Item items;
	bool is_despawned = false;
	private int _x, _y;

	// Return false if Map.update() should return.
	abstract bool update();
	@property abstract Symbol symbol();

	@property int x() { return _x; }
	@property int y() { return _y; }

	this()
	{
		stats = ActorStats();
		items = Array!Item();
	}

	this(Serializer serializer) { this(); }
	void beforesave(Serializer serializer) {}
	void beforeload(Serializer serializer) {}
	void aftersave(Serializer serializer) {}
	void afterload(Serializer serializer) {}

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
		map.getTile(x, y).actor = this;
		_x = x;
		_y = y;
	}

	void setPos(int x, int y)
	{
		map.getTile(_x, _y).actor = null;
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

		if (map.getTile(x, y).is_blocking
		|| map.getTile(x, y).actor !is null) {
			return false;
		}
		setPos(x, y);
		return true;
	}

	bool actPickUp(int index)
	{
		if (index < 0 || index >= map.getTile(x, y).items.length) {
			return false;
		}
		auto item = map.getTile(x, y).items[index];
		auto range = map.getTile(x, y).items[index..index+1];
		map.getTile(x, y).items.linearRemove(range);
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
		map.getTile(x, y).items.insertBack(item);
		return true;
	}
}

class PlayerActor : Actor
{
	mixin InheritedSerializable;
	override @property Symbol symbol()
	{
		return Symbol('@', Color.white, Color.black, true);
	}

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

	override bool update()
	{
		bool has_acted = false;
		do {
			main_game.draw();
			auto key = term.readKey();
			if (key == Key.escape) {
				if (!menu.inGameMenu(main_game)) {
					return false;
				}
			} else if (key >= Key.digit_1 && key <= Key.digit_9) {
				has_acted = 
					actMoveTo(x+util.key_to_x[key], y+util.key_to_y[key]);
			} else if (key == Key.g) {
				int index;
				if (menu.selectItem(map.getTile(x, y).items,
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
		
		return true;
	}
}

class AiActor : Actor
{
	/*this(Serializer serializer)
	{
		load(serializer);
	}*/

	override bool update()
	{
		return true;
	}
}
