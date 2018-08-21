import std.random;
import util;
import ser;
import actor;

class AiActor : Actor
{
	mixin InheritedSerializable;
	enum max_action_attempts_num = 100;

	this() { super(); }
	this(Serializer serializer) { this(); }

	override bool subupdate()
	{
		aiFollow();
		return true;
	}

	void aiMeander()
	{
		bool has_acted = false;
		// TODO: Timeout when too many attempts fail.
		for (int i = 0; !has_acted && i < max_action_attempts_num; ++i) {
			has_acted
				= actMoveTo(x+1-uniform(0, 3, rng), y+1-uniform(0, 3, rng));
		}
	}

	void aiFollow()
	{
		bool has_acted = false;
		Point[] path = this.map.findPath(x, y,
			map.game.player.x, map.game.player.y);

		if (map.game.player is map.getTile(path[1]).actor) {
			actHit(path[1]);
		} else if (!actMoveTo(path[1])) {
			aiMeander();
		}
	}

	void aiWander()
	{
	}
}
