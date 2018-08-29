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
import body;
import stat;

immutable bool debug_can_move_anywhere = false;

class Actor
{
	invariant(body_ !is null);

	mixin Serializable;

	enum base_ap_per_turn = 10;
	enum base_ap_cost = 100;
	enum agility_ap_weight = 10;
	enum dexterity_ap_weight = 10;
	enum hitting_ap_weight = 5;

	/*enum dexterity_hit_chance_weight = 1;
	enum observantness_hit_chance_weight = 1;
	enum striking_hit_chance_weight = 1;
	enum agility_hit_chance_weight = 1;
	enum dodging_hit_chance_weight = 1;
	enum strength_hit_damage_weight = 1;
	enum striking_hit_damage_weight = 1;
	enum dexterity_hit_damage_weight = 1;*/

	enum ap_action_threshold = 100;

	@noser Map map;
	Stats _stats;
	Body body_;
	Array!Item items;
	bool is_despawned = false;

	protected int weapon_index = -1;
	private int ap = 0;
	private int _x, _y;

	abstract bool subupdate(); // Return false if `Map.update()` shall return.
	@property abstract Symbol symbol();
	@property abstract string name();

	// "ap" means "action points". "eff" means "effective".
	@property Stats stats() const pure { return _stats; }
	@property void stats(Stats stats)
	{
		_stats = stats;
		body_.update();
		//body_ = new ActorBody(stats);
	}

	@property int quickness() const pure { return 0; }
	@property int eff_quickness() const pure
		{ return quickness + stats[Stat.reflex]; }
	@property int ap_per_turn() const pure
		{ return base_ap_per_turn + eff_quickness; }

	@property int hit_chance_bonus() const pure
	{
		return stats[Stat.dexterity]
			+ stats[Stat.striking]
			+ stats[Stat.observantness];
		/*dexterity_hit_chance_weight*stats[Stat.dexterity]
		+ striking_hit_chance_weight*stats[Stat.striking]
		+ observantness_hit_chance_weight*stats[Stat.observantness]
		- agility_hit_chance_weight*target.stats[Stat.agility]
		- dodging_hit_chance_weight*target.stats[Stat.dodging])) {*/
	}

	@property int evasion_chance_bonus() const pure
	{
		return stats[Stat.agility]
			+ stats[Stat.observantness]
			+ stats[Stat.dodging];
	}

	@property int hit_damage_bonus() const pure
	{
		return stats[Stat.strength]
			+ stats[Stat.striking];
			//+ stats[Stat
			/*scaledSigmoid(weapon.blunt_hit_damage,
			strength_hit_damage_weight*stats[Stat.strength]
			+ striking_hit_damage_weight*stats[Stat.striking]
			+ scaledSigmoid(weapon.sharp_hit_damage,
			+ strength_hit_damage_weight*stats[Stat.strength]
			+ striking_hit_damage_weight*stats[Stat.striking]
			+ dexterity_hit_damage_weight*stats[Stat.dexterity])*/
	}

	@property int x() const pure { return _x; }
	@property int y() const pure { return _y; }

