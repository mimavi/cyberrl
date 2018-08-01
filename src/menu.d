import std.algorithm.comparison;
import std.container;
import std.math;
import util;
import term;
import item;

bool selectItem(Array!Item items, string header, ref int index)
{
	int pos = 0;
	Key key;
	drawSelectItem(items, header, pos);
	do {
		key = term.readKey();
		if (key == Key.escape) {
			return false;
		}
	} while (key_to_chr[key] == 0
	|| chr_to_index[key_to_chr[key]] >= items.length);
	index = chr_to_index[key_to_chr[key]];
	return true;
}

void drawSelectItem(Array!Item items, string header, int pos)
{
	term.clear(); // TODO: Optimize. Can be done without clearing.
	term.write(0, 0, header);
	foreach (i; pos..(pos+min(items.length, term_height-2))) {
		term.write(1, i+1, index_to_chr[i]~" - "~items[i].name);
	}
}
