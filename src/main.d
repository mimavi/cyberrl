import term;
import game;
import actor;
import std.stdio;
import std.format;

Game main_game;
PlayerActor main_player;

void main()
{
	try {
		import map;
		main_game = new Game;
		main_player = new PlayerActor(main_game.map, 10, 10);
		main_game.map.get_tile(9, 9) = new WallTile;
		main_game.map.get_tile(9, 11) = new WallTile;
		main_game.map.get_tile(11, 9) = new WallTile;
		main_game.map.get_tile(11, 11) = new WallTile;
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
