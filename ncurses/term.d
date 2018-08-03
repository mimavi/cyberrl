module term;

static import ncurses = deimos.ncurses;

public import term_common;

private Key[128] ascii_to_key = [
	Key.none, Key.none, Key.none, Key.none,
	Key.none, Key.none, Key.none, Key.none,
	Key.none, Key.tab, Key.enter, Key.none,
	Key.none, Key.none, Key.none, Key.none,
	Key.none, Key.none, Key.none, Key.none,
	Key.none, Key.none, Key.none, Key.none,
	Key.none, Key.none, Key.none, Key.escape,
	Key.none, Key.none, Key.none, Key.none,
	Key.space, Key.exclam, Key.quote, Key.hash,
	Key.dollar, Key.percent, Key.ampersand, Key.apostrophe,
	Key.lparen, Key.rparen, Key.asterisk, Key.plus,
	Key.comma, Key.minus, Key.period, Key.slash,
	Key.digit_0, Key.digit_1, Key.digit_2, Key.digit_3,
	Key.digit_4, Key.digit_5, Key.digit_6, Key.digit_7,
	Key.digit_8, Key.digit_9, Key.colon, Key.semicolon,
	Key.less, Key.equals, Key.greater, Key.question,
	Key.at, Key.A, Key.B, Key.C,
	Key.D, Key.E, Key.F, Key.G,
	Key.H, Key.I, Key.J, Key.K,
	Key.L, Key.M, Key.N, Key.O,
	Key.P, Key.Q, Key.R, Key.S,
	Key.T, Key.U, Key.V, Key.W,
	Key.X, Key.Y, Key.Z, Key.lbracket,
	Key.backslash, Key.rbracket, Key.caret, Key.underscore,
	Key.backtick, Key.a, Key.b, Key.c,
	Key.d, Key.e, Key.f, Key.g,
	Key.h, Key.i, Key.j, Key.k,
	Key.l, Key.m, Key.n, Key.o,
	Key.p, Key.q, Key.r, Key.s,
	Key.t, Key.u, Key.v, Key.w,
	Key.x, Key.y, Key.z, Key.lbrace,
	Key.vbar, Key.rbrace, Key.tilde, Key.del
];

private Key[int] keycode_to_key;

static this()
{
	keycode_to_key = [
		ncurses.KEY_DOWN: Key.digit_2,
		ncurses.KEY_UP: Key.digit_8,
		ncurses.KEY_LEFT: Key.digit_4,
		ncurses.KEY_RIGHT: Key.digit_6,
	];

	ncurses.initscr();
	ncurses.cbreak();
	ncurses.keypad(ncurses.stdscr, true);

	ncurses.start_color();
	for (Color fg; fg <= Color.max; fg++) {
		for (Color bg; bg <= Color.max; bg++) {
			ncurses.init_pair(cast(short)(fg+bg*(Color.max+1)),
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
		if (0 <= code && code <= 127) {
			return ascii_to_key[code];
		}
		else if (code in keycode_to_key) {
			return keycode_to_key[code];
		}
	}
}

void refresh()
{
	for (size_t y = 0; y < term_height; y++) {
		for (size_t x = 0; x < term_width; x++) {
			Symbol symbol = symbol_array[x+y*term_width];
			ulong color_pair = ncurses.COLOR_PAIR(
				cast(short)(symbol.color+symbol.bg_color*(Color.max+1)));
			ncurses.attrset(symbol.is_bright ?
			               color_pair | ncurses.A_BOLD :
			               color_pair);
			ncurses.mvaddch(cast(int)y, cast(int)x, symbol.chr);
		}
	}
	ncurses.refresh();
}
