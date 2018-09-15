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

	DList!Item loaded_ammo;

	@property abstract Symbol symbol() const /*pure*/;
	@property abstract string name() const /*pure*/;

	@property Strike hit_max_strike() const { return Strike(); }/*pure*/
	@property int hit_damage_bonus() const { return 0; } /*pure*/;
	@property int hit_chance_bonus() const { return 0; }

	@property Strike shoot_max_strike() const { return Strike(); }
	@property double shoot_max_spread() const { return PI_2; }
	@property int shoot_hit_chance_bonus() const { return 0; }

	@property int ammo_damage_bonus() const { return 0; }
	@property int ammo_hit_chance_bonus() const { return 0; }
	@property string[] ammo_weapon_types() const { return []; }

	@property bool can_hit() const { return false; }
	@property bool can_shoot() const { return false; }
	@property bool is_throwable() const { return false; }

	this() /*pure*/ {}
	this(Serializer serializer) /*pure*/ { this(); }
	//void beforesave(Serializer serializer) /*pure*/ {}
	//void beforeload(Serializer serializer) /*pure*/ {}
	//void aftersave(Serializer serializer) /*pure*/ {}
	//void afterload(Serializer serializer) /*pure*/ {}

	final void draw(int x, int y)
	{
		term.setSymbol(x, y, symbol);
	}

	bool tryHit(Actor hitter, int x, int y)
		in(hitter !is null)
	{
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

	void hit(Actor hitter, int x, int y)
		in(hitter !is null)
	{
		auto hittee = hitter.map.getTile(x, y).actor;
		if (rollWhetherHitImpacts(hitter, hittee)) {
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

			hitter.onHitJustBefore(x, y, part);

			auto strike = rollHitStrike(hitter);
			hittee.body_.dealStrike(part, strike);
			hitter.onHitImpact(x, y, part);
		} else {
			hitter.onHitMiss(x, y);
		}
	}

	bool tryShoot(Actor shooter, int x, int y)
		in(shooter !is null)
	{
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

	void shoot(Actor shooter, int x, int y)
		in(shooter !is null)
	{
		bool shootGetIsBlocking(int x, int y)
		{
			auto tile = shooter.map.getTile(x, y);
			return !tile.is_walkable || (tile.actor !is null);
		}

		double targetAngle = atan2(cast(double)(y-shooter.y),
			cast(double)(x-shooter.x));
		double angleError = rollShootAngleError(shooter, x, y);
		double angle = targetAngle+angleError;
		int new_x = cast(int)round((x+0.5)*cos(angle)-(y+0.5)*sin(angle));
		int new_y = cast(int)round((x+0.5)*sin(angle)+(y+0.5)*cos(angle));

		Point[] ray = shooter.map.castRay(shooter.x, shooter.y, new_x, new_y,
			&shootGetIsBlocking);
		foreach (e; ray) {

			//import tile;
			//shooter.map.getTile(x, y) = new MarkerFloorTile(Color.blue);
		}
	}

	bool rollWhetherHitImpacts(Actor hitter, Actor hittee)
		in(hitter !is null)
		in(hittee !is null)
	{
		// TODO: Take account for weapon skills.
		return
			sigmoidChance(hitter.hit_chance_bonus-hittee.evasion_chance_bonus);
	}

	Strike rollHitStrike(Actor hitter)
		in(hitter !is null)
	{
		// TODO: Take account for weapon skills.
		Strike strike;
		foreach (int i, ref e; strike) {
			e = uniform!"[]"(0, scaledSigmoid(hit_max_strike[i],
				hit_damage_bonus+hitter.hit_damage_bonus));
		}
		return strike;
	}

	double rollShootAngleError(Actor shooter, int x, int y)
	{
		double spread =
			scaledSigmoid(shoot_max_spread, -shooter.shoot_aim_bonus);
		return uniform!"[]"(-spread, spread);
	}
}
