import std.algorithm.comparison;
import std.stdio;
import std.file;
import std.conv;
import util;
import serializer;
import term;
import actor;
import map;

class Game
{
	mixin Serializable;
	immutable int camera_width = 23, camera_height = 23;
	Map map;
	@noser PlayerActor player;
	ulong id = 0; // `id == 0` means none.
	private int camera_x, camera_y;

	this()
	{
		// Find the lowest inexistant id and claim it.
		//ulong i;
		//for (i = 0; exists(to!string(i)~".json"); ++i) {}
		//this(id);
	//}

	//this(int id)
	//{
		//this.id = id;
		/*if (!exists(to!string(i)~".json")) {
			
		}*/
		map = new Map(300, 300);
	}

	this(Serializer serializer) { this(); }
	void beforesave(Serializer serializer) {}
	void beforeload(Serializer serializer) {}
	void aftersave(Serializer serializer) {}
	void afterload(Serializer serializer) {}

	void read(ulong id)
	{
		this.id = id;
		read();
	}

	// Will throw exception if `this.id == 0`.
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

	/*void spawn(Actor actor, int x, int y)
	{
		actor.game = this;
		map.addActor(actor, x, y);
	}

	void despawn(Actor actor)
	{
		actor.is_despawned = true;
	}*/

	void run()
	{ 
		while(map.update())
		{}
	}

	void draw()
	{
		map.draw(camera_x, camera_y, 0, 0, 23, 23);
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
}
