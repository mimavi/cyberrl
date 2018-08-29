import std.algorithm.comparison;
import std.conv;
import std.container;
import std.stdio;
import std.file;
import util;
import ser;
import term;
import player;
import map;

struct Msg
{
	mixin Serializable;
	mixin SimplySerialized;
	string str;
	Color color;
	bool is_bright;

	this(Serializer serializer) {}
	this(string str, Color color, bool is_bright)
	{
		this.str = str;
		this.color = color;
		this.is_bright = is_bright;
	}
}

class Game
{
	mixin Serializable;

	enum camera_x_margin = 1;
	enum camera_y_margin = 2;
	enum camera_width = 21;
	enum camera_height = 21;
	enum message_x_margin = 24;
	enum message_y_margin = 3;
	enum message_display_width = term_width-message_x_margin;
	enum message_display_height = term_height-message_y_margin;
	//enum body_parts_text_x = message_x_margin;
	//enum body_parts_text_y = 1;
	//enum body_part_text_width = 11;

	@noser PlayerActor player;
	Map map;
	private Array!Msg messages;
	private ulong id = 0; // `id == 0` means none.
	private int camera_x, camera_y;

	this(Map map)
	{
		//map = new Map(300, 300);
		this.map = map;
		this.map.game = this;
	}

	this(Serializer serializer) {}
	void beforesave(Serializer serializer) {}
	void beforeload(Serializer serializer) {}
	void aftersave(Serializer serializer) {}
	void afterload(Serializer serializer) { map.game = this; }

	void read(ulong id)
	{
		this.id = id;
		read();
	}

	// Will throw exception if `this.id == 0`.
	// TODO: Trivial task: make this function use `idToFilename` function.
	void read()
	{
		Serializer serializer = new Serializer;
		auto file = File("saves/"~to!string(id)~".json", "r");
		serializer.str = file.readln('\0');
		this.load(serializer);
	}

	void write()
	{
		if (!exists("saves")) {
			mkdir("saves");
		}
		// If no id was assigned yet,
		// find lowest possible id and claim it.
		if (id == 0) {
			for (id = 1; exists(idToFilename(id)); ++id)
			{}
		}

		Serializer serializer = new Serializer;
		this.save(serializer);
		auto file = File(idToFilename(id), "w");
		file.write(serializer.str);
	}

	void run()
	{ 
		while(map.update())
		{}
	}

	// XXX: How about drawing the map here instead
	// and making the `map` module independent of the `term` module?
	void draw()
	{
		map.draw(camera_x, camera_y, camera_x_margin, camera_y_margin,
			camera_width, camera_height);

		term.write(0, 0, player.player_name, Color.white, true);
		player.drawBodyStatus();
		/*term.write(body_parts_text_x,
			body_parts_text_y, " left arm", Color.white, true,
			body_part_text_width);
		term.write(body_parts_text_x+body_part_text_width,
			body_parts_text_y, "   head", Color.white, true,
			body_part_text_width);
		term.write(body_parts_text_x+2*body_part_text_width,
			body_parts_text_y, " right arm", Color.white, true,
			body_part_text_width);
		term.write(body_parts_text_x,
			body_parts_text_y+1, " left leg", Color.white, true,
			body_part_text_width);
		term.write(body_parts_text_x+body_part_text_width,
			body_parts_text_y+1, "   torso", Color.white, true,
			body_part_text_width);
		term.write(body_parts_text_x+2*body_part_text_width,
			body_parts_text_y+1, " right leg", Color.white, true,
			body_part_text_width);*/

		player.drawBodyStatus();

		if (messages.length > 0) {
			auto lines = splitAtSpaces(messages[$-1].str, message_display_width);
			int y = message_y_margin+message_display_height-cast(int)lines.length;
			int index = cast(int)messages.length-1;
			while (y+lines.length-1 >= message_y_margin) {
				foreach (int i, string e; lines) {
					if (y+i >= message_y_margin) {
						term.write(message_x_margin, y+i, e,
								messages[index].color, messages[index].is_bright);
					}
				}
				if (index <= 0) {
					break;
				}
				--index;
				lines = splitAtSpaces(messages[index].str, message_display_width);
				y -= lines.length;
			}
		}

		//foreach (int i, Msg e; messages) {
		//foreach (i; 0..min(messages.length, message_display_height)) {
			/*auto message = messages[$-i-1];
			term.write(message_x_margin, message_y_margin+message_display_height-i-1, 
				message.str, message.color, message.is_bright,
				message_display_width);*/
		//}
		/*for ({int i = 0; auto message = messages}
		i < min(messages.length, message_display_height);
		i += */

		/*int i = 0;
		do {
			auto message = messages[$-i-1];
			i += lines.length;
		} while (i < min(messages.length, message_display_height));*/
	}

	void centerizeCamera(int x, int y)
	{
		camera_x = x-camera_width/2;
		camera_y = y-camera_height/2;
	}

	static ulong filenameToId(string filename)
	{
		// Remove leading "saves/" and trailing ".json",
		// then convert to `int`.
		return to!int(filename[6..$][0..$-5]);
	}

	static string idToFilename(ulong id)
	{
		return "saves/"~to!string(id)~".json";
	}

	// TODO: Allow for several source points to be specified.
	void sendVisibleEventMsg(int x, int y, string str,
		Color color, bool is_bright)
	{
		if (map.getTile(x, y).is_visible) {
			//menu.sendMsg(message, color, is_bright);
			messages.insertBack(Msg(str, color, is_bright));
		}
	}
}
