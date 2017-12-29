module term;
static import ncurses = deimos.ncurses;
public import term_common;

private immutable uint term_width = 80;
private immutable uint term_height = 24;

private Symbol[term_width*term_height] array;

static this()
{
	ncurses.initscr();
	ncurses.cbreak();
	ncurses.keypad(ncurses.stdscr, true);

	ncurses.start_color();
	for (Color fg; fg < Color.max+1; fg++) {
		for (Color bg; bg < Color.max+1; bg++) {
			ncurses.init_pair(cast(short)(fg+bg*Color.max+1),
			                  cast(short)fg,
			                  cast(short)bg);
		}
	}
}

static ~this()
{
	ncurses.endwin();
}

Key readKey()
{
	while (true) {
		int code = ncurses.getch();
		if ('a' <= code && code <= 'z')
			return cast(Key)(cast(int)Key.a + (code - cast(int)'a'));
		if ('A' <= code && code <= 'Z')
			return cast(Key)(cast(int)Key.A + (code - cast(int)'A'));
		if ('0' <= code && code <= '9')
			return cast(Key)(cast(int)Key.keypad_0 + (code - cast(int)'0'));
		// TODO: Support for: '!' '@' '#' '$' '%' '^' '&' '*' '(' ')'
	}
}

void refresh()
{
	for (int y = 0; y < term_height; y++) {
		for (int x = 0; x < term_width; x++) {
			Symbol symbol = array[x+y*term_width];
			ulong color_pair = ncurses.COLOR_PAIR(
				cast(short)(symbol.color+symbol.bg_color*Color.count));
			ncurses.attron(symbol.is_bright ?
			               color_pair | ncurses.A_BOLD :
			               color_pair);
			ncurses.mvaddch(y, x, symbol.chr);
		}
	}

	ncurses.refresh();
}

void setSymbol(int x, int y, Symbol symbol)
{
	array[x+y*term_width] = symbol;
}

Symbol getSymbol(int x, int y)
{
	return array[x+y*term_width];
}
