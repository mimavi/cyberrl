import util;
import ser;
import item;
import term;
import body;

class LightkatanaItem : Item
{
	mixin InheritedSerializable;

	@property override Symbol symbol() const pure
		{ return Symbol('/', Color.magenta, true); }
	@property override string name() const pure { return "lightkatana"; }

	@property override Strike hit_max_strike() const pure
	{
		//return Damage([DamageType.heat: 90]);
		Strike strike;
		strike[DamageType.heat] = 90;
		return strike;
	}
	@property override int hit_damage_bonus() const pure { return 2; }

	@property override bool can_hit() const pure { return true; }

	this() pure { super(); }
	this(Serializer serializer) pure { this(); }
	/*this(Serializer serializer)
	{
		load(serializer);
	}*/
}

class KnifeItem : Item
{
	mixin InheritedSerializable;

	@property override Symbol symbol() const pure
		{ return Symbol('/', Color.cyan, true); }
	@property override Strike hit_max_strike() const pure
	{
		Strike strike;
		strike[DamageType.blunt] = 20;
		strike[DamageType.sharp] = 40;
		return strike;
	}
	@property override int hit_chance_bonus() const { return 1; }

	@property override string name() const pure { return "knife"; }
	@property override bool can_hit() const pure { return true; }

	this() pure { super(); }
	this(Serializer serializer) pure { this(); }
}

class PistolItem : Item
{
	mixin InheritedSerializable;

	@property override Symbol symbol() const pure
		{ return Symbol('[', Color.cyan, true); }
	@property override string name() const pure { return "pistol"; }

	@property override Strike hit_max_strike() const pure
	{
		Strike strike;
		strike[DamageType.blunt] = 20;
		return strike;
	}
	@property override int hit_chance_bonus() const pure { return -1; }

	@property override Strike shoot_max_strike() const pure
	{
		Strike strike;
		strike[DamageType.blunt] = 20;
		strike[DamageType.sharp] = 60;
		return strike;
	}
	@property override int shoot_hit_chance_bonus() const pure { return 0; }

	@property override int max_loaded_ammo() const pure { return 6; }
	@property override string[] compatible_ammo_kinds() const pure
		{ return ["pistol bullet"]; }

	@property override bool can_hit() const pure { return true; }
	@property override bool can_shoot() const pure { return true; }

	this() { super(); }
	this(Serializer serializer) { this(); }
}

class PistolBulletItem : Item
{
	mixin InheritedSerializable;

	@property override Symbol symbol() const pure
		{ return Symbol('"', Color.cyan, true); }
	@property override string name() const { return "pistol bullet"; }

	@property override string ammo_kind() const pure
		{ return "pistol bullet"; }
	@property override bool is_stackable() const pure { return true; }
	@property override int max_stack_size() const pure { return 10; }

	this() { super(); }
	this(Serializer serializer) { this(); }
}

/*class PistolClipItem : Item
{
	mixin InheritedSerializable;

	@property override Symbol symbol() const
		{ return Symbol('"', Color.cyan, true); }
	@property override string name() const { return "pistol clip"; }

	//@property override bool is_ammo_container() const { return true; }
	@property override int max_loaded_ammo() const { return 6; }

	@property override int ammo_damage_bonus() const { return 0; }
	@property override int ammo_hit_chance_bonus() const { return 0; }
	/*@property override string[] ammo_weapon_types() const
		{ return ["PistolItem"]; }*/
	
	/*this() { super(); }
	this(Serializer serializer) { this(); }
}*/
