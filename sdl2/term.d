// TODO: Add contracts.

module term;

import std.format;
import core.stdc.stdlib;
import core.stdc.ctype;
import derelict.sdl2.sdl;

public import term_common;
import util;

private immutable uint symbol_width = 9;
private immutable uint symbol_height = 16;
private immutable uint codepage_width = 16;
private immutable uint codepage_height = 16;
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
private immutable ubyte[Color.max+1] bright_color_to_r = [
	Color.black:   64,
	Color.red:     255,
	Color.green:   0,
	Color.yellow:  255,
	Color.blue:    0,
	Color.magenta: 255,
	Color.cyan:    0,
	Color.white:   255,
];
private immutable ubyte[Color.max+1] bright_color_to_g = [
	Color.black:   64,
	Color.red:     0,
	Color.green:   255,
	Color.yellow:  255,
	Color.blue:    0,
	Color.magenta: 0,
	Color.cyan:    255,
	Color.white:   255,
];
private immutable ubyte[Color.max+1] bright_color_to_b = [
	Color.black:   64,
	Color.red:     0,
	Color.green:   0,
	Color.yellow:  0,
	Color.blue:    255,
	Color.magenta: 255,
	Color.cyan:    255,
	Color.white:   255,
];

private SDL_Window* window;
private SDL_Renderer* renderer;
private SDL_Texture* codepage;

private Key[SDL_Keycode] keycode_to_key;
private Key[SDL_Keycode] alnum_keycode_to_shifted_key;

static this()
{
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
		SDLK_ESCAPE: Key.escape,
		SDLK_RETURN: Key.enter,
		SDLK_RETURN2: Key.enter,
		SDLK_TAB: Key.tab,
		SDLK_SPACE: Key.space,
		SDLK_DELETE: Key.del,
		SDLK_BACKSPACE: Key.backspace,
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
		SDLK_BACKQUOTE: Key.tilde,
		/*SDLK_ESCAPE: Key.escape,
		SDLK_RETURN: Key.enter,
		SDLK_RETURN2: Key.enter,
		SDLK_TAB: Key.tab,
		SDLK_SPACE: Key.space,
		SDLK_BACKSPACE: Key.backspace,*/
	];
	DerelictSDL2.load();
	if (SDL_Init(SDL_INIT_VIDEO) != 0)
		throw new TermException(format("Unable to initialize SDL: %s",
			SDL_GetError()));
	window = SDL_CreateWindow(
		"CyberRL",
		SDL_WINDOWPOS_CENTERED,
		SDL_WINDOWPOS_CENTERED,
		symbol_width*term_width,
		symbol_height*term_height,
		0);
	if (window is null){
		throw new TermException(
			format("Unable to create SDL window: %s", SDL_GetError()));
	}
	renderer = SDL_CreateRenderer(window, -1, 0);
	if (renderer is null){
		throw new TermException(
			format("Unable to create SDL renderer: %s", SDL_GetError()));
	}
	SDL_Surface* codepage_surface = SDL_LoadBMP("sdl2/cp437.bmp");
	if (codepage_surface is null)
		throw new TermException(
			format("Unable to load 'sdl2/cp437.bmp': %s", SDL_GetError()));
	SDL_SetColorKey(codepage_surface, SDL_TRUE,
		SDL_MapRGB((*codepage_surface).format, 0, 0, 0));
	codepage = SDL_CreateTextureFromSurface(renderer, codepage_surface);
	if (codepage is null)
		throw new TermException(
			format("Unable to create SDL texture from SDL surface: %s",
			SDL_GetError()));
	SDL_FreeSurface(codepage_surface);
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
	do {
		if (SDL_WaitEvent(&event) != 1) {
			throw new TermException(
				format("Waiting for SDL event failed: %s", SDL_GetError()));
		}
		if (event.type == SDL_QUIT) {
			exit(EXIT_SUCCESS);
		} else if (event.type == SDL_WINDOWEVENT) {
			/*if (event.window.event == SDL_WINDOWEVENT_SHOWN
			|| event.window.event == SDL_WINDOWEVENT_EXPOSED
			|| event.window.event == SDL_WINDOWEVENT_MOVED
			|| event.window.*/
			refresh();
		}
		else if (event.type == SDL_WINDOWEVENT
		&& event.window.event == SDL_WINDOWEVENT_EXPOSED) refresh();
		// Repeat until a valid key is pressed.
		// Make sure that keycode is a valid key for `keycode_to_key`.
	} while(event.type != SDL_KEYDOWN
	|| (event.key.keysym.sym in keycode_to_key) is null);
	// If shift is held while a key valid for `alnum_keycode_to_shifted_key`
	// is pressed, then convert it to its shifted analogon.
	// All alphanumeric keys and
	// '[', ']', '\', ';', '\'', ',', '.', '/' are valid here.
	if ((event.key.keysym.mod & KMOD_SHIFT)
	&& (event.key.keysym.sym in alnum_keycode_to_shifted_key) !is null) {
		return alnum_keycode_to_shifted_key[event.key.keysym.sym];
	}

	return keycode_to_key[event.key.keysym.sym];
}

void refresh()
{
	SDL_RenderClear(renderer);
	for (uint i = 0; i < term_width; ++i) {
		for (uint j = 0; j < term_height; ++j) {
			uint index = i+j*term_width;
			SDL_Rect bg_rect = {
				x: (219%codepage_width)*symbol_width,
				y: (219/codepage_width)*symbol_height,
				w: symbol_width,
				h: symbol_height,
			};
			SDL_Rect src_rect = {
				x: (symbol_array[index].chr%codepage_width)*symbol_width,
				y: (symbol_array[index].chr/codepage_width)*symbol_height,
				w: symbol_width,
				h: symbol_height,
			};
			SDL_Rect dest_rect = {
				x: i*symbol_width,
				y: j*symbol_height,
				w: symbol_width,
				h: symbol_height,
			};
			SDL_SetTextureColorMod(codepage,
				color_to_r[symbol_array[index].bg_color],
				color_to_g[symbol_array[index].bg_color],
				color_to_b[symbol_array[index].bg_color]);
			SDL_RenderCopy(renderer, codepage, &bg_rect, &dest_rect);
			if (symbol_array[index].is_bright) {
				SDL_SetTextureColorMod(codepage,
					bright_color_to_r[symbol_array[index].color],
					bright_color_to_g[symbol_array[index].color],
					bright_color_to_b[symbol_array[index].color]);
			} else {
				SDL_SetTextureColorMod(codepage,
					color_to_r[symbol_array[index].color],
					color_to_g[symbol_array[index].color],
					color_to_b[symbol_array[index].color]);
			}
			SDL_RenderCopy(renderer, codepage, &src_rect, &dest_rect);
		}
	}
	SDL_RenderPresent(renderer);
}

void waitMilliseconds(int delay)
{
	refresh();
	SDL_Delay(delay);
}

void setSymbol(int x, int y, Symbol symbol)
{
	symbol_array[x+y*term_width] = symbol;
}
void setSymbol(Point p, Symbol symbol)
{
	setSymbol(p.x, p.y, symbol);
}

Symbol getSymbol(int x, int y)
{
	return symbol_array[x+y*term_width];
}
Symbol getSymbol(Point p)
{
	return getSymbol(p.x, p.y);
}
