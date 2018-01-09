import util;
import term;
import map;

class Game
{
	immutable int camera_width = 23, camera_height = 23;
	Map map;
	private int camera_x, camera_y;

	this() {
		map = new Map(300, 300);
	}

	void run() { 
		while (true) {
			map.draw(camera_x, camera_y, 0, 0, 23, 23);
			map.update();
		}
	}

	void centerizeCamera(int x, int y)
	{
		camera_x = x-camera_width/2;
		camera_y = y-camera_height/2;
	}
}
