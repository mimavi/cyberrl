import std.stdio;
import std.format;
import std.random;
import std.datetime;
import util;
import term;
import game;

Game main_game;

void main()
{
	try {
		import map;
		import actor;
		import tile;
		import item;
		main_game = new Game;
		main_game.player = new PlayerActor;
		main_game.spawn(main_game.player, 10, 10);
		//main_game.spawn(new Actor, 12, 12);
		auto sm = new SaveManager();
		sm.save(main_game);
		auto rng = Random(
			cast(uint) Clock.currTime().fracSecs().total!"hnsecs");
		foreach (i; 1..10000) {
			int x = uniform(0, 300, rng);
			int y = uniform(0, 300, rng);
			main_game.map.get_tile(x, y) = new WallTile;
		}
		foreach (i; 1..10000) {
			int x = uniform(0, 300, rng);
			int y = uniform(0, 300, rng);
			main_game.map.get_tile(x, y).items.insert(new LightkatanaItem);
		}
		main_game.centerizeCamera(main_game.player.x, main_game.player.y);
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
