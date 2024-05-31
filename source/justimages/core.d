///
module justimages.core;

/++
	History:
		Moved from color.d to core.d in March 2023 (dub v11.0).
+/
nothrow @safe @nogc pure
inout(char)[] stripInternal(return inout(char)[] s) {
	bool isAllWhitespace = true;
	foreach(i, char c; s)
		if(c != ' ' && c != '\t' && c != '\n' && c != '\r') {
			s = s[i .. $];
			isAllWhitespace = false;
			break;
		}

	if(isAllWhitespace)
		return s[$..$];

	for(int a = cast(int)(s.length - 1); a > 0; a--) {
		char c = s[a];
		if(c != ' ' && c != '\t' && c != '\n' && c != '\r') {
			s = s[0 .. a + 1];
			break;
		}
	}

	return s;
}
