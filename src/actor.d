// XXX: Perhaps rename all "bonus" to "mod"?

import std.algorithm.comparison;
import std.container;
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

enum Gender {male, female, neuter}

abstract class Actor
{
	invariant(body_ !is null);

	mixin Serializable;

	enum base_ap_per_turn = 10;
	enum base_ap_cost = 100;
	enum agility_ap_weight = 10;
	enum dexterity_ap_weight = 10;
	enum hitting_ap_weight = 5;

	enum ap_action_threshold = 100;

	@noser Map map;
	bool is_despawned = false;

	/*protected*/ Body body_;
	protected int weapon_index = -1;
	private int ap;
	private int _x, _y;
	private Gender gender = Gender.male;

	@property abstract Symbol symbol() const /*pure*/;
	@property abstract string name() const /*pure*/;
	//@property abstract Strike unarmed_max_strike();
	abstract bool subupdate(); // Return false if `Map.update()` shall return.

	@property string definite_name() const /*pure*/ { return "the "~name; }
	@property string indefinite_name() const /*pure*/
	{
		return prependIndefiniteArticle(name);
	}
	@property string possesive_pronoun() const /*pure*/
	{
		final switch(gender) {
			case Gender.male: return "his";
			case Gender.female: return "her";
			case Gender.neuter: return "its";
		}
	}

	// XXX: Superfluous?
	@property Stats stats() const /*pure*/ { return body_.stats; }
	@property void stats(Stats stats)
	{
		body_.stats = stats;
		//body_.update();
		//body_ = new ActorBody(stats);
	}

	@property int quickness() const /*pure*/ { return 0; }
	@property int eff_quickness() const /*pure*/
		{ return quickness + stats[Stat.reflex]; }
	@property int ap_per_turn() const /*pure*/
		{ return base_ap_per_turn + eff_quickness; }

	@property int hit_chance_bonus() const /*pure*/
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

	@property int evasion_chance_bonus() const /*pure*/
	{
		return stats[Stat.agility]
			+ stats[Stat.observantness]
			+ stats[Stat.dodging];
	}

	@property int hit_damage_bonus() const /*pure*/
	{
		return stats[Stat.strength]
			+ stats[Stat.striking];
	}

	@property int shoot_aim_bonus() const
	{
		return stats[Stat.dexterity] + stats[Stat.aiming];
	}

	@property int x() const /*pure*/ { return _x; }
	@property int y() const /*pure*/ { return _y; }
	@property Point pos() const { return Point(_x, _y); }

	// XXX: Superfluous?
	@property ref Array!Item items() { return body_.items; }

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

	void initPos(int x, int y) /*pure*/
		in(map !is null)
	{
		map.getTile(x, y).actor = this;
		_x = x;
		_y = y;
	}

	void setPos(int x, int y)
		in(map !is null)
	{
		map.getTile(_x, _y).actor = null;
		initPos(x, y);
	}

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

	private string act_hit_prev_damage_str;

	bool actHit(int x, int y)
		in(map !is null)
	{
		auto hittee = map.getTile(x, y).actor;

		if (weapon_index != -1) {
			if (items[weapon_index].tryHit(this, x, y)) {
				ap -= base_ap_cost - dexterity_ap_weight*stats[Stat.dexterity];
				return true;
			}
		} else {
			if (hittee is null) {
				return false;
			}
			if (rollWhetherUnarmedHitImpacts(hittee)) {
				// Torso can be hit 2 times more likely than each other part.
				auto part = [
					HumanFleshyBodyPart.left_arm,
					HumanFleshyBodyPart.right_arm,
					HumanFleshyBodyPart.left_leg,
					HumanFleshyBodyPart.right_leg,
					HumanFleshyBodyPart.head,
					HumanFleshyBodyPart.torso,
					HumanFleshyBodyPart.torso
				].choice(rng);

				onUnarmedHitJustBefore(x, y, part);

				auto strike = rollUnarmedHitStrike();
				hittee.body_.dealStrike(part, strike);
				ap -= base_ap_cost - dexterity_ap_weight*stats[Stat.dexterity];
				onUnarmedHitImpact(x, y, part);
				return true;
			} else {
				ap -= base_ap_cost - dexterity_ap_weight*stats[Stat.dexterity];
				onUnarmedHitMiss(x, y);
				return true;
			}
		}

		return false;
	}
	bool actHit(Point p) { return actHit(p.x, p.y); }

