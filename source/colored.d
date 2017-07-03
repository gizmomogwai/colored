module colored;

import std.string;

enum AnsiColor {
  black = 30,
  red = 31,
  green = 32,
  yellow = 33,
  blue = 34,
  magenta = 35,
  cyan = 36,
  white = 37
}

struct StringWithForeground(T) {
  string s;
  T fg;
  this(string s, T fg) {
    this.s = s;
    this.fg = fg;
  }
  string toString() {
    return "\033[%dm%s\033[0m".format(fg, s);
  }
}

struct StringWithBackground(T) {
  string s;
  T bg;
  this(string s, T bg) {
    this.s = s;
    this.bg = bg;
  }
  string toString() {
    return "\033[%dm%s\033[0m".format(bg+10, s);
  }
}

struct StringWithBoth(T) {
  string s;
  T fg;
  T bg;
  this(string s, T fg, T bg) {
    this.s = s;
    this.fg = fg;
    this.bg = bg;
  }
  string toString() {
    return "\033[%dm\033[%dm%s\033[0m".format(fg, bg+10, s);
  }
}

@("color structs") unittest {
  import unit_threaded;
  StringWithForeground!AnsiColor("fgTest", AnsiColor.red).toString.shouldEqual("\033[31mfgTest\033[0m");
  StringWithBackground!AnsiColor("bgTest", AnsiColor.red).toString.shouldEqual("\033[41mbgTest\033[0m");
  StringWithBoth!AnsiColor("bothTest", AnsiColor.red, AnsiColor.red).toString.shouldEqual("\033[31m\033[41mbothTest\033[0m");
}

string asMixin(T)() {
  import std.conv;
  import std.traits;
  string res = "";
  foreach (immutable ansiColor; [EnumMembers!T]) {
    res ~= "auto %1$s(string s) { return StringWithForeground!%2$s(s, %2$s.%1$s); }\n".format(ansiColor, typeof(T.init).stringof);
    res ~= "auto %1$s(StringWithBackground!%2$s s) { return StringWithBoth!%2$s(s.s, %2$s.%1$s, s.bg); }\n".format(ansiColor, typeof(T.init).stringof);
    string n = ansiColor.to!string;
    string name = n[0..1].toUpper ~ n[1..$];
    res ~= "auto on%3$s(string s) { return StringWithBackground!%2$s(s, %2$s.%1$s); }\n".format(ansiColor, typeof(T.init).stringof, name);
    res ~= "auto on%3$s(StringWithForeground!%2$s s) { return StringWithBoth!%2$s(s.s, s.fg, %2$s.%1$s); }\n".format(ansiColor, typeof(T.init).stringof, name);
  }
  return res;
}

@("color mixins") unittest {
  import unit_threaded;
  enum TTT {
    r = 1
  }
  asMixin!TTT.shouldEqual(
`auto r(string s) { return StringWithForeground!TTT(s, TTT.r); }
auto r(StringWithBackground!TTT s) { return StringWithBoth!TTT(s.s, TTT.r, s.bg); }
auto onR(string s) { return StringWithBackground!TTT(s, TTT.r); }
auto on(StringWithForeground!TTT s) { return StringWithBoth!TTT(s.s, s.fg, TTT.r); }
`);
}

mixin(asMixin!AnsiColor);
