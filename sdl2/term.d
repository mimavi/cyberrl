module term;
import std.format;
import core.stdc.stdlib;
import core.stdc.ctype;
import derelict.sdl2.sdl;
public import term_common;

private immutable int symbol_width = 9;
private immutable int symbol_height = 16;
private immutable int symbol_map_width = 80;
private immutable int symbol_map_height = 24;
private immutable int codepage_width = 16;
private immutable int codepage_height = 16;
private immutable ubyte[Color.max+1] color_to_r = [
	Color.black:   0,
	Color.red:     128,
	Color.green:   0,
	Color.yellow:  128,
	Color.blue:    0,
	Color.magenta: 128,
	Color.cyan:    0,
	Color.white:   128,
];
private immutable ubyte[Color.max+1] color_to_g = [
	Color.black:   0,
	Color.red:     0,
	Color.green:   128,
	Color.yellow:  128,
	Color.blue:    0,
	Color.magenta: 0,
	Color.cyan:    128,
	Color.white:   128,
];
private immutable ubyte[Color.max+1] color_to_b = [
	Color.black:   0,
	Color.red:     0,
	Color.green:   0,
	Color.yellow:  0,
	Color.blue:    128,
	Color.magenta: 128,
	Color.cyan:    128,
	Color.white:   128,
];

private SDL_Window* window;
private SDL_Renderer* renderer;
private SDL_Texture* codepage;

private Symbol[] symbol_map;

private Key[SDL_Keycode] keycode_to_key;
private Key[SDL_Keycode] alnum_keycode_to_shifted_key;

