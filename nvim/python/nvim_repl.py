"""Runs a cell of a file in the IPython REPL as code from that file.

nvim (lua/plugins/repl.lua) sends `nvim_repl.run_cell(...)` instead of the
cell's text, so tracebacks, breakpoints and debugger frames point at the real
file and line rather than an anonymous `<ipython-input-N>`. The cell's last
expression is still shown as `Out[N]`, like typing it into IPython.
"""

import ast
import base64
import sys

from IPython import get_ipython


def run_cell(source_b64: str, path: str, first_line: int, pause: bool = False) -> None:
    shell = get_ipython()
    source = base64.b64decode(source_b64).decode()
    # pad with blank lines so the cell's code sits at its line numbers in the file
    tree = ast.parse("\n" * (first_line - 1) + source, path)
    if pause:
        # debugpy pauses on the line after the call, which is the cell's first
        stop = ast.parse("__import__('debugpy').breakpoint()").body[0]
        ast.increment_lineno(stop, max(first_line - 2, 0))
        tree.body.insert(0, stop)
    last = None
    if tree.body and isinstance(tree.body[-1], ast.Expr):
        last = ast.Expression(tree.body.pop().value)
    namespace = shell.user_ns
    try:
        exec(compile(tree, path, "exec"), namespace)
        if last is not None:
            shell.displayhook(eval(compile(last, path, "eval"), namespace))
    except Exception:
        etype, value, tb = sys.exc_info()
        # the error ended the cell: with the debugger attached, stop on the
        # innermost line of your code that raised it (no-op otherwise). Errors
        # that were caught along the way (torch internals etc.) never get here.
        debugpy = sys.modules.get("debugpy")
        if debugpy is not None:
            debugpy.trigger_exception_handler((etype, value, tb))
        # then print the traceback (minus this frame) like IPython would
        shell.showtraceback((etype, value, tb.tb_next))
