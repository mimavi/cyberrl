import std.format; // TODO: Don't use `format` function here.
import util;
import ser;
import term;
import ai;
import item;

class LightsamuraiAiActor : AiActor
{
	mixin InheritedSerializable;

	this()
	{
		items.insertBack(new LightkatanaItem);
		weapon_index = items.length-1;
		//actWield(items.length-1);
	}
	this(Serializer serializer) { this(); }

	@property override Symbol symbol()
		{ return Symbol('@', Color.magenta, true); }
	@property override string name() { return "lightsamurai"; }

	override bool actWield(int index)
	{
		if (super.actWield(index)) {
			map.game.sendVisibleEventMsg(x, y,
				format("%s wields %s.", name, items[index].name),
				Color.yellow, false);
			return true;
		}
		return false;
	}
}