static this()
{
	symbol_map.length = symbol_map_width*symbol_map_height;
	keycode_to_key = [
		SDLK_LEFT: Key.digit_4,
		SDLK_RIGHT: Key.digit_6,
		SDLK_UP: Key.digit_8,
		SDLK_DOWN: Key.digit_2,
		SDLK_KP_1: Key.digit_1,
		SDLK_KP_2: Key.digit_2,
		SDLK_KP_3: Key.digit_3,
		SDLK_KP_4: Key.digit_4,
		SDLK_KP_5: Key.digit_5,
		SDLK_KP_6: Key.digit_6,
		SDLK_KP_7: Key.digit_7,
		SDLK_KP_8: Key.digit_8,
		SDLK_KP_9: Key.digit_9,
		SDLK_0: Key.digit_0,
		SDLK_1: Key.digit_1,
		SDLK_2: Key.digit_2,
		SDLK_3: Key.digit_3,
		SDLK_4: Key.digit_4,
		SDLK_5: Key.digit_5,
		SDLK_6: Key.digit_6,
		SDLK_7: Key.digit_7,
		SDLK_8: Key.digit_8,
		SDLK_9: Key.digit_9,
		SDLK_a: Key.a,
		SDLK_b: Key.b,
		SDLK_c: Key.c,
		SDLK_d: Key.d,
		SDLK_e: Key.e,
		SDLK_f: Key.f,
		SDLK_g: Key.g,
		SDLK_h: Key.h,
		SDLK_i: Key.i,
		SDLK_j: Key.j,
		SDLK_k: Key.k,
		SDLK_l: Key.l,
		SDLK_m: Key.m,
		SDLK_n: Key.n,
		SDLK_o: Key.o,
		SDLK_p: Key.p,
		SDLK_q: Key.q,
		SDLK_r: Key.r,
		SDLK_s: Key.s,
		SDLK_t: Key.t,
		SDLK_u: Key.u,
		SDLK_v: Key.v,
		SDLK_w: Key.w,
		SDLK_x: Key.x,
		SDLK_y: Key.y,
		SDLK_z: Key.z,
		SDLK_LEFTBRACKET: Key.lbracket,
		SDLK_RIGHTBRACKET: Key.rbracket,
		SDLK_BACKSLASH: Key.backslash,
		SDLK_SEMICOLON: Key.semicolon,
		SDLK_QUOTE: Key.apostrophe,
		SDLK_COMMA: Key.comma,
		SDLK_PERIOD: Key.period,
		SDLK_SLASH: Key.slash,
		SDLK_BACKQUOTE: Key.backtick,
	];
	alnum_keycode_to_shifted_key = [
		SDLK_LEFT: Key.dollar,
		SDLK_RIGHT: Key.caret,
		SDLK_UP: Key.asterisk,
		SDLK_DOWN: Key.at,
		SDLK_KP_1: Key.exclam,
		SDLK_KP_2: Key.at,
		SDLK_KP_3: Key.hash,
		SDLK_KP_4: Key.dollar,
		SDLK_KP_5: Key.percent,
		SDLK_KP_6: Key.caret,
		SDLK_KP_7: Key.ampersand,
		SDLK_KP_8: Key.asterisk,
		SDLK_KP_9: Key.lparen,
		SDLK_0: Key.lparen,
		SDLK_1: Key.exclam,
		SDLK_2: Key.at,
		SDLK_3: Key.hash,
		SDLK_4: Key.dollar,
		SDLK_5: Key.percent,
		SDLK_6: Key.caret,
		SDLK_7: Key.ampersand,
		SDLK_8: Key.asterisk,
		SDLK_9: Key.rparen,
		SDLK_a: Key.A,
		SDLK_b: Key.B,
		SDLK_c: Key.C,
		SDLK_d: Key.D,
		SDLK_e: Key.E,
		SDLK_f: Key.F,
		SDLK_g: Key.G,
		SDLK_h: Key.H,
		SDLK_i: Key.I,
		SDLK_j: Key.J,
		SDLK_k: Key.K,
		SDLK_l: Key.L,
		SDLK_m: Key.M,
		SDLK_n: Key.N,
		SDLK_o: Key.O,
		SDLK_p: Key.P,
		SDLK_q: Key.Q,
		SDLK_r: Key.R,
		SDLK_s: Key.S,
		SDLK_t: Key.T,
		SDLK_u: Key.U,
		SDLK_v: Key.V,
		SDLK_w: Key.W,
		SDLK_x: Key.X,
		SDLK_y: Key.Y,
		SDLK_z: Key.Z,
		SDLK_LEFTBRACKET: Key.lbrace,
		SDLK_RIGHTBRACKET: Key.rbrace,
		SDLK_BACKSLASH: Key.vbar,
		SDLK_SEMICOLON: Key.colon,
		SDLK_QUOTE: Key.quote,
		SDLK_COMMA: Key.less,
		SDLK_PERIOD: Key.greater,
		SDLK_SLASH: Key.question,
		SDLK_BACKQUOTE: Key.tilde
	];
	DerelictSDL2.load();
	if(SDL_Init(SDL_INIT_VIDEO) != 0)
		throw new TermException(format("Unable to initialize SDL: %s", SDL_GetError()));
	window = SDL_CreateWindow(
		"CyberRL",
		SDL_WINDOWPOS_CENTERED,
		SDL_WINDOWPOS_CENTERED,
		symbol_width*symbol_map_width,
		symbol_height*symbol_map_height,
		0);
	if(window is null){
		throw new TermException(
			format("Unable to create SDL window: %s", SDL_GetError()));
	}
	renderer = SDL_CreateRenderer(window, -1, 0);
	if(renderer is null){
		throw new TermException(
			format("Unable to create SDL renderer: %s", SDL_GetError()));
	}
	SDL_Surface* codepagesur = SDL_LoadBMP("sdl2/cp437.bmp");
	if(codepagesur is null)
		throw new TermException(
			format("Unable to load 'sdl2/cp437.bmp': %s", SDL_GetError()));
	codepage = SDL_CreateTextureFromSurface(renderer, codepagesur);
	if(codepage is null)
		throw new TermException(
			format("Unable to create SDL texture from SDL surface: %s",
			SDL_GetError()));
	SDL_FreeSurface(codepagesur);
}

