import std.container;
import std.random;
import util;
import ser;
import actor;

class AiActor : Actor
{
	mixin (inherited_serializable);
	enum max_action_attempts_num = 100;

	// TODO: Serialize `group` properly.
	@noser private AiGroup group;

	private Actor _target;
	private Point[] path;
	private int path_index = 0;

	@property Actor target() { return _target; }
	@property void target(Actor target)
	{
		path = map.findPath(x, y, target.x, target.y);
		_target = target;
	}

	this()
	{
		super();
		group = new AiGroup([this]);
	}
	this(Serializer serializer) { this(); }

	protected override bool updateRaw()
	{
		if (map.getTile(x, y).is_visible) {
			group.target = map.game.player;
		}
		if (path.length >= 2) {
			if (!actMoveTo(path[1])) {
				actHit(path[1]);
			}
		}
		return true;
	}

	/*bool aiChase(Actor target)
	{
		bool has_acted = false;
		Point[] path = this.map.findPath(x, y,
			target.x, target.y);

		if (path.length <= 1) {
			return false;
		} else if (path.length == 2) {
			actHit(path[1]);
		} else {
			
		}*/

		/*if (path.length <= 1) {
			aiMeander(1, 5);
		} else if (map.game.player is map.getTile(path[1]).actor) {
			actHit(path[1]);
		} else if (!actMoveTo(path[1])) {
			aiMeander(1, 5);
		}*/
	//}

	/*void aiFollow(const Actor target, int threshold)
	{
		Point[] path = map.findPath(x, y, target.x, target.y);
		if (path.length <= threshold) {
			aiMeander(1, 5);
		} else {
			actMoveTo(path[1]);
		}
	}

	void aiMeander(int prob_numer, int prob_denom)
	{
		bool has_acted = false;
		// TODO: Timeout when too many attempts fail.
		if (chance(prob_numer, prob_denom)) {
			for (int i = 0; !has_acted && i < max_action_attempts_num; ++i) {
				has_acted
					= actMoveTo(x+1-uniform(0, 3, rng), y+1-uniform(0, 3, rng));
			}
		}
	}

	void aiWander()
	{
		if (path.length-path_index <= 0) {
			Point target = map.zones[2][uniform(0, map.zones[2].length)];
			path = map.findPath(this.x, this.y, target.x, target.y);
			path_index = 0;
		}
		actMoveTo(path[path_index+1]);
		++path_index;
	}

	void aiChase()
	{
		bool has_acted = false;
		Point[] path = this.map.findPath(x, y,
			map.game.player.x, map.game.player.y);

		if (path.length <= 1) {
			aiMeander(1, 5);
		} else if (map.game.player is map.getTile(path[1]).actor) {
			actHit(path[1]);
		} else if (!actMoveTo(path[1])) {
			aiMeander(1, 5);
		}
	}*/
}

class AiGroup
{
	mixin (serializable);
	mixin SimplySerialized;

	private Actor _target;
	private Array!AiActor leaders;
	private Array!AiActor subordinates;

	@property Actor target() { return _target; }
	@property target(Actor target)
	{
		_target = target;
		foreach (e; leaders[]) {
			e.target = target;
		}
		foreach (e; subordinates[]) {
			e.target = target;
		}
	}

	this(AiActor[] leaders = [], AiActor[] subordinates = [])
	{
		this.leaders = Array!AiActor(leaders);
		this.subordinates = Array!AiActor(subordinates);
	}
	this(Serializer serializer) { this(); }
}
