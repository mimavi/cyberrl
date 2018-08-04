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
	ulong id = 0; // `id == 0` means no 
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

	/*override void beforesave(Serializer serializer) {}
	override void beforeload(Serializer serializer) {}
	override void aftersave(Serializer serializer) {}
	override void afterload(Serializer serializer) {}*/

	void read(int id)
	{
		this.id = id;
		read();
	}

	void read()
	{
	}

	void write()
	{
		if (!exists("saves")) {
			mkdir("saves");
		}
		// If no id was assigned yet,
		// find lowest possible id and claim it.
		if (id == 0) {
			for (id = 1; exists("saves/"~to!string(id)~".json"); ++id)
			{}
		}
		Serializer serializer = new Serializer;
		this.save(serializer);
		auto file = File("saves/"~to!string(id)~".json", "w");
		file.write(serializer.str);
	}

	void spawn(Actor actor, int x, int y)
	{
		actor.game = this;
		map.addActor(actor, x, y);
	}

	void despawn(Actor actor)
	{
		actor.is_despawned = true;
	}

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
}
