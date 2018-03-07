import std.stdio;
import util;
import term;
import actor;
import map;

class Game
{
	immutable int camera_width = 23, camera_height = 23;
	Map map;
	@("NotSaved") PlayerActor player;
	private int camera_x, camera_y;

	this() {
		map = new Map(300, 300);
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

	void run() { 
		while (true) {
			map.update();
		}
	}

	void draw() {
		map.draw(camera_x, camera_y, 0, 0, 23, 23);
	}

	void centerizeCamera(int x, int y)
	{
		camera_x = x-camera_width/2;
		camera_y = y-camera_height/2;
	}
}
