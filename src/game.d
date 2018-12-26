import std.algorithm.comparison;
import std.math;
import std.conv;
import std.container;
import std.format;
import std.ascii;
import std.regex;
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
	string fmt;
	string[] args;
	Color color;
	bool is_bright;

	this(Serializer serializer) /*pure*/ {}
	this(string fmt, string[] args, Color color, bool is_bright) /*pure*/
	{
		this.fmt = fmt;
		this.args = args;
		this.color = color;
		this.is_bright = is_bright;
	}
}

class Game
{
	mixin Serializable;

	enum viewport_x = 1;
	enum viewport_y = 2;
	enum viewport_width = 21;
	enum viewport_height = 21;
	enum msg_display_x = 24;
	enum msg_display_y = 3;
	enum msg_display_width = term_width-msg_display_x;
	enum msg_display_height = term_height-msg_display_y;
	//enum body_parts_text_x = msg_display_x;
	//enum body_parts_text_y = 1;
	//enum body_part_text_width = 11;

	@noser PlayerActor player;
	Map map;
	private Array!Msg msgs;
	private ulong id = 0; // `id == 0` means none.
	private int camera_x, camera_y;

	this(Map map) /*pure*/
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
		map.draw(camera_x, camera_y, viewport_x, viewport_y,
			viewport_width, viewport_height);

		term.write(0, 0, player.player_name, Color.white, true);
		player.drawBodyStatus();

		if (msgs.length > 0) {
			//auto str = format(msgs[$-1].fmt, msgs[$-1].args);
			auto str = arrayFormat(msgs[$-1].fmt, msgs[$-1].args);
			str = toUpper(str[0])~str[1..$];
			if (str[$-1] != '.' && str[$-1] != '!' && str[$-1] != '?') {
				str = str[0..$]~".";
			}
			auto lines = splitAtSpaces(str, msg_display_width);
			int y = msg_display_y+msg_display_height-cast(int)lines.length;
			int index = cast(int)msgs.length-1;
			while (y+lines.length-1 >= msg_display_y) {
				foreach (int i, string e; lines) {
					if (y+i >= msg_display_y) {
						term.write(msg_display_x, y+i, e,
								msgs[index].color, msgs[index].is_bright);
					}
				}
				if (index <= 0) {
					break;
				}
				--index;
				//str = format(msgs[index].fmt, msgs[index].args);
				str = arrayFormat(msgs[index].fmt, msgs[index].args);
				str = toUpper(str[0])~str[1..$];
				if (str[$-1] != '.' && str[$-1] != '!' && str[$-1] != '?') {
					str = str[0..$]~".";
				}
				lines = splitAtSpaces(str, msg_display_width);
				y -= lines.length;
			}
		}

		//foreach (int i, Msg e; msgs) {
		//foreach (i; 0..min(msgs.length, msg_display_height)) {
			/*auto msg = msgs[$-i-1];
			term.write(msg_display_x, msg_display_y+msg_display_height-i-1, 
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

	void sendMsg(Color color, bool is_bright, string fmt, string[] args...)
	{
		msgs.insertBack(Msg(fmt, args.dup, color, is_bright));
	}

	// Note: The first character in resulting sentence
	// is automatically capitalized.
	// The comma at the end of sentence is automatically inserted
	// if not present, and also if the sentence does not end with '!' or '?'.
	void sendVisibleEventMsg(const Point[] ps, Color color, bool is_bright,
		string fmt, string[] args...)
	{
		bool is_any_visible = false;
		foreach (int i, e; ps) {
			auto re = regex(r"%(\d*)\("~to!string(i+1)~r"\)\|(\d*)\$");
			if (map.getTile(e).is_visible) {
				is_any_visible = true;
				fmt = replaceAll(fmt, re, "%$1$$");
			} else {
				fmt = replaceAll(fmt, re, "%$2$$");
			}
		}
		if (is_any_visible) {
			sendMsg(color, is_bright, fmt, args);
			//msgs.insertBack(Msg(fmt, args.dup, color, is_bright));
		}
	}
	void sendVisibleEventMsg(Point p, Color color, bool is_bright,
		string fmt, string[] args...)
	{
		sendVisibleEventMsg([p], color, is_bright, fmt, args);
	}
	void sendVisibleEventMsg(int x, int y, Color color, bool is_bright,
		string fmt, string[] args...)
	{
		sendVisibleEventMsg(Point(x, y), color, is_bright, fmt, args);
	}

	void centerizeCamera(int x, int y)
	{
		camera_x = x-viewport_width/2;
		camera_y = y-viewport_height/2;
		draw();
	}
	void centerizeCamera(Point p) { centerizeCamera(p.x, p.y); }

	bool setSymbolOnViewport(int x, int y, Symbol symbol)
	{
		if (abs(x-camera_x-viewport_width/2) >= viewport_width/2
		|| abs(y-camera_y-viewport_height/2) >= viewport_height/2) {
			return false;
		}
		term.setSymbol(viewport_x+x-camera_x,
			viewport_y+y-camera_y, symbol);
		return true;
	}
	bool setSymbolOnViewport(Point p, Symbol symbol)
	{
		return setSymbolOnViewport(p.x, p.y, symbol);
	}

	static ulong filenameToId(string filename) /*pure*/
	{
		// Remove leading "saves/" and trailing ".json",
		// then convert to `int`.
		return to!int(filename[6..$][0..$-5]);
	}

	static string idToFilename(ulong id) /*pure*/
	{
		return "saves/"~to!string(id)~".json";
	}
}