	void onTryHitWeaponCantHit(int x, int y) {}

	void onTryHitNothing(int x, int y) {}

	void onHitJustBefore(int x, int y, int part)
	{
		auto hittee = map.getTile(x, y).actor;
		act_hit_prev_damage_str = hittee.body_.getDamageStr(part);
	}

	void onHitImpact(int x, int y, int part)
		in(map.getTile(x, y).actor !is null)
	{
		auto hittee = map.getTile(x, y).actor;
		string damage_str = hittee.body_.getDamageStr(part);
		if (damage_str == act_hit_prev_damage_str) {
			map.game.sendVisibleEventMsg([pos, hittee.pos], Color.red, true,
				"%1(1)|2$s hits %3(2)|4$s in %5$s %6$s"
				~" with %7$s %8$s!",
				definite_name, "somebody", hittee.definite_name, "somebody",
				hittee.possesive_pronoun, body_.getPartName(part),
				possesive_pronoun, items[weapon_index].name);
		} else {
			map.game.sendVisibleEventMsg([pos, hittee.pos], Color.red, true,
				"%2(1)|1$s hits %3(2)|1$s in %4$s %5$s"
				~" with %6$s %7$s and the part becomes %8$s!",
				"somebody", definite_name, hittee.definite_name,
				hittee.possesive_pronoun, body_.getPartName(part),
				possesive_pronoun, items[weapon_index].name, damage_str);
		}
	}

	void onHitMiss(int x, int y)
		in(map.getTile(x, y).actor !is null)
	{
		auto hittee = map.getTile(x, y).actor;
		map.game.sendVisibleEventMsg(hittee.x, hittee.y, Color.red, false,
			"%1$s misses %2$s", definite_name,
			hittee.definite_name);
	}

	void onUnarmedHitJustBefore(int x, int y, int part)
	{
		onHitJustBefore(x, y, part);
	}

	void onUnarmedHitImpact(int x, int y, int part)
		in(map.getTile(x, y).actor !is null)
	{
		auto hittee = map.getTile(x, y).actor;
		string damage_str = hittee.body_.getDamageStr(part);
		if (damage_str == act_hit_prev_damage_str) {
			map.game.sendVisibleEventMsg([pos, hittee.pos], Color.red, true,
				"%2(1)|1$s hits %3(2)|1$s in %4$s %5$s!",
				"somebody", definite_name, hittee.definite_name,
				hittee.possesive_pronoun, body_.getPartName(part));
		} else {
			map.game.sendVisibleEventMsg([pos, hittee.pos], Color.red, true,
				"%2(1)|1$s hits %3(2)|1$s in %4$s %5$s"
				~" and the part becomes %6$s",
				"somebody", definite_name, hittee.definite_name,
				hittee.possesive_pronoun, body_.getPartName(part), damage_str);
		}
	}

	void onUnarmedHitMiss(int x, int y) { onHitMiss(x, y); }

	bool actShoot(int x, int y)
		in(map !is null)
	{
		if (weapon_index != -1) {
			return items[weapon_index].tryShoot(this, x, y);
		}
		return false;
	}
	bool actShoot(Point p) { return actShoot(p.x, p.y); }

	void onTryShootWeaponCantShoot(int x, int y)
	{
	}

	void onTryShootNoLoadedAmmo(int x, int y)
	{
	}

	bool rollWhetherUnarmedHitImpacts(Actor hittee)
		in(hittee !is null)
	{
		return
			sigmoidChance(hit_chance_bonus-hittee.evasion_chance_bonus);
	}

	Strike rollUnarmedHitStrike()
	{
		// TODO: Take account for unarmed fighting skills.
		Strike strike;
		foreach (int i, ref e; strike) {
			e = uniform!"[]"(0, scaledSigmoid(body_.unarmed_hit_max_strike[i],
				hit_damage_bonus));
		}
		return strike;
	}

	float getDistance(int x, int y) const /*pure*/
		{ return sqrt(cast(float)((x-this.x)^^2+(y-this.y)^^2)); }
	float getDistance(Point p) const /*pure*/
		{ return getDistance(p.x, p.y); }
	float getDistance(const Actor target) const /*pure*/
		{ return getDistance(target.x, target.y); }
}
