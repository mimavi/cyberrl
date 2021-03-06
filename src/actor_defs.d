import std.format; // TODO: Don't use `format` function here.
import util;
import ser;
import term;
import ai;
import item_defs;
import body;

class LightsamuraiAiActor : AiActor
{
	mixin (inherited_serializable);

	this()
	{
		body_ = new HumanFleshyBody;
		super();
		items.insertBack(new LightkatanaItem);
		weapon_index = cast(int) items.length-1;
		//actWield(items.length-1);
	}
	this(Serializer serializer) { this(); }

	@property override Symbol symbol() const /*pure*/
		{ return Symbol('@', Color.magenta, true); }
	@property override string name() const /*pure*/ { return "lightsamurai"; }

	override bool actWield(int index)
	{
		if (super.actWield(index)) {
			//map.game.sendVisibleEventMsg(x, y,
				//format("%s wields %s.", name, items[index].name),
				//Color.yellow, false);
			map.game.sendVisibleEventMsg(x, y, Color.yellow, false,
				"%s wields %s.", name, items[index].name);
			return true;
		}
		return false;
	}
}