	this(Stats stats = Stats())
	{
		//stats = Stats();
		//items = Array!Item();
		this.stats = stats;
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
		body_.update();
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
		debug writeln(x, " ", y, " ", map.getTile(x, y).zone);
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
	// The `act*` methods shall be designed to never throw errors.

	bool actWait()
		in(map !is null)
	{
		return true;
	}

	bool actMoveTo(int x, int y)
		in(map !is null)
	{
		// Must be adjacent.
		if (abs(x-_x) > 1 || abs(y-_y) > 1) {
			return false;
		}
		// XXX: If `map` is null, then an exception is thrown.
		// How is that """save"""?
		if (!debug_can_move_anywhere
		&& !map.getTile(x, y).is_walkable
		|| map.getTile(x, y).actor !is null) {
			return false;
		}
		setPos(x, y);

		ap -= base_ap_cost - agility_ap_weight*stats[Stat.agility];
		return true;
	}
	bool actMoveTo(Point p)
		in(map !is null)
		{ return actMoveTo(p.x, p.y); }

	bool actOpen(int x, int y)
		in(map !is null)
	{
		// Must be adjacent.
		if (abs(x-_x) > 1 || abs(y-_y) > 1) {
			return false;
		}
		if (!map.getTile(x, y).open()) {
			return false;
		}

		ap -= base_ap_cost - dexterity_ap_weight*stats[Stat.dexterity];
		return true;
	}
	bool actOpen(Point p)
		in(map !is null)
		{ return actOpen(p.x, p.y); }

	bool actPickUp(int index)
		in(map !is null)
	{
		if (index < 0 || index >= map.getTile(x, y).items.length) {
			return false;
		}
		auto item = map.getTile(x, y).items[index];
		auto range = map.getTile(x, y).items[index..index+1];
		map.getTile(x, y).items.linearRemove(range);
		items.insertBack(item);
		
		ap -= base_ap_cost - dexterity_ap_weight*stats[Stat.dexterity];
		return true;
	}

	bool actDrop(int index)
		in(map !is null)
	{
		if (index < 0 || index >= items.length) {
			return false;
		}
		auto item = items[index];
		auto range = items[index..index+1];
		items.linearRemove(range);
		map.getTile(x, y).items.insertBack(item);

		ap -= base_ap_cost - dexterity_ap_weight*stats[Stat.dexterity];
		return true;
	}

	bool actWield(int index)
		in(map !is null)
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
		in(map !is null)
	{
		auto target = map.getTile(x, y).actor;
		if (target is null) {
			ap -= base_ap_cost
				- dexterity_ap_weight*stats[Stat.dexterity]
				- hitting_ap_weight*stats[Stat.striking];
			map.game.sendVisibleEventMsg(target.x, target.y,
				format("%s hits thin air.", name), Color.red, true);
			return true;
		}
		/*if (sigmoidChance(
		dexterity_hit_chance_weight*stats[Stat.dexterity]
		+ striking_hit_chance_weight*stats[Stat.striking]
		+ observantness_hit_chance_weight*stats[Stat.observantness]
		- agility_hit_chance_weight*target.stats[Stat.agility]
		- dodging_hit_chance_weight*target.stats[Stat.dodging])) {*/
		if (sigmoidChance(hit_chance_bonus-target.evasion_chance_bonus)) {
			if (weapon_index != -1 && items[weapon_index].is_hit) {
				auto weapon = items[weapon_index];
				Strike strike;

				// TODO: Use effective stats instead.
				// TODO: Split the calculation into several smaller ones.
				/*target.hp -= uniform!"[]"(0, max(0,
					scaledSigmoid(weapon.blunt_hit_damage,
					strength_hit_damage_weight*stats[Stat.strength]
					+ striking_hit_damage_weight*stats[Stat.striking]
					+ scaledSigmoid(weapon.sharp_hit_damage,
					+ strength_hit_damage_weight*stats[Stat.strength]
					+ striking_hit_damage_weight*stats[Stat.striking]
					+ dexterity_hit_damage_weight*stats[Stat.dexterity])
					)));*/

				foreach (int i, ref e; strike) {
					e = uniform!"[]"(0, scaledSigmoid(weapon.hit_max_strike[i],
						hit_damage_bonus+weapon.hit_damage_bonus));
					//writeln(weapon.hit_max_damage[i]);
					writeln("q");
					writeln(e);
				}

				// Torso can be choosen 2 times more likely than each other part.
				HumanFleshyBodyPart part = [
					HumanFleshyBodyPart.left_arm,
					HumanFleshyBodyPart.right_arm,
					HumanFleshyBodyPart.left_leg,
					HumanFleshyBodyPart.right_leg,
					HumanFleshyBodyPart.head,
					HumanFleshyBodyPart.torso,
					HumanFleshyBodyPart.torso].choice(rng);

				target.body_.dealStrike(target.stats, part, strike);
				
				map.game.sendVisibleEventMsg(target.x, target.y,
					format("%s hits %s.", name, target.name),
					Color.red, true);
				return true;
			}
			// For now, you cannot hit without a weapon.
			// TODO: Change this.
		}
		map.game.sendVisibleEventMsg(target.x, target.y,
			format("%s misses %s.", name, target.name), Color.red, true);
		return true;
	}

	bool actHit(Point p)
		in(map !is null)
		{ return actHit(p.x, p.y); }

	float getDistance(int x, int y) const pure
	{
		return sqrt(cast(float)((x-this.x)^^2+(y-this.y)^^2));
	}
	float getDistance(Point p) const pure
		{ return getDistance(p.x, p.y); }
	float getDistance(const Actor target) const pure
		{ return getDistance(target.x, target.y); }
}
