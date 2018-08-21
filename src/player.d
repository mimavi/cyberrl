import util;
import main;
import menu;
import ser;
import term;
import tile;
import actor;

class PlayerActor : Actor
{
	mixin InheritedSerializable;

	@property override Symbol symbol()
		{ return Symbol('@', Color.white, Color.black, true); }
	@property override string name() { return "you"; }

	this() { super(); }
	this(Serializer serializer) { this(); }

	override void initPos(int x, int y)
	{
		super.initPos(x, y);
		map.game.centerizeCamera(x, y);
	}

	override bool subupdate()
	{
		void fovCallback(int tile_x, int tile_y, Tile tile)
		{
			//tile.draw(x, y);
			//tile.is_visibles = true;
			//tile.is_discovered = true;
			tile.is_visible = true;
			map.visibles.insertBack(Point(tile_x, tile_y));
		}

		foreach (e; map.visibles[]) {
			map.getTile(e).is_visible = false;
		}

		map.visibles.length = 0;
		map.fov(x, y, int.max, &fovCallback);

		bool has_acted = false;

		do {
			map.game.draw();
			auto key = term.readKey();
			if (key == Key.escape) {
				if (!menu.inGameMenu(map.game)) {
					return false;
				}
			} else if (key >= Key.digit_1 && key <= Key.digit_9) {
				has_acted = 
					actMoveTo(x+util.key_to_x[key], y+util.key_to_y[key]);
			} else if (key == Key.g) {
				int index;
				if (menu.selectItem(map.getTile(x, y).items,
					"Select item to pick up:", index)) {
					has_acted = actPickUp(index);
				}
			} else if (key == Key.d) {
				int index;
				if (menu.selectItem(items,
					"Select item to drop:", index)) {
					has_acted = actDrop(index);
				}
			} else if (key == Key.period) {
				has_acted = actWait();
			}
		} while (!has_acted);
		return true;
	}
}
