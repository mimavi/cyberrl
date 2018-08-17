import std.algorithm.comparison;
import std.container;
import std.random;
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
	int[ActorStat.max+1] stats; // All 0 by default.
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

	enum base_ap_per_turn = 10;
	enum base_ap_cost = 100;
	enum agility_ap_weight = 10;
	enum dexterity_ap_weight = 10;
	enum ap_action_threshold = 100;

	@noser Map map;
	ActorStats stats;
	Array!Item items;
	bool is_despawned = false;

	private int ap = 0;
	private int _x, _y;

	abstract bool subupdate(); // Return false if `Map.update()` shall return.
	@property abstract Symbol symbol();

	// "ap" means "action points". "eff" means "effective".
	@property int quickness() { return 0; }
	@property int eff_quickness()
		{ return quickness + stats[ActorStat.reflex]; }
	@property int ap_per_turn() { return base_ap_per_turn + eff_quickness; }

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

	// Return false if `Map.update()` shall return.
	bool update()
	{
		ap += ap_per_turn;
		if (ap >= ap_action_threshold) {
			ap -= ap_action_threshold;
			return subupdate();
		}
		return true;
	}

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

	bool actWait()
	{
		return true;
	}

	bool actMoveTo(int x, int y)
	{
		// Must be an adjacent tile.
		if (abs(x-_x) > 1 || abs(y-_y) > 1) {
			return false;
		}
		// XXX: If `map` is null, then an exception is thrown.
		// How is that """save"""?
		if (map.getTile(x, y).is_blocking
		|| map.getTile(x, y).actor !is null) {
			return false;
		}
		setPos(x, y);

		ap -= base_ap_cost - agility_ap_weight*stats[ActorStat.agility];
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
		
		ap -= base_ap_cost - dexterity_ap_weight*stats[ActorStat.dexterity];
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

		ap -= base_ap_cost - dexterity_ap_weight*stats[ActorStat.dexterity];
		return true;
	}
}

class PlayerActor : Actor
{
	mixin InheritedSerializable;

	@property override Symbol symbol()
		{ return Symbol('@', Color.white, Color.black, true); }

	this() {}
	this(Serializer serializer) { this(); }

	override void initPos(int x, int y)
	{
		super.initPos(x, y);
		main_game.centerizeCamera(x, y);
	}

	override bool subupdate()
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
					"Select item to pick up:", index)) {
					has_acted = actPickUp(index);
				}
			} else if (key == Key.d) {
				int index;
				if (menu.selectItem(items,
					"Select item to drop:", index)) {
					has_acted = actDrop(index);
				}
			} else if (key == Key.period) {
				has_acted = actWait();
			}
		} while (!has_acted);
		return true;
	}
}

class AiActor : Actor
{
	mixin InheritedSerializable;

	enum max_action_attempts_num = 100;

	override bool subupdate()
	{
		aiMeander();
		return true;
	}

	void aiMeander()
	{
		bool has_acted = false;
		// TODO: Timeout when too many attempts fail.
		for (int i = 0; !has_acted && i < max_action_attempts_num; ++i) {
			has_acted
				= actMoveTo(x+1-uniform(0, 3, rng), y+1-uniform(0, 3, rng));
		}
	}
}

class LightsamuraiAiActor : AiActor
{
	mixin InheritedSerializable;

	this() {}
	this(Serializer serializer) {}

	@property override Symbol symbol()
		{ return Symbol('@', Color.magenta, true); }

}
