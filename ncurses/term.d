module term;
static import ncurses = deimos.ncurses;
public import term_common;

private immutable uint term_width = 80;
private immutable uint term_height = 24;

private Symbol[term_width*term_height] array;

private Key[16] code_conv_32 = [
	Key.space, Key.exclam, Key.quote, Key.hash,
	Key.dollar, Key.percent, Key.ampersand, Key.apostrophe,
	Key.lparen, Key.rparen, Key.asterisk, Key.plus,
	Key.comma, Key.minus, Key.period, Key.slash
];

private Key[7] code_conv_58 = [
	Key.colon, Key.semicolon, Key.less, Key.equals,
	Key.greater, Key.question, Key.at
];

private Key[6] code_conv_91 = [
	Key.lbracket, Key.backslash, Key.rbracket, Key.caret,
	Key.underscore, Key.backtick
];

private Key[5] code_conv_123 = [
	Key.lbrace, Key.vbar, Key.rbrace, Key.tilde,
	Key.del
];

static this()
{
	ncurses.initscr();
	ncurses.cbreak();
	ncurses.keypad(ncurses.stdscr, true);

	ncurses.start_color();
	for (Color fg; fg <= Color.max; fg++) {
		for (Color bg; bg <= Color.max; bg++) {
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
	refresh();

	while (true) {
		int code = ncurses.getch();
		if (' ' <= code && code <= '/') {
			return code_conv_32[code - 32];
		}
		else if ('0' <= code && code <= '9') {
			return cast(Key)(cast(int)Key.digit_0 + (code - cast(int)'0'));
		}
		else if (':' <= code && code <= '@') {
			return code_conv_58[code - 58];
		}
		else if ('a' <= code && code <= 'z') {
			return cast(Key)(cast(int)Key.a + (code - cast(int)'a'));
		}
		else if ('[' <= code && code <= '`') {
			return code_conv_91[code - 91];
		}
		else if ('A' <= code && code <= 'Z') {
			return cast(Key)(cast(int)Key.A + (code - cast(int)'A'));
		}
		else if ('{' <= code && code <= 127) {
			return code_conv_123[code - 123];
		}
	}
}

void refresh()
{
	for (int y = 0; y < term_height; y++) {
		for (int x = 0; x < term_width; x++) {
			Symbol symbol = array[x+y*term_width];
			ulong color_pair = ncurses.COLOR_PAIR(
				cast(short)(symbol.color+symbol.bg_color*(Color.max+1)));
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
