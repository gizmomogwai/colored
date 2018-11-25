/++
 + Simple coloring module for strings
 +
 + Copyright: Copyright © 2017, Christian Köstlin
 + Authors: Christian Koestlin
 + License: MIT
 +/
module colored;

import std.string;

public import colored.packageversion;

/// Available Colors
enum AnsiColor
{
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
    lightGray = 37,
    defaultColor = 39,
    darkGray = 90,
    lightRed = 91,
    lightGreen = 92,
    lightYellow = 93,
    lightBlue = 94,
    lightMagenta = 95,
    lightCyan = 96,
    white = 97
}

/// Available Styles
enum Style
{
    bold = 1,
    dim = 2,
    underlined = 4,
    blink = 5,
    reverse = 7,
    hidden = 8
}

/// Internal structure to style a string
struct StyledString
{
    public string unformatted;
    private int[] befores;
    private int[] afters;
    public this(string unformatted)
    {
        this.unformatted = unformatted;
    }

    private StyledString addPair(int before, int after)
    {
        befores ~= before;
        afters ~= after;
        return this;
    }

    StyledString setForeground(int color)
    {
        return addPair(color, 0);
    }

    StyledString setBackground(int color)
    {
        return addPair(color + 10, 0);
    }

    StyledString addStyle(int style)
    {
        return addPair(style, 0);
    }

    string toString() @safe
    {
        import std.algorithm;

        auto prefix = befores.map!(a => "\033[%dm".format(a)).join("");
        auto suffix = afters.map!(a => "\033[%dm".format(a)).join("");
        return "%s%s%s".format(prefix, unformatted, suffix);
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
        writeln(StyledString(colorName).setForeground(color));
    }
    foreach (immutable color; [EnumMembers!AnsiColor])
    {
        auto colorName = "bg%s".format(color);
        writeln(StyledString(colorName).setBackground(color));
    }
    foreach (immutable style; [EnumMembers!Style])
    {
        auto styleName = "%s".format(style);
        writeln(StyledString(styleName).addStyle(style));
    }
}

auto colorMixin(T)()
{
    import std.traits;

    string res = "";
    foreach (immutable color; [EnumMembers!T])
    {
        auto t = typeof(T.init).stringof;
        auto c = "%s".format(color);
        res ~= "auto %1$s(string s) { return StyledString(s).setForeground(%2$s.%1$s); }\n".format(c,
                t);
        res ~= "auto %1$s(StyledString s) { return s.setForeground(%2$s.%1$s); }\n".format(c, t);
        string name = c[0 .. 1].toUpper ~ c[1 .. $];
        res ~= "auto on%3$s(string s) { return StyledString(s).setBackground(%2$s.%1$s); }\n".format(c,
                t, name);
        res ~= "auto on%3$s(StyledString s) { return s.setBackground(%2$s.%1$s); }\n".format(c,
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
        res ~= "auto %1$s(string s) { return StyledString(s).addStyle(%2$s.%1$s); }\n".format(s, t);
        res ~= "auto %1$s(StyledString s) { return s.addStyle(%2$s.%1$s); }\n".format(s, t);
    }
    return res;
}

mixin(colorMixin!AnsiColor);
mixin(styleMixin!Style);

@("api") unittest
{
    import std.stdio;

    "redOnGreen".red.onGreen.writeln;
    "redOnYellowBoldUnderlined".red.onYellow.bold.underlined.writeln;
    "bold".bold.writeln;
    "test".writeln;
}

/// Calculate length of string excluding all formatting escapes
ulong unformattedLength(string s)
{
    enum State
    {
        NORMAL,
        ESCAPED,
    }

    auto state = State.NORMAL;
    ulong count = 0;
    foreach (c; s)
    {
        switch (state)
        {
        case State.NORMAL:
            if (c == 0x1b)
            {
                state = State.ESCAPED;
            }
            else
            {
                count++;
            }
            break;
        case State.ESCAPED:
            if (c == 'm')
            {
                state = State.NORMAL;
            }
            break;
        default:
            throw new Exception("Illegal state");
        }
    }
    return count;
}

auto leftJustifyFormattedString(string s, ulong width, dchar fillChar = ' ')
{
    auto res = s;
    auto currentWidth = s.unformattedLength;
    for (auto i = currentWidth; i < width; ++i)
    {
        res ~= fillChar;
    }
    return res;
}
