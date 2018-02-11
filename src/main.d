import term;
import game;
import actor;
import std.stdio;
import std.format;
import std.random;
import std.datetime;

Game main_game;
PlayerActor main_player;

void main()
{
	try {
		import map;
		main_game = new Game;
		main_player = new PlayerActor(main_game.map, 10, 10);
		auto rng = Random(cast(uint) Clock.currTime().fracSecs().total!"hnsecs");
		foreach (i; 1..10000) {
			int x = uniform(0, 300, rng);
			int y = uniform(0, 300, rng);
			main_game.map.get_tile(x, y) = new WallTile;
		}
		main_game.centerizeCamera(main_player.x, main_player.y);
		main_game.run();
	}
	// TODO: Better error and exception handling.
	catch (Error e) {
		writefln("%s %d %s: %s",
			e.file, e.line, e.info, e.msg);
		term.readKey();
		return;
	}
	catch (Exception e) {
		writefln("%s %d %s: %s",
			e.file, e.line, e.info, e.msg);
		term.readKey();
		return;
	}
}
