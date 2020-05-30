/++
 + Simple coloring module for strings
 +
 + Copyright: Copyright © 2017, Christian Köstlin
 + Authors: Christian Koestlin
 + License: MIT
 +/
module colored;

@safe:

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

struct RGBString
{
    string unformatted;
    struct RGB
    {
        ubyte r;
        ubyte g;
        ubyte b;
    }

    RGB* foreground;
    RGB* background;
    this(string unformatted)
    {
        this.unformatted = unformatted;
    }

    auto rgb(ubyte r, ubyte g, ubyte b)
    {
        this.foreground = new RGB(r, g, b);
        return this;
    }

    auto onRgb(ubyte r, ubyte g, ubyte b)
    {
        this.background = new RGB(r, g, b);
        return this;
    }

    string toString() @safe
    {
        auto res = "";
        if (foreground != null)
        {
            res = "\033[38;2;%s;%s;%sm".format(foreground.r, foreground.g, foreground.b) ~ res;
        }
        if (background != null)
        {
            res = "\033[48;2;%s;%s;%sm".format(background.r, background.g, background.b) ~ res;
        }
        res ~= unformatted;
        if (foreground != null || background != null)
        {
            res ~= "\033[0m";
        }
        return res;
    }
}

string rgb(string s, ubyte r, ubyte g, ubyte b)
{
    return RGBString(s).rgb(r, g, b).toString;
}

string onRgb(string s, ubyte r, ubyte g, ubyte b)
{
    return RGBString(s).onRgb(r, g, b).toString;
}

@("rgb") unittest
{
    import std.stdio;

    writeln("red: ", "r".rgb(255, 0, 0).onRgb(0, 255, 0));
    writeln("green: ", "g".rgb(0, 255, 0).onRgb(0, 0, 255));
    writeln("blue: ", "b".rgb(0, 0, 255).onRgb(255, 0, 0));
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

// https://en.wikipedia.org/wiki/ANSI_escape_code
auto tokenize(Range)(Range parts)
{
    import std.range;

    struct TokenizeResult(Range)
    {
        Range parts;
        ElementType!(Range)[] next;
        this(Range parts)
        {
            this.parts = parts;
            tokenizeNext();
        }

        private void tokenizeNext()
        {
            next = [];
            if (parts.empty)
            {
                return;
            }
            switch (parts.front)
            {
            case 38:
            case 48:
                next ~= 38;
                parts.popFront;
                switch (parts.front)
                {
                case 2:
                    next ~= 2;
                    parts.popFront;
                    next ~= parts.front;
                    parts.popFront;
                    next ~= parts.front;
                    parts.popFront;
                    next ~= parts.front;
                    parts.popFront;
                    break;
                case 5:
                    next ~= 5;
                    parts.popFront;
                    next ~= parts.front;
                    parts.popFront;
                    break;
                default:
                    throw new Exception("Only [38,48];[2,5] are supported but got %s;%s".format(next[0],
                            parts.front));
                }
                break;
            case 0: .. case 37:
            case 39: .. case 47:
            case 49:
            case 51: .. case 55:
            case 60: .. case 65:
            case 90: .. case 97:
            case 100: .. case 107:
                next ~= parts.front;
                parts.popFront;
                break;
            default:
                throw new Exception("Only colors are supported");
            }
        }

        auto front()
        {
            return next;
        }

        bool empty()
        {
            return next == null;
        }

        void popFront()
        {
            tokenizeNext();
        }
    }

    return TokenizeResult!(Range)(parts);
}

@("ansi tokenizer") unittest
{
    import unit_threaded;

    [38, 5, 2, 38, 2, 1, 2, 3, 36, 1, 2, 3, 4].tokenize.shouldEqual([[38, 5,
            2], [38, 2, 1, 2, 3], [36], [1], [2], [3], [4]]);
}

string filterAnsiEscapes(alias predicate)(string s)
{
    import std.regex;

    string withFilters(Captures!string c)
    {
        import std.string;
        import std.algorithm;
        import std.conv;
        import std.array;

        auto parts = c[1].split(";").map!(a => a.to!uint).tokenize.filter!(p => predicate(p));
        if (parts.empty)
        {
            return "";
        }
        else
        {
            return "\033[" ~ parts.joiner.map!(a => "%d".format(a)).join(";") ~ "m";
        }
    }

    alias r = ctRegex!"\033\\[(.*?)m";
    return s.replaceAll!(withFilters)(r);
}

bool foregroundColor(uint[] token)
{
    return token[0] >= 30 && token[0] <= 38;
}

bool backgroundColor(uint[] token)
{
    return token[0] >= 40 && token[0] <= 48;
}

bool style(uint[] token)
{
    return token[0] >= 1 && token[0] <= 29;
}

bool none(uint[] token)
{
    return false;
}

bool all(uint[] token)
{
    return true;
}

@("configurable strip") unittest
{
    import unit_threaded;
    import std.functional;

    "\033[1;31mtest".filterAnsiEscapes!(foregroundColor).shouldEqual("\033[31mtest");
    "\033[1;31mtest".filterAnsiEscapes!(not!foregroundColor).shouldEqual("\033[1mtest");
    "\033[1;31mtest".filterAnsiEscapes!(style).shouldEqual("\033[1mtest");
    "\033[1;31mtest".filterAnsiEscapes!(none).shouldEqual("test");
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
