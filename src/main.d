import std.stdio;
import util;
import term;
import menu;
import game;

Game main_game;

void main()
{
	try {
		/*import map;
		import actor;
		import tile;
		import item;
		main_game = new Game;
		main_game.player = new PlayerActor;
		main_game.player.items.insertBack(new LightkatanaItem);
		main_game.spawn(main_game.player, 10, 10);

		auto rng = Random(
			cast(uint) Clock.currTime().fracSecs().total!"hnsecs");
		foreach (i; 1..10000) {
			int x = uniform(0, 300, rng);
			int y = uniform(0, 300, rng);
			main_game.map.getTile(x, y) = new WallTile;
		}
		foreach (i; 1..10000) {
			int x = uniform(0, 300, rng);
			int y = uniform(0, 300, rng);
			main_game.map.getTile(x, y).items.insert(new LightkatanaItem);
		}
		main_game.centerizeCamera(main_game.player.x, main_game.player.y);*/

		//auto serializer = new Serializer;
		//main_game.save(serializer);
		//writeln(serializer.root.toString);

		//auto loaded_game = Game.make(serializer);
		//loaded_game.load(serializer);
		//auto loaded_serializer = new Serializer;
		//loaded_game.save(serializer);
		//writeln(serializer.root.toString);

		//main_game.run();
		//menu.mainMenu();
		menu.dualList(["a", "bb", "ccc"], ["d", "ee", "fff"], 0, false, null);
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
