import std.conv;
import std.container;
import std.random;
import std.math;
import util;
import ser;
import term;
import map;
import actor;
import body;

abstract class Item
{
	mixin Serializable;
	mixin SimplySerialized;

	Array!Item loaded_ammo;
	private Array!Item stacked;

	@property abstract Symbol symbol() const pure;
	@property abstract string name() const pure;
	@property string plural_name() const pure { return name~"s"; }

	@property string indefinite_name() const pure
	{
		return prependIndefiniteArticle(name);
	}

	@property string definite_name() const pure
	{
		return "the "~name;
	}

	@property string indefinite_plural_name() const pure
	{
		return plural_name;
	}

	@property string definite_plural_name() const pure
	{
		return "the "~plural_name;
	}

	@property string full_definite_name() const pure
	{
		string result;
		if (stack_size > 1) {
			result = to!string(stack_size)~" "~definite_plural_name;
		} else {
			result = definite_name;
		}

		if (max_loaded_ammo > 0) {
			result ~= " ("~to!string(loaded_ammo.length)
				~"/"~to!string(max_loaded_ammo)~")";
		}
		return result;
	}

	@property string full_indefinite_name() const pure
	{
		string result;
		if (stack_size > 1) {
			result = to!string(stack_size)~" "~indefinite_plural_name;
		} else {
			result = indefinite_name;
		}

		if (max_loaded_ammo > 0) {
			result ~= " ("~to!string(loaded_ammo.length)
				~"/"~to!string(max_loaded_ammo)~")";
		}
		return result;
	}

	@property final int stack_size() const pure { return 1+stacked.length; }

	@property Strike hit_max_strike() const pure { return Strike(); }
	@property int hit_damage_bonus() const pure { return 0; }
	@property int hit_chance_bonus() const pure { return 0; }

	@property Strike shoot_max_strike() const pure { return Strike(); }
	@property int shoot_damage_bonus() const pure { return 0; }
	@property double shoot_max_spread() const pure { return PI_2; }
	// TODO: Rename "hit chance" to "aim".
	@property int shoot_hit_chance_bonus() const pure { return 0; }

	@property int max_loaded_ammo() const pure { return 0; }
	@property string[] compatible_ammo_kinds() const pure { return []; }

	@property string ammo_kind() const pure { return ""; }
	@property int ammo_damage_bonus() const pure { return 0; }
	// TODO: Rename "hit chance" to "aim".
	@property int ammo_hit_chance_bonus() const pure { return 0; }
	//@property string[] ammo_weapon_types() const { return []; }

	@property bool is_stackable() const pure { return false; }
	@property int max_stack_size() const pure { return 1; }

	@property bool can_hit() const pure { return false; }
	@property bool can_shoot() const pure { return false; }
	@property bool is_throwable() const pure { return false; }

	this() pure {}
	this(Serializer serializer) pure { this(); }
	//void beforesave(Serializer serializer) /*pure*/ {}
	//void beforeload(Serializer serializer) /*pure*/ {}
	//void aftersave(Serializer serializer) /*pure*/ {}
	//void afterload(Serializer serializer) /*pure*/ {}

	final void draw(int x, int y) const
	{
		term.setSymbol(x, y, symbol);
	}

	void insertToStacked(Item item)
	in (is_stackable
	&& type == item.type
	&& stack_size+item.stack_size <= max_stack_size)
	{
		if (item.stack_size > 1) {
			stacked.insertBack(item);
			stacked.insertBack(item.stacked[]);
			item.removeStacked();
		} else {
			stacked.insertBack(item);
		}
	}

	void removeFromStacked(int index)
	in (is_stackable
	&& index >= 0
	&& index < stacked.length)
	{
		stacked.linearRemove(stacked[index..index+1]);
	}

	void removeStacked()
	{
		stacked.clear();
	}

	bool tryHit(Actor hitter, int x, int y)
	{
		if (hitter is null) {
			return false;
		}
		if (!can_hit) {
			hitter.onTryHitWeaponCantHit(x, y);
			return false;
		}
		if (hitter.map.getTile(x, y).actor is null) {
			hitter.onTryHitNothing(x, y);
			return false;
		}
		
		hit(hitter, x, y);
		return true;
	}