static ~this()
{
	SDL_DestroyTexture(codepage);
	SDL_DestroyRenderer(renderer);
	SDL_DestroyWindow(window);
	SDL_Quit();
}

Key readKey()
{
	refresh();
	SDL_Event event;
	do{
		if(SDL_WaitEvent(&event) != 1){
			throw new TermException(
				format("Waiting for SDL event failed: %s", SDL_GetError()));
		}
		if(event.type == SDL_QUIT){
			exit(EXIT_SUCCESS);
		}
	// Repeat until a valid key is pressed.
	// Make sure that keycode is a valid key for `keycode_to_key`.
	}while(event.type != SDL_KEYDOWN
	// Keypad keys are valid.
	|| ((event.key.keysym.sym < SDLK_KP_1
			|| event.key.keysym.sym > SDLK_KP_0)
	// Alphabetic keys are valid.
		&& (event.key.keysym.sym < SDLK_a
			|| event.key.keysym.sym > SDLK_z)
	// Arrow keys are valid.
		&& event.key.keysym.sym != SDLK_LEFT
		&& event.key.keysym.sym != SDLK_RIGHT
		&& event.key.keysym.sym != SDLK_UP
		&& event.key.keysym.sym != SDLK_DOWN));
	
	// If shift is held while a key valid for `alnum_keycode_to_shifted_key`
	// is pressed, then convert it to its shifted analogon.
	// All alphanumeric keys and
	// '[', ']', '\', ';', '\'', ',', '.', '/' are valid here.
	if((event.key.keysym.mod & KMOD_SHIFT)
	&& ((event.key.keysym.sym >= SDLK_a
		&& event.key.keysym.sym <= SDLK_z)
	|| (event.key.keysym.sym >= SDLK_0
		&& event.key.keysym.sym <= SDLK_9))
	|| event.key.keysym.sym == SDLK_LEFTBRACKET
	|| event.key.keysym.sym == SDLK_RIGHTBRACKET
	|| event.key.keysym.sym == SDLK_BACKSLASH
	|| event.key.keysym.sym == SDLK_SEMICOLON
	|| event.key.keysym.sym == SDLK_QUOTE
	|| event.key.keysym.sym == SDLK_COMMA
	|| event.key.keysym.sym == SDLK_PERIOD
	|| event.key.keysym.sym == SDLK_SLASH
	|| event.key.keysym.sym == SDLK_BACKQUOTE){
		return alnum_keycode_to_shifted_key[event.key.keysym.sym];
	}

	return keycode_to_key[event.key.keysym.sym];
}

void refresh()
{
	SDL_RenderClear(renderer);
	for(int i = 0; i < symbol_map_width; ++i){
		for(int j = 0; j < symbol_map_height; ++j){
			int index = i+j*symbol_map_width;
			SDL_Rect srcrect = {
				x: (symbol_map[index].chr%codepage_width)*symbol_width,
				y: (symbol_map[index].chr/codepage_width)*symbol_height,
				w: symbol_width,
				h: symbol_height,
			};
			SDL_Rect destrect = {
				x: i*symbol_width,
				y: j*symbol_height,
				w: symbol_width,
				h: symbol_height,
			};
			SDL_SetTextureColorMod(codepage,
				color_to_r[symbol_map[index].color],
				color_to_g[symbol_map[index].color],
				color_to_b[symbol_map[index].color]);
			SDL_RenderCopy(renderer, codepage, &srcrect, &destrect);
		}
	}
	SDL_RenderPresent(renderer);
}

void setSymbol(int x, int y, Symbol symbol)
{
	symbol_map[x+y*symbol_map_width] = symbol;
}

Symbol getSymbol(int x, int y)
{
	return symbol_map[x+y*symbol_map_width];
}
