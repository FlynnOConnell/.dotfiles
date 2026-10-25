"""Run configs as forms: a command line read against its argparse --help.

The viewer's run configs page (nvim_sciview.py) shows each saved command as a
form. parse_help() reads a program's --help page into its name (with any
subcommands), positionals and options; parse_line() splits a command line
into those fields, and to_line() puts the fields back into a line. Anything
using argparse gets a form this way: masknmf, pytest, your own scripts.

Lines are split the way run_configs.lua splits them (spaces separate, quotes
group, nothing else), so a saved line means the same in ,dd and here.
"""

import re
from dataclasses import dataclass, field

ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
# what a running script that reads its arguments mentions somewhere
PARSES_ARGS = re.compile(r"argparse|ArgumentParser|\bclick\b|\btyper\b|fire\.Fire|docopt|tyro")


def split(line: str) -> list[str]:
    """Shell-like: spaces separate, quotes group (run_configs.lua's split)."""
    args, current, quote = [], None, None
    for char in line:
        if quote:
            if char == quote:
                quote = None
            else:
                current = (current or "") + char
        elif char in "\"'":
            quote, current = char, current or ""
        elif char.isspace():
            if current is not None:
                args.append(current)
                current = None
        else:
            current = (current or "") + char
    if current is not None:
        args.append(current)
    return args


def quote(token: str) -> str:
    if token and not re.search(r"[\s\"']", token):
        return token
    return f"'{token}'" if '"' in token else f'"{token}"'


def join(tokens: list[str]) -> str:
    return " ".join(quote(t) for t in tokens)


@dataclass
class Arg:
    name: str  # the form's label: the first long flag, or the positional's name
    flags: list[str] = field(default_factory=list)  # every name of an option; none for a positional
    nargs: str = "1"  # "0" (a switch), "1", "?", "*", "+", or a count
    metavar: str = ""
    choices: list[str] = field(default_factory=list)
    declared: bool = False  # choices from argparse itself ({a,b}), not read off the help text
    help: str = ""
    default: str | None = None
    required: bool = False
    group: str = ""
    subcommand: bool = False  # argparse subparsers: {a,b,c} ...

    @property
    def positional(self) -> bool:
        return not self.flags

    @property
    def several(self) -> bool:
        return self.nargs not in ("0", "1", "?")


@dataclass
class Spec:
    prog: list[str]  # "usage: masknmf run ..." -> ["masknmf", "run"]
    args: list[Arg]
    whole_line: bool = False  # read with the whole command line, not a shorter one

    def option(self, flag: str) -> Arg | None:
        return next((a for a in self.args if flag in a.flags), None)

    @property
    def positionals(self) -> list[Arg]:
        return [a for a in self.args if a.positional]

    @property
    def options(self) -> list[Arg]:
        return [a for a in self.args if not a.positional]


def _nargs(meta: str) -> str:
    """argparse's metavar pattern -> nargs: "" "X" "[X]" "[X ...]" "X [X ...]" "X X"."""
    if not meta:
        return "0"
    if meta.startswith("[") and "..." in meta:
        return "*"
    if "..." in meta:
        return "+"
    if meta.startswith("["):
        return "?"
    return str(len(meta.split()))


def _usage_nargs(usage: str, name: str) -> str:
    n = re.escape(name)
    if re.search(rf"\[{n} \.\.\.\]|\[{n} \[{n} \.\.\.\]\]|\[{n}\](?: \[{n}\])* \[\.\.\.\]", usage):
        return "*"
    if re.search(rf"(?<!\[){n} \[{n} \.\.\.\]", usage):
        return "+"
    if re.search(rf"\[{n}\]", usage):
        return "?"
    return "1"


def _required_in_usage(usage: str, flags: list[str]) -> bool:
    """An option outside every [ ] / ( ) of the usage line is required."""
    depth = 0
    for i, char in enumerate(usage):
        if char in "[(":
            depth += 1
        elif char in "])":
            depth -= 1
        elif depth == 0 and (i == 0 or usage[i - 1] in " |"):
            word = re.match(r"[^\s\]|)]+", usage[i:])
            if word and word.group() in flags:
                return True
    return False


