import std.format;
import util;
import term;
import ser;

immutable int term_width = 80;
immutable int term_height = 24;

Symbol[term_width*term_height] symbol_array;

enum Key
{
	none = -1,
	//arrow, keypad and number keys all map to Key.digit_[0-9]
	digit_0,
	digit_1, digit_2, digit_3,
	digit_4, digit_5, digit_6,
	digit_7, digit_8, digit_9,

	a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,
	A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,
	exclam, at, hash, dollar, percent, caret, ampersand, asterisk,
	lparen, rparen, // '(' and ')'.
	lbracket, rbracket, // '[' and ']'.
	lbrace, rbrace, // '{' and '}'.
	backslash, vbar, semicolon, colon, apostrophe, quote,
	comma, period, slash, question, underscore, tilde,
	backtick, // '`'.
	equals, // '='
	less, // '<'.
	greater, // '>'.
	plus, minus,
	escape, enter, tab, space,
	del, backspace,
}

enum Color
{
	black, red, green, yellow, blue, magenta, cyan, white,
}

struct Symbol
{
	mixin Serializable;

	char chr = ' ';
	Color color = Color.white;
	Color bg_color = Color.black;
	bool is_bright = false;

	this(Serializer serializer) {}
	void beforesave(Serializer serializer) {}
	void beforeload(Serializer serializer) {}
	void aftersave(Serializer serializer) {}
	void afterload(Serializer serializer) {}

	this(char chr,
		Color color = Color.white,
		Color bg_color = Color.black,
		bool is_bright = false)
	{
		this.chr = chr;
		this.color = color;
		this.bg_color = bg_color;
		this.is_bright = is_bright;
	}

	this(char chr, Color color, bool is_bright)
	{
		this.chr = chr;
		this.color = color;
		this.bg_color = Color.black;
		this.is_bright = is_bright;
	}
}

class TermException : Exception
{
	this(string msg, string file = __FILE__, size_t line = __LINE__)
	{
		super(msg, file, line);
	}
}

void setSymbol(int x, int y, Symbol symbol)
{
	if (x >= term_width || y >= term_height || x < 0 || y < 0) {
		throw new TermException(
			format!"attempt to write out of terminal bounds: %d %d"(x, y));
	}
	symbol_array[x+y*term_width] = symbol;
}

Symbol getSymbol(int x, int y)
{
	if (x >= term_width || y >= term_height || x < 0 || y < 0) {
		throw new TermException(
			format!"attempt to read out of terminal bounds: %d %d"(x, y));
	}
	return symbol_array[x+y*term_width];
}

void write(int x, int y, string str,
	Color color,
	Color bg_color,
	bool is_bright,
	int width)
{
	string[] lines = splitAtSpaces(str, width);
	foreach (int i, string e; lines) {
		foreach (int j, char c; e) {
			setSymbol(x+j, y+i, Symbol(c, color, bg_color, is_bright));
		}
		foreach (int j; e.length..width) {
			setSymbol(x+j, y+i, Symbol(' '));
		}
	}
}

void write(int x, int y, string str,
	Color color = Color.white,
	Color bg_color = Color.black,
	bool is_bright = false)
{
	write(x, y, str, color, bg_color, is_bright, str.length);
}

void write(int x, int y, string str, bool is_bright, int width)
{
	write(x, y, str, Color.white, Color.black, is_bright, width);
}

void write(int x, int y, string str, bool is_bright)
{
	write(x, y, str, Color.white, Color.black, is_bright);
}

void write(int x, int y, string str, Color color, bool is_bright, int width)
{
	write(x, y, str, color, Color.black, is_bright, width);
}

void write(int x, int y, string str, Color color, bool is_bright)
{
	write(x, y, str, color, Color.black, is_bright);
}

void clear()
{
	foreach (i; 0..term_width) {
		foreach (j; 0..term_height) {
			setSymbol(i, j, Symbol());
		}
	}
}
