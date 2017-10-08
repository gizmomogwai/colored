module colored;

import std.string;

enum AnsiColor
{
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
    white = 37,
    defaultColor = 39
}

enum Style
{
    bold = 1,
    dim = 2,
    underlined = 4,
    blink = 5,
    reverse = 7,
    hidden = 8
}

struct StyledString
{
    string s;
    int[] befores;
    int[] afters;
    this(string s)
    {
        this.s = s;
    }

    StyledString addStyle(int before, int after)
    {
        befores ~= before;
        afters ~= after;
        return this;
    }

    string toString()
    {
        import std.algorithm;

        auto prefix = befores.map!(a => "\033[%dm".format(a)).join("");
        auto suffix = afters.map!(a => "\033[%dm".format(a)).join("");
        return "%s%s%s".format(prefix, s, suffix);
    }
}

@("styledstring") unittest
{
    import unit_threaded;
    import std.stdio;
    import std.traits;

    foreach (immutable color; [EnumMembers!AnsiColor])
    {
        auto colorName = "%s".format(color);
        writeln(StyledString(colorName).addStyle(color, 0));
    }
    foreach (immutable color; [EnumMembers!AnsiColor])
    {
        auto colorName = "bg%s".format(color);
        writeln(StyledString(colorName).addStyle(color + 10, 0));
    }
    foreach (immutable style; [EnumMembers!Style])
    {
        auto styleName = "%s".format(style);
        writeln(StyledString(styleName).addStyle(style, style + 20));
    }

    writeln(StyledString("test").addStyle(AnsiColor.red, 0)
            .addStyle(Style.underlined, Style.underlined + 20));
}

auto colorMixin(T)()
{
    import std.traits;

    string res = "";
    foreach (immutable color; [EnumMembers!T])
    {
        auto t = typeof(T.init).stringof;
        auto c = "%s".format(color);
        res ~= "auto %1$s(string s) { return StyledString(s).addStyle(%2$s.%1$s, 0); }\n".format(c,
                t);
        res ~= "auto %1$s(StyledString s) { return s.addStyle(%2$s.%1$s, 0); }\n".format(c, t);
        string name = c[0 .. 1].toUpper ~ c[1 .. $];
        res ~= "auto on%3$s(string s) { return StyledString(s).addStyle(%2$s.%1$s+10, 0); }\n".format(c,
                t, name);
        res ~= "auto on%3$s(StyledString s) { return s.addStyle(%2$s.%1$s+10, 0); }\n".format(c,
                t, name);
    }
    return res;
}

auto styleMixin(T)()
{
    import std.traits;

    string res = "";
    foreach (immutable style; [EnumMembers!T])
    {
        auto t = typeof(T.init).stringof;
        auto s = "%s".format(style);
        res ~= "auto %1$s(string s) { return StyledString(s).addStyle(%2$s.%1$s, %2$s.%1$s+20); }\n".format(s,
                t);
        res ~= "auto %1$s(StyledString s) { return s.addStyle(%2$s.%1$s, %2$s.%1$s+20); }\n".format(s,
                t);
    }
    return res;
}

mixin(colorMixin!AnsiColor);
mixin(styleMixin!Style);

@("api") unittest
{
    import std.stdio;

    writeln("red".red);
    writeln("red".red.onYellow.bold.underlined);
}