def _read_help_text(arg: Arg):
    """What masknmf-style help text says: "one of a, b", "default X", "required"."""
    text = " ".join(arg.help.split())
    found = re.search(r"\(default: ([^)]*)\)", text) or re.search(
        r"\bdefault[: ]\s*('[^']*'|\"[^\"]*\"|[^\s;,)]+)", text)
    if found:
        arg.default = found.group(1).strip("'\"")
    if not arg.choices:
        one_of = re.search(r"\bone of ([\w.\-]+(?:,\s*[\w.\-]+)+)", text)
        if one_of:
            arg.choices = [c.strip() for c in one_of.group(1).split(",")]
        elif arg.default in ("True", "False") and arg.nargs == "1":
            arg.choices = ["True", "False"]
    if re.match(r"required\b", text, re.I) or re.search(r"\(required\)|; required\b", text, re.I):
        arg.required = True


def parse_help(text: str) -> Spec | None:
    """An argparse --help page -> Spec, or None if it isn't one."""
    lines = ANSI.sub("", text).replace("\r", "\n").split("\n")
    start = next((i for i, line in enumerate(lines) if line.startswith("usage:")), None)
    if start is None:
        return None
    usage_lines = [lines[start][len("usage:"):]]
    i = start + 1
    while i < len(lines) and lines[i].strip():
        usage_lines.append(lines[i])
        i += 1
    usage = " ".join(line.strip() for line in usage_lines)

    # the sections: "title:" at the left edge, items indented under it
    items, section, current, item_indent = [], None, None, None
    for line in lines[i:]:
        if not line.strip():
            continue
        indent = len(line) - len(line.lstrip())
        if indent == 0:
            section = line.strip()[:-1] if line.rstrip().endswith(":") else None
            current, item_indent = None, None
            continue
        if section is None:
            continue  # the description or epilog
        if item_indent is None:
            item_indent = indent
        if indent == item_indent:
            parts = re.split(r"\s{2,}", line.strip(), maxsplit=1)
            current = {"header": parts[0], "help": parts[1] if len(parts) > 1 else "", "section": section}
            items.append(current)
        elif current is not None:
            current["help"] += "\n" + line.strip()

    positional_names = [it["header"].split()[0] for it in items if not it["header"].startswith("-")]
    words = usage.split()
    prog = []
    for k, word in enumerate(words):
        if prog[-1:] == ["-m"]:
            prog.append(word)  # python -m pytest
        elif word == "-m" and prog and k + 1 < len(words):
            prog.append(word)
        elif word[0] in "[-{(" or word in positional_names or word == "...":
            break
        else:
            prog.append(word)
    after = " ".join(words[len(prog):])

    args = []
    for it in items:
        header, help_text = it["header"], it["help"].strip()
        if header.startswith("-"):
            flags, meta = [], ""
            for k, part in enumerate(header.split(", ")):
                # "--fs VALUE", or pytest's "--maxfail=num"
                flag, _, rest = part.partition("=") if re.match(r"-[^\s=]+=", part) else part.partition(" ")
                flags.append(flag)
                if k == 0:
                    meta = rest
            if set(flags) & {"-h", "--help"} or "show program's version number" in help_text:
                continue
            arg = Arg(name=next((f for f in flags if f.startswith("--")), flags[0]), flags=flags,
                      nargs=_nargs(meta), metavar=meta, help=help_text, group=it["section"])
            braces = re.fullmatch(r"\{([^}]*)\}", meta.split(" ")[0]) if meta else None
            if braces:
                arg.choices, arg.declared = braces.group(1).split(","), True
            arg.required = _required_in_usage(after, flags)
        else:
            name = header.split()[0]
            if not re.search(rf"(?<![\w-]){re.escape(name)}(?![\w-])", after):
                continue  # not in the usage line: a note, not an argument
            arg = Arg(name=name, metavar=name, help=help_text, group=it["section"])
            braces = re.fullmatch(r"\{([^}]*)\}", name)
            if braces:
                arg.choices, arg.declared = braces.group(1).split(","), True
                arg.subcommand = bool(re.search(rf"{re.escape(name)} \.\.\.", after))
                arg.name = "subcommand" if arg.subcommand else name
            arg.nargs = "1" if arg.subcommand else _usage_nargs(after, name)
            arg.required = arg.nargs in ("1", "+") or arg.nargs.isdigit()
        _read_help_text(arg)
        args.append(arg)
    return Spec(prog=prog, args=args)