	protected void hit(Actor hitter, int x, int y)
	in (can_hit
	&& (hitter !is null)
	&& (hitter.map.getTile(x, y).actor !is null))
	{
		auto hittee = hitter.map.getTile(x, y).actor;
		if (rollWhetherHitImpacts(hitter, hittee)) {
			// Torso can be hit 2 times more likely than each other part.
			int part = [
				HumanFleshyBodyPart.left_arm,
				HumanFleshyBodyPart.right_arm,
				HumanFleshyBodyPart.left_leg,
				HumanFleshyBodyPart.right_leg,
				HumanFleshyBodyPart.head,
				HumanFleshyBodyPart.torso,
				HumanFleshyBodyPart.torso
			].choice(rng);

			hitter.onHitJustBefore(x, y, part);

			Strike strike = rollHitStrike(hitter);
			hittee.body_.dealStrike(part, strike);
			hitter.onHitImpact(x, y, part);
		} else {
			hitter.onHitMiss(x, y);
		}
	}

	// XXX: Perhaps the `try*` methods shouldn't have `in` assertions,
	// since that beats their purpose somewhat -
	// they aren't safe to use anymore.
	// XXX: Consider making the "non-try" equivalents protected.

	// Note that it is possible to shoot yourself with this function.
	bool tryShoot(Actor shooter, int x, int y)
	{
		if (shooter is null) {
			return false;
		}
		if (!can_shoot) {
			shooter.onTryShootWeaponCantShoot(x, y);
			return false;
		}
		if (loaded_ammo.empty) {
			shooter.onTryShootNoLoadedAmmo(x, y);
			return false;
		}

		shoot(shooter, x, y);
		return true;
	}

	protected void shoot(Actor shooter, int x, int y)
	in (can_shoot)
	in (!loaded_ammo.empty)
	in (shooter !is null)
	{
		bool shootGetIsBlocking(int x, int y)
		{
			auto tile = shooter.map.getTile(x, y);
			return !tile.is_walkable
			|| ((tile.actor !is null) && tile.actor != shooter);
		}

		double targetAngle = atan2(cast(double)(y-shooter.y),
			cast(double)(x-shooter.x));
		double angle = 0;
		//double angle = rollShootAngleError(shooter, x, y);
		//double angle = targetAngle+angleError;
		//int new_x = cast(int)round((x+0.5)*cos(angleError)-(y+0.5)*sin(angle));
		//int new_y = cast(int)round((x+0.5)*sin(angle)+(y+0.5)*cos(angle));
		int rel_x = x-shooter.x, rel_y = y-shooter.y;
		int new_x = shooter.x
			+cast(int)((rel_x)*cos(angle)-(rel_y)*sin(angle));
		int new_y = shooter.y
			+cast(int)((rel_x)*sin(angle)+(rel_y)*cos(angle));

		Point[] ray = shooter.map.castRay(shooter.x, shooter.y, new_x, new_y,
			&shootGetIsBlocking);
		Point prev_p = ray[0];

		//if (ray.length >= 2) {
		foreach (e; ray[1..$-1]) {
			Point dp = Point(e.x-prev_p.x, e.y-prev_p.y);

			if (shooter.map.getTile(e).is_visible) {
				shooter.map.game.setSymbolOnViewport(e,
					Symbol(point_to_projectile_chr[dp], Color.white));
				term.waitMilliseconds(50);
			}

			shooter.map.game.setSymbolOnViewport(e,
				shooter.map.getTile(e).visible_symbol);
			prev_p = e;
		}

		//if (map.getTile(ray[$-1]).actor !is null) {
			//map.getTile(ray[$-1]).actor.dealStrike(
			//impactShot(shooter, ray[$-1]);
			//map.getTile(ray[$-1]).actor.body_.dealStrike(
		//}
		//impactShot(shooter, x, y);
		shootImpact(shooter, null, ray[$-1]);

		if (shooter.map.getTile(ray[$-1]).is_visible) {
				shooter.map.game.setSymbolOnViewport(ray[$-1],
					Symbol('*', Color.white));
				term.waitMilliseconds(100);
		}
		//}
	}

