import std.algorithm.comparison;
import util;
import ser;
import stat;

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

	/*this(int[DamageType.max+1] damages) pure
	{
		this.damages = damages;
	}*/
}

class Body
{
	mixin Serializable;
	mixin SimplySerialized;

	enum max_resistance = 4;

	@property int dexterity_mod() const pure { return 0; }
	@property int agility_mod() const pure { return 0; }

	this() pure {}
	this(Serializer serializer) pure {}

	//void update(Stats stats) {}
	void dealStrike(Stats stats, int part, Strike strike) pure
	{
		foreach(int i, e; strike) {
			int resistance = getResistance(stats, cast(DamageType)i, part);
			debug writeln(e*(max_resistance-resistance)/max_resistance);
			dealDamage(stats, part, e*(max_resistance-resistance)/max_resistance);
		}
	}

	void update() pure {};

	protected abstract void dealDamage(Stats stats, int part, int damage) pure
		out { assert(getDamage(part) <= getMaxDamage(stats, part)); }
		do {}

	abstract int getDamage(int part) const pure;
	abstract int getMaxDamage(Stats stats, int part) const pure;
	abstract int getResistance(Stats stats, DamageType damage_type, int part)
		const pure;
}

class FleshyBody : Body
{
	mixin InheritedSerializable;

	enum bleeding_from_sharp_divisor = 10;

	int _lost_blood;

	@property int lost_blood() const pure { return _lost_blood; }
	@property abstract int total_bleeding() const pure;
	@property abstract int total_pain() const pure;

	this() pure {}
	this(Serializer serializer) pure { super(serializer); }

	override void update() pure
	{
		_lost_blood += total_bleeding;
	}

	abstract int getMaxLostBlood(Stats stats) const pure;
	abstract int getBleeding(int part) const pure;
	abstract int getPain(int part) const pure;
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

	this() pure {}
	this(Serializer serializer) pure { super(serializer); }

	override void dealStrike(Stats stats, int part, Strike base_damage) pure
	{
		super.dealStrike(stats, part, base_damage);
		bleeding[cast(HumanFleshyBodyPart)part]
			+= (bleeding_from_sharp_divisor+base_damage[DamageType.sharp])
			/ bleeding_from_sharp_divisor;
	}

	protected override void dealDamage(Stats stats, int part, int damage) pure
	{
		this.damage[cast(HumanFleshyBodyPart)part] += damage;
		this.damage[cast(HumanFleshyBodyPart)part] =
			min(this.damage[cast(HumanFleshyBodyPart)part],
			getMaxDamage(stats, part));
	}

	override int getDamage(int part) const pure
	{
		return damage[cast(HumanFleshyBodyPart)part];
	}

	override int getMaxDamage(Stats stats, int part) const pure
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

	override int getResistance(Stats stats, DamageType damage_type, int part) 
		const pure
	{
		if (damage_type == DamageType.electromagnetic) {
			return 3;
		} else {
			return 0;
		}
	}

	override int getMaxLostBlood(Stats stats) const pure { return 1000; }

	override int getBleeding(int part) const pure
	{
		return bleeding[cast(HumanFleshyBodyPart)part];
	}

	override int getPain(int part) const pure
	{
		// TODO: Add pain.
		return 0;
	}
}
