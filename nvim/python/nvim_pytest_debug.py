"""pytest plugin: when a test fails under the debugger, stop on the line that raised.

pytest catches every test's exception itself, so the debugger never sees it as
uncaught. This hook runs only when a test actually fails (a `pytest.raises`
that gets its exception never reaches it), and hands the failure to debugpy,
which stops on the innermost frame of your code with the whole stack kept.
Loaded only in debug runs, via PYTEST_PLUGINS (lua/plugins/python-envs.lua).
"""

import debugpy
import pytest


def pytest_exception_interact(node, call, report):
    excinfo = call.excinfo
    if excinfo is None or report.skipped or hasattr(report, "wasxfail"):
        return
    if excinfo.errisinstance((pytest.skip.Exception, pytest.xfail.Exception, KeyboardInterrupt)):
        return
    debugpy.trigger_exception_handler((excinfo.type, excinfo.value, excinfo.tb))