	protected void shootImpact(Actor shooter, Item projectile, int x, int y)
	in ((shooter !is null) && (projectile !is null))
	{
		Actor target = shooter.map.getTile(x, y).actor;
		if ((target !is null) && rollWhetherShootImpacts(shooter, target)) {
			int part = [
				HumanFleshyBodyPart.left_arm,
				HumanFleshyBodyPart.right_arm,
				HumanFleshyBodyPart.left_leg,
				HumanFleshyBodyPart.right_leg,
				HumanFleshyBodyPart.head,
				HumanFleshyBodyPart.torso,
				HumanFleshyBodyPart.torso,
			].choice(rng);

			shooter.onShootImpactOnActorJustBefore(x, y, projectile, part);

			Strike strike = rollShootStrike(shooter, projectile);
			target.body_.dealStrike(part, strike);
			shooter.onShootImpactOnActor(x, y, projectile, part);
		}
	}
	protected void shootImpact(Actor shooter, Item projectile, Point p)
	{
		shootImpact(shooter, projectile, p.x, p.y);
	}

	bool tryLoadAmmo(Actor actor, int index, int num)
	{
		if (actor is null) {
			return false;
		}
		Item ammo = actor.body_.items[index];

		if (!getIsAmmoCompatible(ammo)) {
			actor.onTryLoadAmmoNotCompatible(ammo);
			return false;
		}
		if (num < 0) {
			num = 0;
		} else if (loaded_ammo.length+num > max_loaded_ammo) {
			num = max_loaded_ammo-loaded_ammo.length;
		}
		/*if (num > loaded_ammo.back.stack_size) {
			return false;
		}*/
		//loadAmmo(actor, ammo, num);
		return true;
	}
	bool tryLoadAmmo(Actor actor, int index)
	{
		if (actor is null) {
			return false;
		}
		/*if (ammo.is_ammo_container) {
			return tryLoadAmmo(actor, ammo, max_loaded_ammo-loaded_ammo.length);
		}*/
		return tryLoadAmmo(actor, index, 1);
	}

	/*protected void loadAmmo(Actor actor, Item ammo, int num)
	in (ammo !is null)
	in (num >= 0)
	in (num <= loaded_ammo.back.stack_size)
	{*/
		/*if (num == 0) {
			return false;
		} else if (num == loaded_ammo.back.stack_size) {
			
		}*/
		/*loaded_ammo.insertBack(ammo.dup);
		loaded_ammo.back.stack_size = num;
		ammo.stack_size -= num;*/
	//}
	/*protected void loadAmmo(Actor actor, Item ammo)
	{
		//loaded_ammo += ammo.num;
		//loaded_ammo.insertBack(ammo);
	}*/

	protected bool rollWhetherHitImpacts(Actor hitter, Actor hittee)
	in ((hitter !is null) && (hittee !is null))
	{
		// TODO: Take account for weapon skills.
		return
			sigmoidChance(hitter.hit_chance_bonus-hittee.evasion_chance_bonus);
	}

	protected Strike rollHitStrike(Actor hitter)
	in (hitter !is null)
	{
		// TODO: Take account for weapon skills.
		Strike strike;
		foreach (int i, ref e; strike) {
			e = uniform!"[]"(0, scaledSigmoid(hit_max_strike[i],
				hit_damage_bonus+hitter.hit_damage_bonus));
		}
		return strike;
	}

	protected bool rollWhetherShootImpacts(Actor shooter, Actor target)
	in ((shooter !is null) && (target !is null))
	{
		return
			sigmoidChance(shooter.shoot_aim_bonus-target.evasion_chance_bonus);
	}

	protected double rollShootAngleError(Actor shooter, int x, int y)
	{
		double spread =
			scaledSigmoid(shoot_max_spread, -shooter.shoot_aim_bonus);
		return uniform!"[]"(-spread, spread);
	}

	protected Strike rollShootStrike(Actor shooter, Item projectile)
	in (shooter !is null)
	{
		Strike strike;
		foreach (int i, ref e; strike) {
			e = uniform!"[]"(0, scaledSigmoid(shoot_max_strike[i],
				shoot_damage_bonus+shooter.shoot_damage_bonus));
		}
		return strike;
	}

	bool getIsAmmoCompatible(Item ammo)
	{
		/*foreach (e; ammo) {
			bool is_found = false;
			foreach (ee; compatible_ammo_kinds) {
				if (e.ammo_kind == ee) {
					is_found = true;
					break;
				}
			}
			if (!is_found) {
				return false;
			}
		}
		return true;*/
		foreach (e; compatible_ammo_kinds) {
			if (e == ammo.ammo_kind) {
				return true;
			}
		}
		return false;
	}
}