@dataclass
class Form:
    command: list[str]  # the program and its subcommands, as typed: ["masknmf", "run"]
    values: dict[str, list[str]]  # Arg.name -> its tokens; a switch that's on: []
    used: dict[str, str]  # option name -> the flag as typed (--fs for --frame-rate)
    joined: set[str]  # options written --flag=value
    extra: list[str]  # what the help doesn't know, in order


def command_length(tokens: list[str], spec: Spec | None) -> int:
    """How many leading tokens name the program: masknmf run, -m pkg, a script."""
    n = 2 if tokens[:1] == ["-m"] else 1
    prog = spec.prog if spec else []
    # the words after the program's own name ("python -m pkg" counts as one)
    for word in prog[prog.index("-m") + 2:] if "-m" in prog else prog[1:]:
        if n < len(tokens) and tokens[n] == word:
            n += 1
    return min(n, len(tokens))


def _is_flag(token: str) -> bool:
    return token.startswith("-") and len(token) > 1 and not re.fullmatch(r"-[\d.]+", token)


def parse_line(line: str, spec: Spec | None) -> Form:
    tokens = split(line)
    n = command_length(tokens, spec)
    form = Form(command=tokens[:n], values={}, used={}, joined=set(), extra=[])
    if spec is None:
        form.extra = tokens[n:]
        return form
    slots = list(spec.positionals)
    i = n
    while i < len(tokens):
        token = tokens[i]
        if token == "--":
            form.extra += tokens[i:]
            break
        if _is_flag(token):
            flag, eq, value = token.partition("=")
            arg = spec.option(flag)
            if arg is None or arg.name in form.values:
                # unknown (or repeated): kept as typed, with a value that follows it
                take = 2 if i + 1 < len(tokens) and not _is_flag(tokens[i + 1]) and not eq else 1
                form.extra += tokens[i:i + take]
                i += take
                continue
            form.used[arg.name] = flag
            if eq:
                form.values[arg.name] = [value]
                form.joined.add(arg.name)
                i += 1
                continue
            i += 1
            values = []
            if arg.nargs == "1":
                values = tokens[i:i + 1]
            elif arg.nargs == "?":
                values = tokens[i:i + 1] if i < len(tokens) and not _is_flag(tokens[i]) else []
            elif arg.nargs in ("*", "+"):
                while i + len(values) < len(tokens) and not _is_flag(tokens[i + len(values)]):
                    values.append(tokens[i + len(values)])
            elif arg.nargs.isdigit():
                values = tokens[i:i + int(arg.nargs)]
            form.values[arg.name] = values
            i += len(values)
            continue
        if not slots:
            form.extra.append(token)
            i += 1
            continue
        arg = slots.pop(0)
        if arg.subcommand:
            # what follows belongs to the subcommand, which this help doesn't describe
            form.values[arg.name] = [token]
            form.extra += tokens[i + 1:]
            break
        if arg.nargs in ("*", "+"):
            values = []
            while i + len(values) < len(tokens) and not _is_flag(tokens[i + len(values)]):
                values.append(tokens[i + len(values)])
        else:
            values = tokens[i:i + (int(arg.nargs) if arg.nargs.isdigit() else 1)]
        form.values[arg.name] = values
        i += len(values)
    return form


def to_line(form: Form, spec: Spec | None) -> str:
    """The fields back as a line: the command, positionals, options, extra args."""
    tokens = list(form.command)
    for arg in spec.args if spec else []:
        if arg.positional and arg.name in form.values:
            tokens += form.values[arg.name]
    for arg in spec.args if spec else []:
        if arg.positional or arg.name not in form.values:
            continue
        flag = form.used.get(arg.name, arg.name)
        values = form.values[arg.name]
        if arg.name in form.joined and len(values) == 1:
            tokens.append(f"{flag}={values[0]}")
        else:
            tokens += [flag, *values]
    return join(tokens + form.extra)


def help_line(form: Form, spec: Spec | None) -> str:
    """The part of a line its --help depends on: the command and the options
    with argparse choices (masknmf's --pipeline decides the other flags)."""
    tokens = list(form.command)
    for arg in spec.options if spec else []:
        if arg.declared and arg.name in form.values:
            tokens += [form.used.get(arg.name, arg.name), *form.values[arg.name]]
    return join(tokens)
