import std.algorithm.comparison;
import std.container;
import util;
import ser;
import stat;
import item;

enum HumanFleshyBodyPart
{
	head, torso,
	left_arm, right_arm,
	left_leg, right_leg,
}

enum DamageType
{
	blunt, sharp, heat, electromagnetic,
}

struct Strike
{
	int[DamageType.max+1] damages;
	alias damages this;

	// Possibly very slow...
	@property bool is_null() const
	{
		foreach (e; this) {
			if (e != 0) {
				return false;
			}
		}
		return true;
	}

	/*this(int[DamageType.max+1] damages) /*pure*/
	/*{
		this.damages = damages;
	}*/
}

abstract class Body
{
	mixin Serializable;
	mixin SimplySerialized;

	enum max_resistance = 4;

	Array!Item items;
	private Stats _stats;

	@property void stats(Stats stats) pure
	{
		_stats = stats;
		update();
	}
	@property Stats stats() const pure { return _stats; }

	@property Strike unarmed_hit_max_strike() const /*pure*/
	{
		Strike strike;
		strike[DamageType.blunt] = 10;
		return strike;
	}
	@property int dexterity_mod() const /*pure*/ { return 0; }
	@property int agility_mod() const /*pure*/ { return 0; }

	this() {}
	this(Serializer serializer) /*pure*/ {}

	//void update(Stats stats) {}
	void dealStrike(int part, Strike strike) /*pure*/
	{
		foreach (int i, e; strike) {
			int resistance = getResistance(cast(DamageType) i, part);
			dealDamage(part, e*(max_resistance-resistance)/max_resistance);
		}
	}

	void update() pure {};

	protected abstract void dealDamage(int part, int damage) /*pure*/
		out { assert(getDamage(part) <= getMaxDamage(part)); }
		do {}

	abstract int getDamage(int part) const /*pure*/;
	abstract int getMaxDamage(int part) const /*pure*/;
	abstract int getResistance(DamageType damage_type, int part)
		const /*pure*/;
	abstract string getPartName(int part) const /*pure*/;
	abstract string getDamageStr(int part) const /*pure*/;
}

abstract class FleshyBody : Body
{
	mixin InheritedSerializable;

	enum bleeding_from_sharp_divisor = 10;

	int _lost_blood;

	@property int lost_blood() const pure { return _lost_blood; }
	@property abstract int total_bleeding() const pure;
	@property abstract int total_pain() const pure;

	this() /*pure*/ { super(); }
	this(Serializer serializer) /*pure*/ { super(serializer); }

	override void update() pure
	{
		_lost_blood += total_bleeding;
	}

	abstract int getMaxLostBlood() const /*pure*/;
	abstract int getBleeding(int part) const /*pure*/;
	abstract int getPain(int part) const /*pure*/;
}

class HumanFleshyBody : FleshyBody
{
	mixin InheritedSerializable;

	private int[HumanFleshyBodyPart.max+1] damage;
	private int[HumanFleshyBodyPart.max+1] bleeding;
	private int[HumanFleshyBodyPart.max+1] pain;

	@property override int total_bleeding() const pure
	{
		int sum;
		foreach (e; bleeding) {
			sum += e;
		}
		return sum;
	}

	@property override int total_pain() const pure
	{
		// TODO: Add pain.
		return 0;
	}

	this() { super(); }
	this(Serializer serializer) /*pure*/ { super(serializer); }

	override void dealStrike(int part, Strike base_damage) /*pure*/
	{
		super.dealStrike(part, base_damage);
		bleeding[cast(HumanFleshyBodyPart)part]
			+= (bleeding_from_sharp_divisor+base_damage[DamageType.sharp])
			/ bleeding_from_sharp_divisor;
	}

	protected override void dealDamage(int part, int damage) /*pure*/
	{
		this.damage[cast(HumanFleshyBodyPart)part] += damage;
		this.damage[cast(HumanFleshyBodyPart)part] =
			min(this.damage[cast(HumanFleshyBodyPart)part],
			getMaxDamage(part));
	}

	override int getDamage(int part) const /*pure*/
	{
		return damage[cast(HumanFleshyBodyPart)part];
	}

	override int getMaxDamage(int part) const /*pure*/
	{
		final switch(cast(HumanFleshyBodyPart)part) {
			case HumanFleshyBodyPart.head:
				return 100+10*stats[Stat.endurance];
			case HumanFleshyBodyPart.torso:
				return 200+20*stats[Stat.endurance];
			case HumanFleshyBodyPart.left_arm:
				return 100+10*stats[Stat.endurance];
			case HumanFleshyBodyPart.right_arm:
				return 100+10*stats[Stat.endurance];
			case HumanFleshyBodyPart.left_leg:
				return 100+10*stats[Stat.endurance];
			case HumanFleshyBodyPart.right_leg:
				return 100+10*stats[Stat.endurance];
		}
	}

	override int getResistance(DamageType damage_type, int part) 
		const /*pure*/
	{
		if (damage_type == DamageType.electromagnetic) {
			return 3;
		} else {
			return 0;
		}
	}

	override int getMaxLostBlood() const /*pure*/ { return 1000; }

	override int getBleeding(int part) const /*pure*/
	{
		return bleeding[cast(HumanFleshyBodyPart)part];
	}

	override int getPain(int part) const /*pure*/
	{
		// TODO: Add pain.
		return 0;
	}

	override string getPartName(int part) const /*pure*/
	{
		final switch(cast(HumanFleshyBodyPart)part) {
			case HumanFleshyBodyPart.head: return "head";
			case HumanFleshyBodyPart.torso: return "torso";
			case HumanFleshyBodyPart.left_arm: return "left arm";
			case HumanFleshyBodyPart.right_arm: return "right arm";
			case HumanFleshyBodyPart.left_leg: return "left leg";
			case HumanFleshyBodyPart.right_leg: return "right leg";
		}
	}
	
	// TODO: Return bleeding info.
	override string getDamageStr(int part) const /*pure*/
	{
		uint percentage = 100-getDamage(part)*100/getMaxDamage(part);
		if (percentage == 100) {
			return "unwounded";
		} else if (percentage >= 70) {
			return "lightly wounded";
		} else if (percentage >= 30) {
			return "moderately wounded";
		} else if (percentage > 0) {
			return "heavily wounded";
		} else {
			return "collapsed";
		}
	}
}
