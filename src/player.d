import std.typecons;
import util;
import main;
import menu;
import ser;
import term;
import tile;
import actor;
import body;

class PlayerActor : Actor
{
	mixin InheritedSerializable;

	enum body_parts_text_x = 24;
	enum body_parts_text_y = 1;
	enum body_part_text_width = 11;

	string _player_name;

	@property override Symbol symbol()
		{ return Symbol('@', Color.white, Color.black, true); }
	@property override string name() { return "you"; }
	@property string player_name() { return _player_name; }
	@property void player_name(string name) { _player_name = name; }
	@property private string[int] item_appends()
	{
		return [
			weapon_index: " (currently wielded)",
		];
	}

	this()
	{
		body_ = new HumanFleshyBody;
		super();
	}
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
				has_acted = actMoveTo(x+key_to_point[key].x, y+key_to_point[key].y);
					//actMoveTo(x+util.key_to_x[key], y+util.key_to_y[key]);
				if (!has_acted) {
					has_acted = actOpen(x+key_to_point[key].x, y+key_to_point[key].y);
				}
			} else if (key == Key.g) {
				int index;
				if (menu.selectItem(map.getTile(x, y).items, (string[int]).init,
				"Select item to pick up:", index)) {
					has_acted = actPickUp(index);
				}
			} else if (key == Key.d) {
				int index;
				if (menu.selectItem(items, item_appends, "Select item to drop:",
				index)) {
					has_acted = actDrop(index);
				}
			} else if (key == Key.w) {
				int index;
				if (menu.selectItem(items, item_appends, "Select item to wield:",
				index)) {
					has_acted = actWield(index);
				}
			} else if (key == Key.period) {
				has_acted = actWait();
			}
		} while (!has_acted);
		return true;
	}

	void drawBodyStatus()
	{
		term.write(body_parts_text_x,
			body_parts_text_y, " left arm",
			drawBodyStatusDamageArgs(HumanFleshyBodyPart.left_arm).expand,
			body_part_text_width);
		term.write(body_parts_text_x+body_part_text_width,
			body_parts_text_y, "   head",
			drawBodyStatusDamageArgs(HumanFleshyBodyPart.head).expand,
			body_part_text_width);
		term.write(body_parts_text_x+2*body_part_text_width,
			body_parts_text_y, " right arm",
			drawBodyStatusDamageArgs(HumanFleshyBodyPart.right_arm).expand,
			body_part_text_width);
		term.write(body_parts_text_x,
			body_parts_text_y+1, " left leg",
			drawBodyStatusDamageArgs(HumanFleshyBodyPart.left_leg).expand,
			body_part_text_width);
		term.write(body_parts_text_x+body_part_text_width,
			body_parts_text_y+1, "  torso",
			drawBodyStatusDamageArgs(HumanFleshyBodyPart.torso).expand,
			body_part_text_width);
		term.write(body_parts_text_x+2*body_part_text_width,
			body_parts_text_y+1, " right leg",
			drawBodyStatusDamageArgs(HumanFleshyBodyPart.right_leg).expand,
			body_part_text_width);
	}

	private Tuple!(Color, bool)
		drawBodyStatusDamageArgs(HumanFleshyBodyPart part) const pure
	{
		int percentage = 100-body_.getDamage(part)*100
			/ body_.getMaxDamage(stats, part);
		if (percentage == 100) {
			return tuple(Color.white, true);
		} else if (percentage >= 75) {
			return tuple(Color.white, false);
		} else if (percentage >= 50) {
			return tuple(Color.yellow, true);
		} else if (percentage >= 25) {
			return tuple(Color.red, true);
		} else if (percentage > 0) {
			return tuple(Color.red, false);
		} else {
			return tuple(Color.black, true);
		}
	}

	override bool actOpen(int x, int y)
	{
		bool result = super.actOpen(x, y);
		if (result) {
			map.game.sendVisibleEventMsg(x, y, Color.yellow, false,
				"you open the door");
		}
		return result;
	}

	/*private bool drawBodyStatusDamageToBright(int damage, int max_damage)
		const pure
	{
		int percentage = damage*100/max_damage;
		if (percentage == 100) {
			return true;
		} else if (percentage >= 75) {
			return false;
		} else if (percentage >= 50) {
			return true;
		} else if (percentage >= 25) {
			return true;
		} else if (percentage > 0) {
			return false;
		} else {
			return true;
		}
	}*/
}
