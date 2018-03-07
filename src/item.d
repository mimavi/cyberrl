import term;

class Item
{
	abstract @property Symbol symbol();
	abstract @property string name();

	void draw(int x, int y)
	{
		term.setSymbol(x, y, symbol);
	}
}

class LightkatanaItem : Item
{
	override @property Symbol symbol() { return Symbol('/', Color.cyan); }
	override @property string name() { return "lightkatana"; }
}
