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
	enum camera_y_margin = 1;
	enum camera_width = 21;
	enum camera_height = 21;
	enum msg_x_margin = 24;
	enum msg_y_margin = 2;
	enum msg_display_width = term_width-msg_x_margin;
	enum msg_display_height = term_height-msg_y_margin;

	Array!Msg msgs;
	Map map;
	@noser PlayerActor player;
	ulong id = 0; // `id == 0` means none.
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

		if (msgs.length > 0) {
			auto lines = splitAtSpaces(msgs[$-1].str, msg_display_width);
			int y = msg_y_margin+msg_display_height-lines.length;
			int index = msgs.length-1;
			while (y+lines.length-1 >= msg_y_margin) {
				foreach (int i, string e; lines) {
					if (y+i >= msg_y_margin) {
						term.write(msg_x_margin, y+i, e,
								msgs[index].color, msgs[index].is_bright);
					}
				}
				if (index <= 0) {
					break;
				}
				--index;
				lines = splitAtSpaces(msgs[index].str, msg_display_width);
				y -= lines.length;
			}
		}

		//foreach (int i, Msg e; msgs) {
		//foreach (i; 0..min(msgs.length, msg_display_height)) {
			/*auto msg = msgs[$-i-1];
			term.write(msg_x_margin, msg_y_margin+msg_display_height-i-1, 
				msg.str, msg.color, msg.is_bright,
				msg_display_width);*/
		//}
		/*for ({int i = 0; auto msg = msgs}
		i < min(msgs.length, msg_display_height);
		i += */

		/*int i = 0;
		do {
			auto msg = msgs[$-i-1];
			i += lines.length;
		} while (i < min(msgs.length, msg_display_height));*/
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
			//menu.sendMsg(msg, color, is_bright);
			msgs.insertBack(Msg(str, color, is_bright));
		}
	}
}
