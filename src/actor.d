import std.algorithm.comparison;
import std.container;
import std.format; // TODO: Don't use `format` function here.

import std.random;
import std.math;
import util;
import ser;
import term;
import map;
import tile;
import item;

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
	mixin SimplySerialized;
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

class Actor
{
	mixin Serializable;

	enum base_ap_per_turn = 10;
	enum base_ap_cost = 100;
	enum agility_ap_weight = 10;
	enum dexterity_ap_weight = 10;
	enum hitting_ap_weight = 5;

	enum dexterity_hit_chance_weight = 1;
	enum observantness_hit_chance_weight = 1;
	enum striking_hit_chance_weight = 1;
	enum agility_hit_chance_weight = 1;
	enum dodging_hit_chance_weight = 1;
	enum strength_hit_damage_weight = 1;
	enum striking_hit_damage_weight = 1;
	enum dexterity_hit_damage_weight = 1;

	enum ap_action_threshold = 100;

	@noser Map map;
	ActorStats stats;
	Array!Item items;
	bool is_despawned = false;

	int max_hp;
	int hp;

	protected int weapon_index = -1;
	private int ap = 0;
	private int _x, _y;

	abstract bool subupdate(); // Return false if `Map.update()` shall return.
	@property abstract Symbol symbol();
	@property abstract string name();

	// "ap" means "action points". "eff" means "effective".
	@property int quickness() { return 0; }
	@property int eff_quickness()
		{ return quickness + stats[ActorStat.reflex]; }
	@property int ap_per_turn() { return base_ap_per_turn + eff_quickness; }

	@property int x() { return _x; }
	@property int y() { return _y; }

	this()
	{
		//stats = ActorStats();
		//items = Array!Item();
		hp = max_hp;
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

	final void draw(int x, int y)
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
	bool actMoveTo(Point p) { return actMoveTo(p.x, p.y); }

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

	bool actWield(int index)
	{
		if (index < 0 || index >= items.length) {
			return false;
		}
		weapon_index = index;
		return true;
	}

	// TODO: If either attacker or target is not visible,
	// then properly replace their name with some replacement,
	// e.g. "somebody".
	bool actHit(int x, int y)
	{
		auto target = map.getTile(x, y).actor;
		if (target is null) {
			ap -= base_ap_cost
				- dexterity_ap_weight*stats[ActorStat.dexterity]
				- hitting_ap_weight*stats[ActorStat.striking];
			map.game.sendVisibleEventMsg(target.x, target.y,
				format("%s hits thin air.", name), Color.red, true);
			return true;
		}
		if (sigmoidChance(
		dexterity_hit_chance_weight*stats[ActorStat.dexterity]
		+ striking_hit_chance_weight*stats[ActorStat.striking]
		+ observantness_hit_chance_weight*stats[ActorStat.observantness]
		- agility_hit_chance_weight*target.stats[ActorStat.agility]
		- dodging_hit_chance_weight*target.stats[ActorStat.dodging])) {
			if (weapon_index != -1 && items[weapon_index].is_hit) {
				auto weapon = items[weapon_index];
				// TODO: Use effective stats instead.
				// TODO: Split the calculation into several smaller ones.
				target.hp -= uniform!"[]"(0, max(0,
					scaledSigmoid(weapon.blunt_hit_damage,
					strength_hit_damage_weight*stats[ActorStat.strength]
					+ striking_hit_damage_weight*stats[ActorStat.striking]
					+ scaledSigmoid(weapon.sharp_hit_damage,
					+ strength_hit_damage_weight*stats[ActorStat.strength]
					+ striking_hit_damage_weight*stats[ActorStat.striking]
					+ dexterity_hit_damage_weight*stats[ActorStat.dexterity])
					)));
				map.game.sendVisibleEventMsg(target.x, target.y,
					format("%s hits %s. hits observes meaningless repeating fast localized square integration", name, target.name),
					Color.red, true);
				return true;
			}
			// For now, you cannot hit without a weapon.
		}
		map.game.sendVisibleEventMsg(target.x, target.y,
			format("%s misses %s.", name, target.name), Color.red, true);
		return true;
	}
	bool actHit(Point p) { return actHit(p.x, p.y); }
}
