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
		if (name[0] == 'a' || name[0] == 'e' || name[0] == 'o'
		|| name[0] == 'u' || name[0] == 'i') {
			return "an "~name;
		} else {
			return "a "~name;
		}
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
	// The `act*` methods shall be designed to never throw
	// exceptions and errors.

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
			return false;
		}

		// Torso can be choosen 2 times more likely than each other part.
		HumanFleshyBodyPart part = [
			HumanFleshyBodyPart.left_arm,
			HumanFleshyBodyPart.right_arm,
			HumanFleshyBodyPart.left_leg,
			HumanFleshyBodyPart.right_leg,
			HumanFleshyBodyPart.head,
			HumanFleshyBodyPart.torso,
			HumanFleshyBodyPart.torso
		].choice(rng);

		// TODO: Weapon skills and unarmed fighting skills should also affect
		// probability of hitting.
		if (sigmoidChance(hit_chance_bonus-target.evasion_chance_bonus)) {
			string prev_damage_str = target.body_.getDamageStr(part);
			// Hit with a weapon.
			if (weapon_index != -1 && items[weapon_index].can_hit) {

				auto weapon = items[weapon_index];
				Strike strike;
				foreach (int i, ref e; strike) {
					e = uniform!"[]"(0, scaledSigmoid(weapon.hit_max_strike[i],
						hit_damage_bonus+weapon.hit_damage_bonus));
				}

				target.body_.dealStrike(part, strike);
				actHitSendHitMsg(target, part, prev_damage_str);
			// Hit unarmed.
			} else {
				Strike strike;
				foreach (int i, ref e; strike) {
					e = uniform!"[]"(0, scaledSigmoid(body_.unarmed_max_strike[i],
						hit_damage_bonus));
				}

				target.body_.dealStrike(part, strike);
				actHitSendUnarmedHitMsg(target, part, prev_damage_str);
			}
			// For now, you cannot hit without a weapon.
			// TODO: Change this.
		} else {
			actHitSendMissMsg(target, part);
		}

		ap -= base_ap_cost - dexterity_ap_weight*stats[Stat.dexterity];
		return true;
	}

	protected void actHitSendHitMsg(const Actor target, int part,
		string prev_damage_str)
	{
		string damage_str = target.body_.getDamageStr(part);
		if (damage_str == prev_damage_str) {
			map.game.sendVisibleEventMsg([pos, target.pos],
				Color.red, true, "%1(1)|2$s hits %3(2)|4$s in %5$s %6$s"
				~" with %7$s %8$s!",
				definite_name, "somebody", target.definite_name, "somebody",
				target.possesive_pronoun, body_.getPartName(part),
				possesive_pronoun, items[weapon_index].name);
		} else {
			map.game.sendVisibleEventMsg([pos, target.pos],
				Color.red, true, "%2(1)|1$s hits %3(2)|1$s in %4$s %5$s"
				~" with %6$s %7$s and the part becomes %8$s!",
				"somebody", definite_name, target.definite_name,
				target.possesive_pronoun, body_.getPartName(part),
				possesive_pronoun, items[weapon_index].name, damage_str);
		}
	}

	protected void actHitSendUnarmedHitMsg(const Actor target, int part,
		string prev_damage_str)
	{
		string damage_str = target.body_.getDamageStr(part);
		if (damage_str == prev_damage_str) {
			map.game.sendVisibleEventMsg([pos, target.pos],
				Color.red, true, "%2(1)|1$s hits %3(2)|1$s in %4$s %5$s!",
				"somebody", definite_name, target.definite_name,
				target.possesive_pronoun, body_.getPartName(part));
		} else {
			map.game.sendVisibleEventMsg([pos, target.pos],
				Color.red, true, "%2(1)|1$s hits %3(2)|1$s in %4$s %5$s"
				~" and the part becomes %6$s",
				"somebody", definite_name, target.definite_name,
				target.possesive_pronoun, body_.getPartName(part), damage_str);
		}
	}

	protected void actHitSendMissMsg(const Actor target, int part)
	{
		map.game.sendVisibleEventMsg(target.x, target.y,
			Color.red, false, "%1$s misses %2$s", definite_name,
			target.definite_name);
	}

	bool actHit(Point p)
		in(map !is null)
		{ return actHit(p.x, p.y); }

	float getDistance(int x, int y) const /*pure*/
		{ return sqrt(cast(float)((x-this.x)^^2+(y-this.y)^^2)); }
	float getDistance(Point p) const /*pure*/
		{ return getDistance(p.x, p.y); }
	float getDistance(const Actor target) const /*pure*/
		{ return getDistance(target.x, target.y); }
}
