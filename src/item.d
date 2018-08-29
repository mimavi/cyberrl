import util;
import ser;
import term;
import body;

class Item
{
	mixin Serializable;
	mixin SimplySerialized;

	@property abstract Symbol symbol() const pure;
	@property abstract string name() const pure;
	@property abstract Strike hit_max_strike() const pure;
	@property abstract int hit_damage_bonus() const pure;
	@property bool is_hit() const pure { return false; }

	this() pure {}
	this(Serializer serializer) pure { this(); }
	/*void beforesave(Serializer serializer) pure {}
	void beforeload(Serializer serializer) pure {}
	void aftersave(Serializer serializer) pure {}
	void afterload(Serializer serializer) pure {}*/

	final void draw(int x, int y)
	{
		term.setSymbol(x, y, symbol);
	}
}

class LightkatanaItem : Item
{
	mixin InheritedSerializable;

	@property override Symbol symbol() const pure
		{ return Symbol('/', Color.magenta, true); }

	@property override Strike hit_max_strike() const pure
	{
		//return Damage([DamageType.heat: 90]);
		Strike strike;
		strike[DamageType.heat] = 90;
		return strike;
	}
	
	@property override int hit_damage_bonus() const pure
		{ return 2; }
	@property override string name() const pure { return "lightkatana"; }
	@property override bool is_hit() const pure { return true; }

	this() pure {}
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
		strike[DamageType.blunt] = 2;
		strike[DamageType.sharp] = 10;
		return strike;
	}
	@property override string name() const pure { return "knife"; }
	@property override bool is_hit() const pure { return true; }

	this() pure {}
	this(Serializer serializer) pure { this(); }
}
