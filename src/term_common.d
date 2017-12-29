module term_common;
import term;

enum Key
{
	// We do not separate keypad keys.
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

struct Symbol {
	char chr = ' ';
	Color color = Color.white;
	Color bg_color = Color.black;
	bool is_bright = false;
}

class TermException : Exception
{
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

void print(int x, int y,
	string str, Color color, Color bg_color, bool is_bright, int width)
{
	// TODO: Proper automatic line breaking.
	// `width` is useless a.t.m..
	foreach(int i, char c; str){
		setSymbol(x+i, y, Symbol(c, color, bg_color, is_bright));
	}
}
